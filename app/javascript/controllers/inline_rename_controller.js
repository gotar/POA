import { Controller } from "@hotwired/stimulus"

// InlineRenameController
//
// Usage:
// <div data-controller="inline-rename">
//   <div data-inline-rename-target="display" data-action="click->inline-rename#edit">...</div>
//   <div data-inline-rename-target="form" class="hidden">...<input data-inline-rename-target="input" ...></div>
// </div>
//
// Works nicely with Turbo forms:
// - on successful submit, hides the form again (turbo:submit-end)
export default class extends Controller {
  static targets = ["display", "form", "input"]

  connect() {
    // Ensure initial state
    this.showDisplay()
  }

  edit(event) {
    if (event) event.preventDefault()
    this.showForm()
  }

  cancel(event) {
    if (event) event.preventDefault()
    this.showDisplay()
  }

  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.showDisplay()
      return
    }

    // Enter submits (unless user is composing IME text)
    if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
      // Let the form submit normally
      const form = this.formTarget.querySelector("form")
      if (form) {
        event.preventDefault()
        form.requestSubmit()
      }
    }
  }

  submitEnd(event) {
    // event.detail.success is true for 2xx/3xx
    if (event && event.detail && event.detail.success) {
      this.showDisplay()
    } else {
      // keep form open to show validation errors
      this.showForm(false)
    }
  }

  showForm(focus = true) {
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")

    if (focus && this.hasInputTarget) {
      try {
        this.inputTarget.focus()
        this.inputTarget.select()
      } catch (_e) {
        // ignore
      }
    }
  }

  showDisplay() {
    this.formTarget.classList.add("hidden")
    this.displayTarget.classList.remove("hidden")
  }
}
