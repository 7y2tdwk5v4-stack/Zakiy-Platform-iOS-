# Late.Chat 🌙

An AI chat app: accounts, unlimited chats, streaming answers, and long-term
memory that carries across conversations — powered by OpenAI + Supabase.

## What's here

- `backend/` — Flask API: streams OpenAI responses, verifies Supabase auth
  tokens, stores chats/messages, and extracts durable "memories" from
  conversations automatically.
- `frontend/` — Static single-page UI (no build step): sign in/up, sidebar
  with New Chat + chat history, streaming message bubbles, a memories panel.
- `supabase/schema.sql` — Postgres schema for `chats`, `messages`,
  `memories`, with row-level security policies.

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) → New project.
2. In the SQL editor, paste and run `supabase/schema.sql`.
3. In **Authentication → Providers**, make sure Email is enabled (default).
4. In **Project Settings → API**, copy:
   - Project URL
   - `anon` `public` key
   - `service_role` `secret` key (keep this one server-side only)

## 2. Get an OpenAI API key

Create one at [platform.openai.com/api-keys](https://platform.openai.com/api-keys).

## 3. Configure the backend

```bash
cd backend
cp .env.example .env
# edit .env and fill in OPENAI_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
```

## 4. Configure the frontend

```bash
cd frontend
cp config.example.js config.js
# edit config.js and fill in SUPABASE_URL + the anon key (not the service role key)
```

## 5. Run it

```bash
cd backend
python app.py
```

Open **http://localhost:5000** — the Flask app also serves the frontend.
Create an account, hit **New chat**, and start talking. After a few
exchanges, open **🧠 Memories** in the sidebar to see what it's remembered
about you — it'll use that context automatically in future chats, even in
a brand new conversation.

## How memory works

After every assistant reply, a cheap background model call decides whether
anything durable was revealed (a preference, a project, a fact about you).
If so, it's saved to the `memories` table and quietly injected into the
system prompt on every future request — so Late.Chat doesn't forget you
between chats.

## Notes

- Swap models via `OPENAI_CHAT_MODEL` / `OPENAI_MEMORY_MODEL` in `.env`.
- `frontend/config.js` only needs the public anon key — never put the
  Supabase service role key or your OpenAI key in the frontend.
