import { Controller } from "@hotwired/stimulus"

// Adds client-side filtering to the model picker (<select>) so it is usable on mobile.
export default class extends Controller {
  static targets = ["search", "select"]

  connect() {
    if (!this.hasSelectTarget) return

    // Snapshot original options (preserve selected)
    this._allOptions = Array.from(this.selectTarget.options).map((o) => ({
      value: o.value,
      text: o.text,
      selected: o.selected,
    }))
  }

  filter() {
    if (!this.hasSelectTarget) return

    const term = (this.searchTarget?.value || "").trim().toLowerCase()
    const currentValue = this.selectTarget.value

    const options = term.length === 0
      ? this._allOptions
      : this._allOptions.filter((o) => o.text.toLowerCase().includes(term) || o.value.toLowerCase().includes(term))

    // Rebuild options list
    this.selectTarget.innerHTML = ""
    options.forEach((o) => {
      const opt = document.createElement("option")
      opt.value = o.value
      opt.text = o.text
      opt.selected = o.value === currentValue
      this.selectTarget.appendChild(opt)
    })

    // If the current selection disappeared, fall back to first option
    if (this.selectTarget.options.length > 0 && this.selectTarget.value !== currentValue) {
      this.selectTarget.selectedIndex = 0
    }
  }

  submit() {
    // submit on change
    this.element.requestSubmit()
  }
}
