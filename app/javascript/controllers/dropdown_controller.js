import { Controller } from "@hotwired/stimulus"

// Mobile-friendly dropdown toggle
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Close on click outside - with touch support
    this.boundClickOutside = this.clickOutside.bind(this)
    this.boundEscapeKey = this.escapeKey.bind(this)

    // Add escape key listener
    document.addEventListener("keydown", this.boundEscapeKey)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundEscapeKey)
    document.removeEventListener("click", this.boundClickOutside)
  }

  toggle(event) {
    event?.stopPropagation()

    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    // Add click outside listener when opening
    setTimeout(() => document.addEventListener("click", this.boundClickOutside), 0)

    // Focus first menu item for accessibility
    const firstItem = this.menuTarget.querySelector("a, button")
    if (firstItem) {
      setTimeout(() => firstItem.focus(), 100)
    }
  }

  close() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundClickOutside)
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  escapeKey(event) {
    if (event.key === "Escape" && !this.menuTarget.classList.contains("hidden")) {
      this.close()
      // Return focus to toggle button
      const toggle = this.element.querySelector('[data-action*="toggle"]')
      if (toggle) toggle.focus()
    }
  }
}
