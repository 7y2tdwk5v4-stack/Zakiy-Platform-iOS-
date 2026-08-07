(() => {
  const STORAGE_KEY = "latechat_demo_v1";

  function loadState() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) return JSON.parse(raw);
    } catch (e) {
      /* ignore corrupt state */
    }
    return { chats: [], memories: [] };
  }

  function saveState() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  }

  let state = loadState();
  let activeChatId = state.chats[0]?.id || null;
  let streaming = false;

  const chatListEl = document.getElementById("chat-list");
  const messagesEl = document.getElementById("messages");
  const emptyState = document.getElementById("empty-state");
  const composer = document.getElementById("composer");
  const composerInput = document.getElementById("composer-input");
  const newChatBtn = document.getElementById("new-chat-btn");
  const clearBtn = document.getElementById("clear-btn");

  const memoriesBtn = document.getElementById("memories-btn");
  const memoriesModal = document.getElementById("memories-modal");
  const memoriesClose = document.getElementById("memories-close");
  const memoriesList = document.getElementById("memories-list");

  function activeChat() {
    return state.chats.find((c) => c.id === activeChatId) || null;
  }

  function renderChatList() {
    chatListEl.innerHTML = "";
    state.chats.forEach((chat) => {
      const item = document.createElement("div");
      item.className = "chat-item" + (chat.id === activeChatId ? " active" : "");
      item.textContent = chat.title || "New chat";
      item.addEventListener("click", () => selectChat(chat.id));

      const del = document.createElement("button");
      del.className = "chat-item-delete";
      del.textContent = "✕";
      del.title = "Delete chat";
      del.addEventListener("click", (e) => {
        e.stopPropagation();
        state.chats = state.chats.filter((c) => c.id !== chat.id);
        if (activeChatId === chat.id) {
          activeChatId = state.chats[0]?.id || null;
        }
        saveState();
        renderChatList();
        renderMessages(activeChat()?.messages || []);
      });

      item.appendChild(del);
      chatListEl.appendChild(item);
    });
  }

  function selectChat(chatId) {
    activeChatId = chatId;
    renderChatList();
    renderMessages(activeChat()?.messages || []);
  }

  newChatBtn.addEventListener("click", () => {
    const chat = { id: crypto.randomUUID(), title: "New chat", messages: [] };
    state.chats.unshift(chat);
    activeChatId = chat.id;
    saveState();
    renderChatList();
    renderMessages([]);
    composerInput.focus();
  });

  clearBtn.addEventListener("click", () => {
    if (!confirm("Delete every chat and memory stored in this browser? This can't be undone.")) return;
    state = { chats: [], memories: [] };
    activeChatId = null;
    saveState();
    renderChatList();
    renderMessages([]);
  });

  memoriesBtn.addEventListener("click", () => {
    memoriesModal.classList.remove("hidden");
    renderMemories();
  });
  memoriesClose.addEventListener("click", () => memoriesModal.classList.add("hidden"));
  memoriesModal.addEventListener("click", (e) => {
    if (e.target === memoriesModal) memoriesModal.classList.add("hidden");
  });

  function renderMemories() {
    if (!state.memories.length) {
      memoriesList.innerHTML = '<p class="memories-empty">Nothing remembered yet — keep chatting.</p>';
      return;
    }
    memoriesList.innerHTML = "";
    state.memories.forEach((fact, idx) => {
      const row = document.createElement("div");
      row.className = "memory-row";
      const text = document.createElement("span");
      text.textContent = fact;
      const del = document.createElement("button");
      del.textContent = "Forget";
      del.className = "ghost-btn small";
      del.addEventListener("click", () => {
        state.memories.splice(idx, 1);
        saveState();
        renderMemories();
      });
      row.appendChild(text);
      row.appendChild(del);
      memoriesList.appendChild(row);
    });
  }

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
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
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

    let chat = activeChat();
    if (!chat) {
      chat = { id: crypto.randomUUID(), title: "New chat", messages: [] };
      state.chats.unshift(chat);
      activeChatId = chat.id;
      renderChatList();
    }

    const history = chat.messages.slice();
    chat.messages.push({ role: "user", content: text });
    if (chat.title === "New chat") chat.title = text.slice(0, 60);
    saveState();
    renderChatList();

    composerInput.value = "";
    composerInput.style.height = "auto";
    appendBubble("user", text);
    scrollToBottom();

    const assistantInner = appendTypingBubble();
    scrollToBottom();
    streaming = true;

    try {
      const fullReply = await streamAssistantReply(history, text, assistantInner);
      chat.messages.push({ role: "assistant", content: fullReply });
      saveState();
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

  async function streamAssistantReply(history, message, targetEl) {
    const res = await fetch("/api/demo/stream", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ history, message, memories: state.memories }),
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
        if (payload.done && payload.memory) {
          state.memories.unshift(payload.memory);
          saveState();
        }
      }
    }
    return full;
  }

  // ---------- bootstrap ----------
  renderChatList();
  renderMessages(activeChat()?.messages || []);
})();
