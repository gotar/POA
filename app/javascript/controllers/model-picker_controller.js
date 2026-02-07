import { Controller } from "@hotwired/stimulus"

// Model picker combobox:
// - click to open
// - shows first N models by default
// - typing filters (fuzzy)
// - optional favorites-only mode (default) with "All models" toggle
export default class extends Controller {
  static targets = ["input", "hidden", "panel", "list", "toggleAll"]
  static values = {
    models: Array,
    favorites: Array,
    showAll: { type: Boolean, default: false },
    selected: String,
    selectedLabel: String,
    limit: { type: Number, default: 30 }
  }

  connect() {
    this._favoriteSet = new Set((this.favoritesValue || []).map((v) => v.toString()))

    // If user hasn't typed yet, keep the selected label in the input.
    if (this.hasInputTarget && this.selectedLabelValue) {
      this.inputTarget.value = this.selectedLabelValue
    }

    this._outsideClick = (e) => {
      if (!this.element.contains(e.target)) this.close()
    }
    document.addEventListener("mousedown", this._outsideClick)
    document.addEventListener("touchstart", this._outsideClick)

    // Initial render (not visible until open)
    this.renderList()
  }

  disconnect() {
    document.removeEventListener("mousedown", this._outsideClick)
    document.removeEventListener("touchstart", this._outsideClick)
  }

  open() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.remove("hidden")

    // If input currently equals selected label, treat as empty query (so you see first N models)
    const v = (this.inputTarget.value || "").trim()
    if (v === (this.selectedLabelValue || "").trim()) {
      // keep text but render default list
      this._queryOverride = ""
    } else {
      this._queryOverride = null
    }

    this.renderList()
    // Select all text to make typing easy
    this.inputTarget.setSelectionRange(0, this.inputTarget.value.length)
  }

  close() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.add("hidden")
    this._queryOverride = null
  }

  preventEnter(event) {
    // Prevent form submit when typing in combobox
    event.preventDefault()
  }

  toggleAll() {
    this.showAllValue = !!this.toggleAllTarget?.checked
    this.renderList()
  }

  filter() {
    this.renderList()
  }

  renderList() {
    if (!this.hasListTarget) return

    const raw = (this.inputTarget?.value || "").trim().toLowerCase()
    const term = (this._queryOverride !== null && this._queryOverride !== undefined) ? this._queryOverride : raw

    let pool = (this.modelsValue || []).map((m) => ({
      value: `${m.provider}:${m.model}`,
      label: m.label || `${m.model} (${m.provider})`
    }))

    if (!this.showAllValue) {
      pool = pool.filter((o) => this._favoriteSet.has(o.value) || o.value === this.selectedValue)
    }

    let results = pool
    if (term.length > 0) {
      const tokens = term.split(/\s+/).filter(Boolean)
      results = pool
        .map((o) => ({ ...o, score: this._score(tokens, `${o.label} ${o.value}`.toLowerCase()) }))
        .filter((o) => o.score !== null)
        .sort((a, b) => a.score - b.score)
    } else {
      // Stable ordering when empty term
      results = pool.sort((a, b) => a.label.localeCompare(b.label))
    }

    results = results.slice(0, this.limitValue)

    this.listTarget.innerHTML = ""

    if (results.length === 0) {
      this.listTarget.innerHTML = `<div class="px-3 py-4 text-sm text-gray-400">No models found</div>`
      return
    }

    results.forEach((o) => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.className = `w-full text-left px-3 py-2 text-sm hover:bg-gray-700 ${o.value === this.selectedValue ? "bg-gray-700" : ""}`
      btn.textContent = o.label
      btn.addEventListener("click", () => this.choose(o.value, o.label))
      this.listTarget.appendChild(btn)
    })
  }

  choose(value, label) {
    this.selectedValue = value
    this.selectedLabelValue = label

    if (this.hasHiddenTarget) this.hiddenTarget.value = value
    if (this.hasInputTarget) this.inputTarget.value = label

    this.close()
    // Submit only on explicit selection
    this.element.requestSubmit()
  }

  // Returns numeric score (lower is better) or null if no match.
  _score(tokens, hay) {
    let score = 0
    for (const t of tokens) {
      const idx = hay.indexOf(t)
      if (idx >= 0) {
        score += idx
        continue
      }
      const fuzzyIdx = this._subsequenceIndex(t, hay)
      if (fuzzyIdx === null) return null
      score += fuzzyIdx + 500
    }
    return score
  }

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
