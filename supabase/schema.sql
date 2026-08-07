-- Late.Chat database schema
-- Run this in your Supabase project's SQL editor.

create extension if not exists "pgcrypto";

create table if not exists chats (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'New chat',
  created_at timestamptz not null default now()
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references chats(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists memories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists chats_user_id_idx on chats(user_id);
create index if not exists messages_chat_id_idx on messages(chat_id);
create index if not exists memories_user_id_idx on memories(user_id);

-- Row Level Security: the backend uses the service-role key (bypasses RLS),
-- but this keeps things safe if the tables are ever queried directly from
-- the client with a user's own token.
alter table chats enable row level security;
alter table messages enable row level security;
alter table memories enable row level security;

create policy "Users manage their own chats" on chats
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users manage messages in their own chats" on messages
  for all using (
    exists (select 1 from chats where chats.id = messages.chat_id and chats.user_id = auth.uid())
  ) with check (
    exists (select 1 from chats where chats.id = messages.chat_id and chats.user_id = auth.uid())
  );

create policy "Users manage their own memories" on memories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
