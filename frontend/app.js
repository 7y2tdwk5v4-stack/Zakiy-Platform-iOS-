(() => {
  const cfg = window.LATE_CHAT_CONFIG || {};
  const API_BASE = cfg.API_BASE || "";

  if (!cfg.SUPABASE_URL || !cfg.SUPABASE_ANON_KEY || cfg.SUPABASE_URL.includes("YOUR-PROJECT")) {
    document.body.innerHTML =
      '<div class="setup-notice">Late.Chat isn\'t configured yet.<br>' +
      "Copy <code>frontend/config.example.js</code> to <code>frontend/config.js</code> " +
      "and fill in your Supabase project URL + anon key.</div>";
    return;
  }

  const supabase = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);

  // ---------- state ----------
  let session = null;
  let chats = [];
  let activeChatId = null;
  let streaming = false;

  // ---------- elements ----------
  const authScreen = document.getElementById("auth-screen");
  const appScreen = document.getElementById("app-screen");
  const authForm = document.getElementById("auth-form");
  const authEmail = document.getElementById("auth-email");
  const authPassword = document.getElementById("auth-password");
  const authError = document.getElementById("auth-error");
  const authHint = document.getElementById("auth-hint");
  const authSubmit = document.getElementById("auth-submit");
  const authTabs = document.querySelectorAll(".auth-tab");

  const chatListEl = document.getElementById("chat-list");
  const messagesEl = document.getElementById("messages");
  const emptyState = document.getElementById("empty-state");
  const composer = document.getElementById("composer");
  const composerInput = document.getElementById("composer-input");
  const newChatBtn = document.getElementById("new-chat-btn");
  const signoutBtn = document.getElementById("signout-btn");

  const memoriesBtn = document.getElementById("memories-btn");
  const memoriesModal = document.getElementById("memories-modal");
  const memoriesClose = document.getElementById("memories-close");
  const memoriesList = document.getElementById("memories-list");

  let authMode = "signin";

  // ---------- auth ----------
  authTabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      authMode = tab.dataset.mode;
      authTabs.forEach((t) => t.classList.toggle("active", t === tab));
      authSubmit.textContent = authMode === "signin" ? "Sign in" : "Create account";
      authError.textContent = "";
      authHint.textContent = "";
    });
  });

  authForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    authError.textContent = "";
    authHint.textContent = "";
    authSubmit.disabled = true;
    const email = authEmail.value.trim();
    const password = authPassword.value;
    try {
      if (authMode === "signin") {
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
      } else {
        const { error } = await supabase.auth.signUp({ email, password });
        if (error) throw error;
        authHint.textContent = "Account created. Check your email if confirmation is required, then sign in.";
      }
    } catch (err) {
      authError.textContent = err.message || "Something went wrong.";
    } finally {
      authSubmit.disabled = false;
    }
  });

  signoutBtn.addEventListener("click", async () => {
    await supabase.auth.signOut();
  });

  supabase.auth.onAuthStateChange((_event, newSession) => {
    session = newSession;
    if (session) {
      showApp();
    } else {
      showAuth();
    }
  });

  function showAuth() {
    authScreen.classList.remove("hidden");
    appScreen.classList.add("hidden");
  }

  function showApp() {
    authScreen.classList.add("hidden");
    appScreen.classList.remove("hidden");
    loadChats();
  }

  // ---------- api helper ----------
  async function api(path, options = {}) {
    const token = session?.access_token;
    const res = await fetch(API_BASE + path, {
      ...options,
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
        ...(options.headers || {}),
      },
    });
    if (!res.ok && res.status !== 204) {
      const body = await res.json().catch(() => ({}));
      throw new Error(body.error || `Request failed (${res.status})`);
    }
    return res;
  }

  // ---------- chats ----------
  async function loadChats() {
    const res = await api("/api/chats");
    chats = await res.json();
    renderChatList();
    if (!activeChatId && chats.length) {
      selectChat(chats[0].id);
    } else if (!chats.length) {
      renderMessages([]);
    }
  }

  function renderChatList() {
    chatListEl.innerHTML = "";
    chats.forEach((chat) => {
      const item = document.createElement("div");
      item.className = "chat-item" + (chat.id === activeChatId ? " active" : "");
      item.textContent = chat.title || "New chat";
      item.addEventListener("click", () => selectChat(chat.id));

      const del = document.createElement("button");
      del.className = "chat-item-delete";
      del.textContent = "✕";
      del.title = "Delete chat";
      del.addEventListener("click", async (e) => {
        e.stopPropagation();
        await api(`/api/chats/${chat.id}`, { method: "DELETE" });
        chats = chats.filter((c) => c.id !== chat.id);
        if (activeChatId === chat.id) {
          activeChatId = null;
          if (chats.length) selectChat(chats[0].id);
          else renderMessages([]);
        }
        renderChatList();
      });

      item.appendChild(del);
      chatListEl.appendChild(item);
    });
  }

  async function selectChat(chatId) {
    activeChatId = chatId;
    renderChatList();
    const res = await api(`/api/chats/${chatId}/messages`);
    const msgs = await res.json();
    renderMessages(msgs);
  }

  newChatBtn.addEventListener("click", async () => {
    const res = await api("/api/chats", { method: "POST" });
    const chat = await res.json();
    chats.unshift(chat);
    activeChatId = chat.id;
    renderChatList();
    renderMessages([]);
    composerInput.focus();
  });

  memoriesBtn.addEventListener("click", async () => {
    memoriesModal.classList.remove("hidden");
    memoriesList.innerHTML = '<p class="memories-empty">Loading…</p>';
    const res = await api("/api/memories");
    const memories = await res.json();
    if (!memories.length) {
      memoriesList.innerHTML = '<p class="memories-empty">Nothing remembered yet — keep chatting.</p>';
      return;
    }
    memoriesList.innerHTML = "";
    memories.forEach((m) => {
      const row = document.createElement("div");
      row.className = "memory-row";
      const text = document.createElement("span");
      text.textContent = m.content;
      const del = document.createElement("button");
      del.textContent = "Forget";
      del.className = "ghost-btn small";
      del.addEventListener("click", async () => {
        await api(`/api/memories/${m.id}`, { method: "DELETE" });
        row.remove();
      });
      row.appendChild(text);
      row.appendChild(del);
      memoriesList.appendChild(row);
    });
  });
  memoriesClose.addEventListener("click", () => memoriesModal.classList.add("hidden"));
  memoriesModal.addEventListener("click", (e) => {
    if (e.target === memoriesModal) memoriesModal.classList.add("hidden");
  });

  // ---------- messages rendering ----------
  function renderMessages(msgs) {
    messagesEl.innerHTML = "";
    if (!msgs.length) {
      messagesEl.appendChild(emptyState);
      return;
    }
    msgs.forEach((m) => appendBubble(m.role, m.content));
    scrollToBottom();
  }

  function appendBubble(role, content) {
    if (messagesEl.contains(emptyState)) messagesEl.removeChild(emptyState);
    const bubble = document.createElement("div");
    bubble.className = `bubble ${role}`;
    const inner = document.createElement("div");
    inner.className = "bubble-inner";
    inner.innerHTML = renderMarkdownLite(content);
    bubble.appendChild(inner);
    messagesEl.appendChild(bubble);
    return inner;
  }

  function escapeHtml(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  function renderMarkdownLite(text) {
    const escaped = escapeHtml(text);
    const withCodeBlocks = escaped.replace(/```([\s\S]*?)```/g, (_, code) => `<pre><code>${code}</code></pre>`);
    const withInlineCode = withCodeBlocks.replace(/`([^`]+)`/g, "<code>$1</code>");
    const withBold = withInlineCode.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
    return withBold.replace(/\n/g, "<br>");
  }

  function scrollToBottom() {
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }

  // ---------- composer ----------
  composerInput.addEventListener("input", () => {
    composerInput.style.height = "auto";
    composerInput.style.height = Math.min(composerInput.scrollHeight, 200) + "px";
  });

  composerInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      composer.requestSubmit();
    }
  });

  composer.addEventListener("submit", async (e) => {
    e.preventDefault();
    const text = composerInput.value.trim();
    if (!text || streaming) return;

    if (!activeChatId) {
      const res = await api("/api/chats", { method: "POST" });
      const chat = await res.json();
      chats.unshift(chat);
      activeChatId = chat.id;
      renderChatList();
    }

    composerInput.value = "";
    composerInput.style.height = "auto";
    appendBubble("user", text);
    scrollToBottom();

    const assistantInner = appendTypingBubble();
    scrollToBottom();
    streaming = true;

    try {
      await streamAssistantReply(activeChatId, text, assistantInner);
    } catch (err) {
      assistantInner.innerHTML = `<span class="error-text">⚠️ ${escapeHtml(err.message)}</span>`;
    } finally {
      streaming = false;
    }
  });

  function appendTypingBubble() {
    if (messagesEl.contains(emptyState)) messagesEl.removeChild(emptyState);
    const bubble = document.createElement("div");
    bubble.className = "bubble assistant";
    const inner = document.createElement("div");
    inner.className = "bubble-inner";
    inner.innerHTML = '<span class="typing"><span></span><span></span><span></span></span>';
    bubble.appendChild(inner);
    messagesEl.appendChild(bubble);
    return inner;
  }

  async function streamAssistantReply(chatId, message, targetEl) {
    const token = session?.access_token;
    const res = await fetch(`${API_BASE}/api/chats/${chatId}/stream`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ message }),
    });

    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      throw new Error(body.error || `Request failed (${res.status})`);
    }

    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    let full = "";
    let first = true;

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const events = buffer.split("\n\n");
      buffer = events.pop();
      for (const evt of events) {
        const line = evt.trim();
        if (!line.startsWith("data:")) continue;
        const payload = JSON.parse(line.slice(5).trim());
        if (payload.error) throw new Error(payload.error);
        if (payload.delta) {
          if (first) {
            targetEl.innerHTML = "";
            first = false;
          }
          full += payload.delta;
          targetEl.innerHTML = renderMarkdownLite(full);
          scrollToBottom();
        }
        if (payload.done) {
          const chat = chats.find((c) => c.id === chatId);
          if (chat) {
            chat.title = payload.title;
            renderChatList();
          }
        }
      }
    }
  }

  // ---------- bootstrap ----------
  supabase.auth.getSession().then(({ data }) => {
    session = data.session;
    if (session) showApp();
    else showAuth();
  });
})();
