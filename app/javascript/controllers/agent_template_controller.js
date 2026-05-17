import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    const field = event.currentTarget.closest(".field")
    const input = field && field.querySelector("[data-agent-template-target='input']")

    if (!input) {
      return
    }

    input.value = event.currentTarget.value
    input.focus()
  }
}
