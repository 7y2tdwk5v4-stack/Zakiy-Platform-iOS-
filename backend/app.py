import json
import os
from functools import wraps

from dotenv import load_dotenv
from flask import Flask, Response, jsonify, request, stream_with_context
from flask_cors import CORS
from openai import OpenAI
from supabase import Client, create_client

load_dotenv()

app = Flask(__name__, static_folder="../frontend", static_url_path="")
CORS(app)
app.json.ensure_ascii = False

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
CHAT_MODEL = os.getenv("OPENAI_CHAT_MODEL", "gpt-4o")
MEMORY_MODEL = os.getenv("OPENAI_MEMORY_MODEL", "gpt-4o-mini")
openai_client = OpenAI(api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase_admin: Client | None = None
if SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY:
    supabase_admin = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

SYSTEM_PROMPT = (
    "You are Late.Chat, an exceptionally sharp, warm and direct AI assistant. "
    "Answer anything the user asks as clearly and completely as you can: explain "
    "your reasoning when it helps, give working code when asked, stay concise for "
    "simple questions and go deep for hard ones. Never pad your answers with filler. "
    "If you don't know something, say so plainly instead of guessing."
)


def require_auth(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if supabase_admin is None:
            return jsonify({"error": "Accounts are not configured on this server yet."}), 503
        auth_header = request.headers.get("Authorization", "")
        token = auth_header.replace("Bearer ", "").strip()
        if not token:
            return jsonify({"error": "You must be signed in."}), 401
        try:
            user_response = supabase_admin.auth.get_user(token)
            if not user_response or not user_response.user:
                raise ValueError("invalid token")
            request.user_id = user_response.user.id
        except Exception:
            return jsonify({"error": "Your session expired, please sign in again."}), 401
        return f(*args, **kwargs)

    return wrapper


def _get_owned_chat(chat_id):
    res = (
        supabase_admin.table("chats")
        .select("id, title")
        .eq("id", chat_id)
        .eq("user_id", request.user_id)
        .limit(1)
        .execute()
    )
    return res.data[0] if res.data else None


def _load_memories_text(user_id):
    res = (
        supabase_admin.table("memories")
        .select("content")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .limit(30)
        .execute()
    )
    if not res.data:
        return ""
    bullets = "\n".join(f"- {row['content']}" for row in res.data)
    return f"\n\nThings you remember about this user from earlier conversations:\n{bullets}"


def _maybe_extract_memory(user_id, user_message, assistant_message):
    if openai_client is None:
        return
    try:
        completion = openai_client.chat.completions.create(
            model=MEMORY_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Decide if this exchange reveals a durable fact worth remembering about "
                        "the user for future conversations (preferences, identity, goals, ongoing "
                        "projects, constraints). Ignore one-off questions. Reply with strict JSON: "
                        '{"remember": true|false, "fact": "short fact written in third person, '
                        'or empty string"}'
                    ),
                },
                {
                    "role": "user",
                    "content": f"User said: {user_message}\nAssistant replied: {assistant_message}",
                },
            ],
            response_format={"type": "json_object"},
            temperature=0,
        )
        data = json.loads(completion.choices[0].message.content)
        if data.get("remember") and data.get("fact"):
            supabase_admin.table("memories").insert(
                {"user_id": user_id, "content": data["fact"]}
            ).execute()
    except Exception:
        pass


@app.route("/api/health")
def health():
    return jsonify(
        {
            "status": "ok",
            "openai_configured": openai_client is not None,
            "accounts_configured": supabase_admin is not None,
        }
    )


# ---------- Chats ----------


@app.route("/api/chats", methods=["GET"])
@require_auth
def list_chats():
    res = (
        supabase_admin.table("chats")
        .select("id, title, created_at")
        .eq("user_id", request.user_id)
        .order("created_at", desc=True)
        .execute()
    )
    return jsonify(res.data)


@app.route("/api/chats", methods=["POST"])
@require_auth
def create_chat():
    res = (
        supabase_admin.table("chats")
        .insert({"user_id": request.user_id, "title": "New chat"})
        .execute()
    )
    return jsonify(res.data[0]), 201


@app.route("/api/chats/<chat_id>", methods=["DELETE"])
@require_auth
def delete_chat(chat_id):
    supabase_admin.table("chats").delete().eq("id", chat_id).eq(
        "user_id", request.user_id
    ).execute()
    return "", 204


@app.route("/api/chats/<chat_id>/messages", methods=["GET"])
@require_auth
def get_messages(chat_id):
    if _get_owned_chat(chat_id) is None:
        return jsonify({"error": "Chat not found"}), 404
    res = (
        supabase_admin.table("messages")
        .select("id, role, content, created_at")
        .eq("chat_id", chat_id)
        .order("created_at")
        .execute()
    )
    return jsonify(res.data)


# ---------- Memories ----------


@app.route("/api/memories", methods=["GET"])
@require_auth
def list_memories():
    res = (
        supabase_admin.table("memories")
        .select("id, content, created_at")
        .eq("user_id", request.user_id)
        .order("created_at", desc=True)
        .execute()
    )
    return jsonify(res.data)


@app.route("/api/memories/<memory_id>", methods=["DELETE"])
@require_auth
def delete_memory(memory_id):
    supabase_admin.table("memories").delete().eq("id", memory_id).eq(
        "user_id", request.user_id
    ).execute()
    return "", 204


# ---------- Streaming chat ----------


@app.route("/api/chats/<chat_id>/stream", methods=["POST"])
@require_auth
def stream_chat(chat_id):
    if openai_client is None:
        return jsonify({"error": "OPENAI_API_KEY is not configured on the server."}), 503

    chat = _get_owned_chat(chat_id)
    if chat is None:
        return jsonify({"error": "Chat not found"}), 404

    body = request.get_json(force=True) or {}
    user_message = (body.get("message") or "").strip()
    if not user_message:
        return jsonify({"error": "Message is empty"}), 400

    supabase_admin.table("messages").insert(
        {"chat_id": chat_id, "role": "user", "content": user_message}
    ).execute()

    history_res = (
        supabase_admin.table("messages")
        .select("role, content")
        .eq("chat_id", chat_id)
        .order("created_at")
        .execute()
    )
    history = history_res.data

    new_title = chat["title"]
    if new_title == "New chat":
        new_title = user_message[:60]
        supabase_admin.table("chats").update({"title": new_title}).eq(
            "id", chat_id
        ).execute()

    memories_text = _load_memories_text(request.user_id)
    messages = [{"role": "system", "content": SYSTEM_PROMPT + memories_text}]
    messages += [{"role": m["role"], "content": m["content"]} for m in history]

    def generate():
        full_reply = ""
        try:
            stream = openai_client.chat.completions.create(
                model=CHAT_MODEL, messages=messages, stream=True
            )
            for chunk in stream:
                delta = chunk.choices[0].delta.content
                if delta:
                    full_reply += delta
                    yield f"data: {json.dumps({'delta': delta})}\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"
            return

        supabase_admin.table("messages").insert(
            {"chat_id": chat_id, "role": "assistant", "content": full_reply}
        ).execute()
        yield f"data: {json.dumps({'done': True, 'title': new_title})}\n\n"
        _maybe_extract_memory(request.user_id, user_message, full_reply)

    return Response(stream_with_context(generate()), mimetype="text/event-stream")


@app.route("/")
def index():
    return app.send_static_file("index.html")


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=True)
