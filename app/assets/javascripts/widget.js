(function () {
  function bootWidget() {
    var config = window.ChatbotSaasWidgetConfig;
    var agentToken = config && config.agentToken;
    var baseUrl = config && config.baseUrl;
    var autoOpen = config && config.autoOpen;

    if (!agentToken || !baseUrl || document.getElementById("chatbot-saas-widget")) {
      return;
    }

    var conversationStorageKey = "chatbot_saas_conversation_" + agentToken;
    var visitorStorageKey = "chatbot_saas_visitor";
    var conversationToken = localStorage.getItem(conversationStorageKey);
    var visitorIdentifier = localStorage.getItem(visitorStorageKey);

    if (!visitorIdentifier) {
      visitorIdentifier = "visitor_" + Math.random().toString(36).slice(2) + Date.now().toString(36);
      localStorage.setItem(visitorStorageKey, visitorIdentifier);
    }

    var container = document.createElement("div");
    container.id = "chatbot-saas-widget";
    container.className = "chatbot-saas-position-bottom-right";

    var panel = document.createElement("div");
    panel.className = autoOpen ? "chatbot-saas-panel chatbot-saas-panel-open" : "chatbot-saas-panel";

    var header = document.createElement("button");
    header.type = "button";
    header.className = "chatbot-saas-header";
    header.setAttribute("aria-expanded", autoOpen ? "true" : "false");
    header.setAttribute("aria-label", autoOpen ? "Close chat" : "Open chat");

    var headerIcon = document.createElement("span");
    headerIcon.className = "chatbot-saas-header-icon";
    headerIcon.setAttribute("aria-hidden", "true");
    headerIcon.innerHTML = '<svg viewBox="0 0 24 24" focusable="false"><path d="M21 11.5a8.4 8.4 0 0 1-.9 3.8 8.6 8.6 0 0 1-7.7 4.7 8.4 8.4 0 0 1-3.8-.9L3 21l1.9-5.1a8.4 8.4 0 0 1-1.1-4.4 8.6 8.6 0 0 1 17.2 0Z"></path></svg>';

    var headerTitle = document.createElement("span");
    headerTitle.className = "chatbot-saas-header-title";
    headerTitle.textContent = "Chat";

    header.appendChild(headerIcon);
    header.appendChild(headerTitle);

    var body = document.createElement("div");
    body.className = autoOpen ? "chatbot-saas-body chatbot-saas-body-open" : "chatbot-saas-body";

    var messages = document.createElement("div");
    messages.className = "chatbot-saas-messages";

    var welcome = document.createElement("div");
    welcome.className = "chatbot-saas-message chatbot-saas-message-assistant";
    welcome.textContent = "Loading...";
    messages.appendChild(welcome);

    var form = document.createElement("form");
    form.className = "chatbot-saas-form";

    var input = document.createElement("input");
    input.className = "chatbot-saas-input";
    input.type = "text";
    input.placeholder = "Entrez votre message ...";

    var submit = document.createElement("button");
    submit.className = "chatbot-saas-submit";
    submit.type = "submit";
    submit.textContent = "Send";

    form.appendChild(input);
    form.appendChild(submit);
    body.appendChild(messages);
    body.appendChild(form);
    panel.appendChild(header);
    panel.appendChild(body);
    container.appendChild(panel);
    document.body.appendChild(container);

    function addMessage(text, role, extraClass) {
      var message = document.createElement("div");
      message.className = "chatbot-saas-message chatbot-saas-message-" + role;
      if (extraClass) {
        message.className += " " + extraClass;
      }
      renderMessageContent(message, text);
      messages.appendChild(message);
      messages.scrollTop = messages.scrollHeight;
      return message;
    }

    function renderMessageContent(message, text) {
      var content = text || "";
      var urlPattern = /(https?:\/\/[^\s<]+)/g;
      var lastIndex = 0;
      var match;

      message.textContent = "";

      while ((match = urlPattern.exec(content)) !== null) {
        if (match.index > lastIndex) {
          message.appendChild(document.createTextNode(content.slice(lastIndex, match.index)));
        }

        var rawUrl = match[0];
        var trailingPunctuation = "";

        while (/[.,;:!?)]$/.test(rawUrl)) {
          trailingPunctuation = rawUrl.slice(-1) + trailingPunctuation;
          rawUrl = rawUrl.slice(0, -1);
        }

        var link = document.createElement("a");
        link.href = rawUrl;
        link.textContent = rawUrl;
        link.target = "_blank";
        link.rel = "noopener noreferrer";
        message.appendChild(link);

        if (trailingPunctuation) {
          message.appendChild(document.createTextNode(trailingPunctuation));
        }

        lastIndex = match.index + match[0].length;
      }

      if (lastIndex < content.length) {
        message.appendChild(document.createTextNode(content.slice(lastIndex)));
      }
    }

    function normalizeAssistantText(text) {
      return text
        .replace(/([A-Za-zÀ-ÖØ-öø-ÿ])([0-9])/g, "$1 $2")
        .replace(/([0-9])([A-Za-zÀ-ÖØ-öø-ÿ])/g, "$1 $2")
        .replace(/([.!?])([A-ZÀ-Ö])/g, "$1 $2");
    }

    function appendToMessage(message, text) {
      message.classList.remove("chatbot-saas-message-typing");
      message.dataset.rawContent = normalizeAssistantText((message.dataset.rawContent || message.textContent) + text);
      renderMessageContent(message, message.dataset.rawContent);
      messages.scrollTop = messages.scrollHeight;
    }

    function createTypingBuffer(message) {
      return {
        push: function (text) {
          appendToMessage(message, text || "");
        },
        finish: function () {
          message.classList.remove("chatbot-saas-message-typing");
        },
        clear: function () {
          message.dataset.rawContent = "";
        }
      };
    }

    function handleStreamEvent(eventName, eventData, assistantMessage, typingBuffer) {
      if (eventData.conversation_token) {
        conversationToken = eventData.conversation_token;
        localStorage.setItem(conversationStorageKey, conversationToken);
      }

      if (eventName === "delta") {
        typingBuffer.push(eventData.content || "");
      }

      if (eventName === "done") {
        typingBuffer.finish();
      }

      if (eventName === "error") {
        typingBuffer.clear();
        assistantMessage.classList.remove("chatbot-saas-message-typing");
        assistantMessage.textContent = eventData.error || "Sorry, the chat is not available right now.";
      }
    }

    function parseStreamEvent(rawEvent) {
      var eventName = "message";
      var dataLines = [];

      rawEvent.split("\n").forEach(function (line) {
        if (line.indexOf("event:") === 0) {
          eventName = line.slice(6).trim();
        }

        if (line.indexOf("data:") === 0) {
          dataLines.push(line.slice(5).trim());
        }
      });

      return {
        name: eventName,
        data: dataLines.length ? JSON.parse(dataLines.join("\n")) : {}
      };
    }

    function readMessageStream(response, assistantMessage, typingBuffer) {
      var reader = response.body.getReader();
      var decoder = new TextDecoder();
      var buffer = "";

      function readNextChunk() {
        return reader.read().then(function (result) {
          if (result.done) {
            return;
          }

          buffer += decoder.decode(result.value, { stream: true });
          var events = buffer.split("\n\n");
          buffer = events.pop();

          events.forEach(function (rawEvent) {
            if (!rawEvent.trim()) {
              return;
            }

            var parsedEvent = parseStreamEvent(rawEvent);
            handleStreamEvent(parsedEvent.name, parsedEvent.data, assistantMessage, typingBuffer);
          });

          return readNextChunk();
        });
      }

      return readNextChunk();
    }

    function sendStreamingMessage(text, assistantMessage, typingBuffer) {
      return fetch(baseUrl + "/widget/messages/stream", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          agent_token: agentToken,
          conversation_token: conversationToken,
          visitor_identifier: visitorIdentifier,
          message: text
        })
      }).then(function (response) {
        if (!response.body) {
          throw new Error("Streaming is not available in this browser.");
        }

        return readMessageStream(response, assistantMessage, typingBuffer);
      });
    }

    function setChatOpen(isOpen) {
      panel.classList.toggle("chatbot-saas-panel-open", isOpen);
      body.classList.toggle("chatbot-saas-body-open", isOpen);
      header.setAttribute("aria-expanded", isOpen ? "true" : "false");
      header.setAttribute("aria-label", isOpen ? "Close chat" : "Open chat");

      if (isOpen) {
        input.focus();
      }
    }

    header.addEventListener("click", function () {
      setChatOpen(!panel.classList.contains("chatbot-saas-panel-open"));
    });

    form.addEventListener("submit", function (event) {
      event.preventDefault();

      var text = input.value.trim();
      if (!text) {
        return;
      }

      input.value = "";
      addMessage(text, "visitor");
      var assistantMessage = addMessage("", "assistant", "chatbot-saas-message-typing");
      assistantMessage.innerHTML = "<span></span><span></span><span></span>";
      var typingBuffer = createTypingBuffer(assistantMessage);
      submit.disabled = true;
      input.disabled = true;

      sendStreamingMessage(text, assistantMessage, typingBuffer)
        .catch(function (error) {
          typingBuffer.clear();
          assistantMessage.classList.remove("chatbot-saas-message-typing");
          assistantMessage.textContent = error.message || "Sorry, the chat is not available right now.";
        })
        .finally(function () {
          submit.disabled = false;
          input.disabled = false;
          input.focus();
        });
    });

    fetch(baseUrl + "/widget/agents/" + encodeURIComponent(agentToken))
      .then(function (response) { return response.json(); })
      .then(function (agent) {
        var primaryColor = agent.widget_primary_color || "#111827";
        var theme = agent.widget_theme || "glass";

        container.className = "chatbot-saas-position-" + (agent.widget_position || "bottom_right").replace("_", "-") + " chatbot-saas-theme-" + theme;
        container.style.setProperty("--chatbot-saas-primary-color", primaryColor);
        headerTitle.textContent = agent.widget_title || agent.name || "Chat";
        headerTitle.hidden = agent.widget_show_title === false;
        submit.textContent = agent.widget_send_label || "Send";
        input.placeholder = agent.widget_placeholder || "Type your message...";
        welcome.textContent = agent.welcome_message || "Hi! How can I help you today?";

        if (autoOpen) {
          setChatOpen(true);
        }
      })
      .catch(function () {
        welcome.textContent = "Hi! How can I help you today?";

        if (autoOpen) {
          setChatOpen(true);
        }
      });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", bootWidget);
  } else {
    bootWidget();
  }
})();
