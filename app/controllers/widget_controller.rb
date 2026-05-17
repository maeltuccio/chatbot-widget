class WidgetController < ApplicationController
  skip_before_action :authenticate_user!
  skip_forgery_protection only: :show

  def show
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Content-Type"] = "application/javascript; charset=utf-8"
    render plain: widget_loader_javascript
  end

  private

  def widget_loader_javascript
    <<~JAVASCRIPT
      (function () {
        var script = document.currentScript;
        var agentToken = script && script.dataset ? script.dataset.agentToken : null;
        var autoOpen = script && script.dataset ? script.dataset.open === "true" : false;

        if (!agentToken || document.getElementById("chatbot-saas-widget")) {
          return;
        }

        var baseUrl = new URL(script.src).origin;

        window.ChatbotSaasWidgetConfig = {
          agentToken: agentToken,
          baseUrl: baseUrl,
          autoOpen: autoOpen
        };

        function appendAsset(tagName, attributes) {
          var element = document.createElement(tagName);
          Object.keys(attributes).forEach(function (key) {
            element.setAttribute(key, attributes[key]);
          });
          document.head.appendChild(element);
        }

        appendAsset("link", {
          rel: "stylesheet",
          href: baseUrl + "#{helpers.asset_path("widget.css")}"
        });

        appendAsset("script", {
          src: baseUrl + "#{helpers.asset_path("widget.js")}",
          defer: "defer"
        });
      })();
    JAVASCRIPT
  end
end
