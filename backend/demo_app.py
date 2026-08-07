"""Zero-setup version of Late.Chat: no Supabase, no accounts.

Chat history and memories live in the browser's localStorage instead of a
database, so testing needs nothing but an OPENAI_API_KEY in backend/.env.
Run: python demo_app.py, then open http://localhost:5000
"""

import json
import os

from dotenv import load_dotenv
from flask import Flask, Response, jsonify, request, stream_with_context
from flask_cors import CORS
from openai import OpenAI

load_dotenv()

app = Flask(__name__, static_folder="../frontend", static_url_path="")
CORS(app)
app.json.ensure_ascii = False

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
CHAT_MODEL = os.getenv("OPENAI_CHAT_MODEL", "gpt-4o-mini")
MEMORY_MODEL = os.getenv("OPENAI_MEMORY_MODEL", "gpt-4o-mini")
openai_client = OpenAI(api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None

SYSTEM_PROMPT = (
    "You are Late.Chat, an exceptionally sharp, warm and direct AI assistant. "
    "Answer anything the user asks as clearly and completely as you can: explain "
    "your reasoning when it helps, give working code when asked, stay concise for "
    "simple questions and go deep for hard ones. Never pad your answers with filler. "
    "If you don't know something, say so plainly instead of guessing."
)


@app.route("/api/health")
def health():
    return jsonify({"status": "ok", "openai_configured": openai_client is not None})


def _maybe_extract_memory(user_message, assistant_message):
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
            return data["fact"]
    except Exception:
        pass
    return None


@app.route("/api/demo/stream", methods=["POST"])
def demo_stream():
    if openai_client is None:
        return jsonify({"error": "OPENAI_API_KEY is not set in backend/.env"}), 503

    body = request.get_json(force=True) or {}
    history = body.get("history") or []
    message = (body.get("message") or "").strip()
    memories = body.get("memories") or []
    if not message:
        return jsonify({"error": "Message is empty"}), 400

    memories_text = ""
    if memories:
        bullets = "\n".join(f"- {m}" for m in memories)
        memories_text = f"\n\nThings you remember about this user from earlier conversations:\n{bullets}"

    messages = [{"role": "system", "content": SYSTEM_PROMPT + memories_text}]
    messages += [{"role": m.get("role"), "content": m.get("content")} for m in history]
    messages.append({"role": "user", "content": message})

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

        new_fact = _maybe_extract_memory(message, full_reply)
        yield f"data: {json.dumps({'done': True, 'memory': new_fact})}\n\n"

    return Response(stream_with_context(generate()), mimetype="text/event-stream")


@app.route("/")
def index():
    return app.send_static_file("demo.html")


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=True)
