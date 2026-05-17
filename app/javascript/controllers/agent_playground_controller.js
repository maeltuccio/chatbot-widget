import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "frame", "status"]

  refresh(event) {
    event.preventDefault()

    const button = event.currentTarget
    const canShowLoading = button.tagName === "BUTTON"
    const originalText = button.textContent
    const formData = new FormData(this.formTarget)

    button.disabled = true
    if (canShowLoading) {
      button.textContent = "Updating..."
    }
    this.setStatus("")

    fetch(this.formTarget.action, {
      method: "PATCH",
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": this.csrfToken()
      },
      body: formData,
      credentials: "same-origin"
    })
      .then((response) => {
        return response.json().then((payload) => {
          if (!response.ok) {
            throw payload
          }

          return payload
        })
      })
      .then((payload) => {
        this.applyTheme(payload.widget_theme)
        this.reloadFrame(payload.playground_url)
        this.setStatus(payload.message || "Chatbot preview updated.")
      })
      .catch((payload) => {
        const errors = payload && payload.errors ? payload.errors.join(", ") : "Could not update the chatbot preview."
        this.setStatus(errors)
      })
      .finally(() => {
        button.disabled = false
        if (canShowLoading) {
          button.textContent = originalText
        }
      })
  }

  reloadFrame(url) {
    const nextUrl = new URL(url || this.frameTarget.src, window.location.origin)
    nextUrl.searchParams.set("preview_at", Date.now().toString())
    this.frameTarget.src = nextUrl.toString()
  }

  applyTheme(theme) {
    const widget = this.frameTarget.contentDocument && this.frameTarget.contentDocument.getElementById("chatbot-saas-widget")

    if (!widget || !theme) {
      return
    }

    widget.classList.remove("chatbot-saas-theme-glass", "chatbot-saas-theme-light", "chatbot-saas-theme-dark")
    widget.classList.add(`chatbot-saas-theme-${theme}`)
  }

  setStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }

  csrfToken() {
    const token = document.querySelector("meta[name='csrf-token']")
    return token ? token.content : ""
  }
}
