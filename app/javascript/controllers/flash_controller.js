import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    autoDismiss: { type: Number, default: 3000 }
  }

  connect() {
    this.timeout = window.setTimeout(() => {
      this.dismiss()
    }, this.autoDismissValue)
  }

  disconnect() {
    this.clearTimeout()
  }

  close() {
    this.dismiss()
  }

  dismiss() {
    this.clearTimeout()
    this.element.classList.add("flash-dismissing")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }

  clearTimeout() {
    if (!this.timeout) return

    window.clearTimeout(this.timeout)
    this.timeout = null
  }
}
