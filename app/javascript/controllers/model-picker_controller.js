import { Controller } from "@hotwired/stimulus"

// Model picker combobox:
// - click to open
// - shows first N models by default
// - typing filters (fuzzy) across ALL models
//
// We DO NOT embed the full model list in HTML attributes (too large/fragile on mobile Safari).
// Instead we fetch it from the server endpoint.
export default class extends Controller {
  static targets = ["input", "hidden", "panel", "list"]
  static values = {
    endpoint: String,
    favorites: Array,
    selected: String,
    selectedLabel: String,
    limit: { type: Number, default: 30 }
  }

  connect() {
    this._favoriteSet = new Set((this.favoritesValue || []).map((v) => v.toString()))
    this._models = null
    this._loading = false
    this._queryOverride = null

    if (this.hasInputTarget && this.selectedLabelValue) {
      this.inputTarget.value = this.selectedLabelValue
    }

    this._outsideClick = (e) => {
      if (!this.element.contains(e.target)) this.close()
    }
    document.addEventListener("mousedown", this._outsideClick)
    document.addEventListener("touchstart", this._outsideClick)

    this._debounced = null
  }

  disconnect() {
    document.removeEventListener("mousedown", this._outsideClick)
    document.removeEventListener("touchstart", this._outsideClick)
  }

  open() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.remove("hidden")

    const v = (this.inputTarget.value || "").trim()
    this._queryOverride = v === (this.selectedLabelValue || "").trim() ? "" : null

    this.ensureModels().then(() => this.renderList())

    // Select all text to make typing easy
    try {
      this.inputTarget.setSelectionRange(0, this.inputTarget.value.length)
    } catch (_) {}
  }

  close() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.add("hidden")
    this._queryOverride = null
  }

  preventEnter(event) {
    event.preventDefault()
  }

  filter() {
    // Ensure panel open while typing
    if (this.hasPanelTarget) this.panelTarget.classList.remove("hidden")

    // debounce filtering while models load
    if (this._debounced) clearTimeout(this._debounced)
    this._debounced = setTimeout(async () => {
      await this.ensureModels()
      this.renderList()
    }, 80)
  }

  async ensureModels() {
    if (this._models) return this._models
    if (this._loading) return null
    if (!this.endpointValue) return null

    this._loading = true
    this.showLoading()

    try {
      const resp = await fetch(this.endpointValue, { headers: { "Accept": "application/json" }, credentials: "same-origin" })
      const json = await resp.json()
      this._models = Array.isArray(json.models) ? json.models : (Array.isArray(json?.data?.models) ? json.data.models : [])
      return this._models
    } catch (e) {
      this.showError("Failed to load models")
      return null
    } finally {
      this._loading = false
    }
  }

  showLoading() {
    if (!this.hasListTarget) return
    this.listTarget.innerHTML = `<div class="px-3 py-4 text-sm text-gray-400">Loading models…</div>`
  }

  showError(msg) {
    if (!this.hasListTarget) return
    this.listTarget.innerHTML = `<div class="px-3 py-4 text-sm text-red-300">${msg}</div>`
  }

  renderList() {
    if (!this.hasListTarget) return

    const raw = (this.inputTarget?.value || "").trim().toLowerCase()
    const term = (this._queryOverride !== null && this._queryOverride !== undefined) ? this._queryOverride : raw

    const models = Array.isArray(this._models) ? this._models : []

    let pool = models.map((m) => ({
      value: `${m.provider}:${m.model}`,
      label: m.label || `${m.model} (${m.provider})`
    }))

    // Default view (empty search): favorites first, then the rest
    if (term.length === 0) {
      const favs = pool.filter((o) => this._favoriteSet.has(o.value))
      const rest = pool.filter((o) => !this._favoriteSet.has(o.value))
      pool = [...favs, ...rest]
    }

    let results = pool
    if (term.length > 0) {
      const tokens = term.split(/\s+/).filter(Boolean)
      results = pool
        .map((o) => ({ ...o, score: this._score(tokens, `${o.label} ${o.value}`.toLowerCase()) }))
        .filter((o) => o.score !== null)
        .sort((a, b) => a.score - b.score)
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
