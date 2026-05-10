(function () {
  function bootWidget() {
    var config = window.ChatbotSaasWidgetConfig;
    var agentToken = config && config.agentToken;
    var baseUrl = config && config.baseUrl;

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
    panel.className = "chatbot-saas-panel";

    var header = document.createElement("button");
    header.type = "button";
    header.className = "chatbot-saas-header";
    header.textContent = "Chat";

    var body = document.createElement("div");
    body.className = "chatbot-saas-body";

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
      message.textContent = text;
      messages.appendChild(message);
      messages.scrollTop = messages.scrollHeight;
      return message;
    }

    function appendToMessage(message, text) {
      message.classList.remove("chatbot-saas-message-typing");
      message.textContent += text;
      messages.scrollTop = messages.scrollHeight;
    }

    function createTypingBuffer(message) {
      var queue = "";
      var timer = null;
      var delay = 14;

      function flushNextCharacter() {
        if (!queue.length) {
          timer = null;
          return;
        }

        appendToMessage(message, queue.charAt(0));
        queue = queue.slice(1);
        timer = setTimeout(flushNextCharacter, delay);
      }

      return {
        push: function (text) {
          queue += text || "";

          if (!timer) {
            flushNextCharacter();
          }
        },
        finish: function () {
          if (queue.length && !timer) {
            flushNextCharacter();
          }
        },
        clear: function () {
          if (timer) {
            clearTimeout(timer);
            timer = null;
          }

          queue = "";
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

    header.addEventListener("click", function () {
      panel.classList.toggle("chatbot-saas-panel-open");
      body.classList.toggle("chatbot-saas-body-open");
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

        container.className = "chatbot-saas-position-" + (agent.widget_position || "bottom_right").replace("_", "-");
        container.style.setProperty("--chatbot-saas-primary-color", primaryColor);
        header.textContent = agent.widget_title || agent.name || "Chat";
        submit.textContent = agent.widget_send_label || "Send";
        input.placeholder = agent.widget_placeholder || "Type your message...";
        welcome.textContent = agent.welcome_message || "Hi! How can I help you today?";
      })
      .catch(function () {
        welcome.textContent = "Hi! How can I help you today?";
      });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", bootWidget);
  } else {
    bootWidget();
  }
})();
