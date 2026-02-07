import { Controller } from "@hotwired/stimulus"

// Model picker with:
// - favorites-only default view
// - "show all" toggle
// - fuzzy search
export default class extends Controller {
  static targets = ["search", "select", "toggleAll"]
  static values = {
    models: Array,
    favorites: Array,
    showAll: { type: Boolean, default: false },
  }

  connect() {
    if (!this.hasSelectTarget) return

    // If models aren't provided via data, fall back to current DOM options.
    if (!Array.isArray(this.modelsValue) || this.modelsValue.length === 0) {
      this.modelsValue = Array.from(this.selectTarget.options).map((o) => ({
        label: o.text,
        provider: o.value.split(":", 2)[0],
        model: o.value.split(":", 2)[1],
      }))
    }

    // Normalize favorites to values like "provider:model"
    this._favoriteSet = new Set((this.favoritesValue || []).map((v) => v.toString()))

    // Initial build (favorites only)
    this.refreshOptions()
  }

  toggleAll() {
    this.showAllValue = !!this.toggleAllTarget?.checked
    this.refreshOptions()
  }

  filter() {
    this.refreshOptions()
  }

  refreshOptions() {
    if (!this.hasSelectTarget) return

    const currentValue = this.selectTarget.value
    const term = (this.searchTarget?.value || "").trim().toLowerCase()

    let pool = this.modelsValue.map((m) => ({
      value: `${m.provider}:${m.model}`,
      text: m.label || `${m.model} (${m.provider})`,
    }))

    if (!this.showAllValue) {
      pool = pool.filter((o) => this._favoriteSet.has(o.value))
    }

    let filtered = pool
    if (term.length > 0) {
      const tokens = term.split(/\s+/).filter(Boolean)
      filtered = pool
        .map((o) => ({ ...o, score: this._score(tokens, `${o.text} ${o.value}`.toLowerCase()) }))
        .filter((o) => o.score !== null)
        .sort((a, b) => a.score - b.score)
    }

    // Avoid rendering thousands of options if something goes wrong.
    const MAX_OPTIONS = 400
    filtered = filtered.slice(0, MAX_OPTIONS)

    this.selectTarget.innerHTML = ""
    filtered.forEach((o) => {
      const opt = document.createElement("option")
      opt.value = o.value
      opt.text = o.text
      opt.selected = o.value === currentValue
      this.selectTarget.appendChild(opt)
    })

    // Keep selection stable if possible.
    if (this.selectTarget.options.length > 0 && this.selectTarget.value !== currentValue) {
      const exists = Array.from(this.selectTarget.options).some((o) => o.value === currentValue)
      if (!exists) this.selectTarget.selectedIndex = 0
    }
  }

  submit() {
    this.element.requestSubmit()
  }

  // Returns numeric score (lower is better) or null if no match.
  _score(tokens, hay) {
    let score = 0
    for (const t of tokens) {
      // Fast path: substring match
      const idx = hay.indexOf(t)
      if (idx >= 0) {
        score += idx
        continue
      }

      // Fuzzy subsequence match
      const fuzzyIdx = this._subsequenceIndex(t, hay)
      if (fuzzyIdx === null) return null

      score += fuzzyIdx + 500 // penalize fuzzy matches vs direct substring
    }
    return score
  }

  // If needle is a subsequence of haystack, returns the position of the first match, else null.
  _subsequenceIndex(needle, hay) {
    let i = 0
    let first = null
    for (let j = 0; j < hay.length && i < needle.length; j++) {
      if (hay[j] === needle[i]) {
        if (first === null) first = j
        i++
      }
    }
    return i === needle.length ? (first ?? 0) : null
  }
}
