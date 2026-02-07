import { Controller } from "@hotwired/stimulus"

// Model picker combobox:
// - click/focus to open
// - shows first N models by default
// - typing filters models (fuzzy)
// - submits only when a model is explicitly chosen
//
// We fetch the model list from the server (avoid embedding huge JSON in HTML).
class ModelPickerController extends Controller {
  connect() {
    this._favoriteSet = new Set((this.favoritesValue || []).map((v) => v.toString()))
    this._models = null
    this._loading = false
    this._queryOverride = null
    this._results = []
    this._activeIndex = -1
    this._buttons = []

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

    // Reset highlight when opening.
    this._activeIndex = -1

    const v = (this.inputTarget.value || "").trim()
    this._queryOverride = v === (this.selectedLabelValue || "").trim() ? "" : null

    this.ensureModels().then(() => this.renderList())

    try {
      this.inputTarget.setSelectionRange(0, this.inputTarget.value.length)
    } catch (_) {}
  }

  close() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.add("hidden")
    this._queryOverride = null
    this._activeIndex = -1
    this._results = []
    this._buttons = []
  }

  keydown(event) {
    // Handle keyboard navigation robustly (don’t rely solely on Stimulus key modifiers,
    // as some mobile/desktop browsers can be inconsistent for arrow keys).
    switch (event.key) {
      case "ArrowDown":
        return this.down(event)
      case "ArrowUp":
        return this.up(event)
      case "Enter":
        return this.enter(event)
      case "Escape":
        event.preventDefault()
        this.close()
        return
      default:
        return
    }
  }

  enter(event) {
    // Enter selects the currently highlighted item (or the first match).
    event.preventDefault()

    if (!this.hasPanelTarget || this.panelTarget.classList.contains("hidden")) return

    if (Array.isArray(this._results) && this._results.length > 0) {
      const idx = this._activeIndex >= 0 ? this._activeIndex : 0
      const o = this._results[idx]
      if (o) this.choose(o.value, o.label)
    }
  }

  down(event) {
    event.preventDefault()
    this._moveActive(1)
  }

  up(event) {
    event.preventDefault()
    this._moveActive(-1)
  }

  filter() {
    if (this.hasPanelTarget) this.panelTarget.classList.remove("hidden")

    // Once the user starts typing, drop the initial "show default list" override.
    this._queryOverride = null

    if (this._debounced) clearTimeout(this._debounced)
    this._debounced = setTimeout(() => {
      this.ensureModels().then(() => this.renderList())
    }, 80)
  }

  ensureModels() {
    if (this._models) return Promise.resolve(this._models)
    if (this._loading) return Promise.resolve(null)

    if (!this.endpointValue) {
      this.showError("No model endpoint configured")
      return Promise.resolve(null)
    }

    this._loading = true
    this.showLoading()

    return fetch(this.endpointValue, {
      headers: { Accept: "application/json" },
      credentials: "same-origin",
    })
      .then((resp) => resp.json())
      .then((json) => {
        this._models = Array.isArray(json.models) ? json.models : []
        return this._models
      })
      .catch(() => {
        this.showError("Failed to load models")
        return null
      })
      .finally(() => {
        this._loading = false
      })
  }

  showLoading() {
    if (!this.hasListTarget) return
    this.listTarget.innerHTML = '<div class="px-3 py-4 text-sm text-gray-400">Loading models…</div>'
  }

  showError(msg) {
    if (!this.hasListTarget) return
    this.listTarget.innerHTML = `<div class="px-3 py-4 text-sm text-red-300">${msg}</div>`
  }

  renderList() {
    if (!this.hasListTarget) return

    const raw = (this.inputTarget.value || "").trim().toLowerCase()
    const term = this._queryOverride !== null ? this._queryOverride : raw

    const models = Array.isArray(this._models) ? this._models : []

    let pool = models.map((m) => ({
      value: `${m.provider}:${m.model}`,
      label: m.label || `${m.model} (${m.provider})`,
    }))

    if (term.length === 0) {
      const favs = pool.filter((o) => this._favoriteSet.has(o.value))
      const rest = pool.filter((o) => !this._favoriteSet.has(o.value))
      pool = favs.concat(rest)
    }

    let results = pool
    if (term.length > 0) {
      const tokens = term.split(/\s+/).filter(Boolean)
      results = pool
        .map((o) => ({ value: o.value, label: o.label, score: this._score(tokens, `${o.label} ${o.value}`.toLowerCase()) }))
        .filter((o) => o.score !== null)
        .sort((a, b) => a.score - b.score)
    }

    results = results.slice(0, this.limitValue)

    this._results = results
    this._buttons = []

    this.listTarget.innerHTML = ""

    if (results.length === 0) {
      this._activeIndex = -1
      this.listTarget.innerHTML = '<div class="px-3 py-4 text-sm text-gray-400">No models found</div>'
      return
    }

    // Auto-highlight the first match when searching.
    if (term.length > 0) {
      this._activeIndex = 0
    } else if (this._activeIndex < 0 || this._activeIndex >= results.length) {
      this._activeIndex = 0
    }

    results.forEach((o, idx) => {
      const btn = document.createElement("button")
      btn.type = "button"

      const isSelected = o.value === this.selectedValue
      const isActive = idx === this._activeIndex

      btn.className = [
        "w-full text-left px-3 py-2 text-sm",
        "hover:bg-gray-700",
        isSelected ? "bg-gray-700" : "",
        isActive ? "ring-1 ring-inset ring-purple-500" : "",
      ]
        .filter(Boolean)
        .join(" ")

      btn.textContent = o.label
      btn.addEventListener("mouseenter", () => this._setActive(idx))
      btn.addEventListener("click", () => this.choose(o.value, o.label))

      this._buttons.push(btn)
      this.listTarget.appendChild(btn)
    })

    this._applyActiveStyles()
    this._scrollActiveIntoView()
  }

  choose(value, label) {
    this.selectedValue = value
    this.selectedLabelValue = label

    if (this.hasHiddenTarget) this.hiddenTarget.value = value
    if (this.hasInputTarget) this.inputTarget.value = label

    this.close()

    if (this.autoSubmitValue) {
      this.requestSubmit()
    }
  }

  _moveActive(delta) {
    if (!this.hasPanelTarget) return

    if (this.panelTarget.classList.contains("hidden")) {
      this.open()
      return
    }

    // If the list isn't rendered yet, render it first.
    if (!Array.isArray(this._results) || this._results.length === 0) {
      this.ensureModels().then(() => this.renderList())
      return
    }

    const next = Math.max(0, Math.min(this._results.length - 1, (this._activeIndex >= 0 ? this._activeIndex : 0) + delta))
    this._setActive(next)
  }

  _setActive(idx) {
    if (!Array.isArray(this._results) || this._results.length === 0) return
    const clamped = Math.max(0, Math.min(this._results.length - 1, idx))
    this._activeIndex = clamped
    this._applyActiveStyles()
    this._scrollActiveIntoView()
  }

  _applyActiveStyles() {
    if (!Array.isArray(this._buttons) || this._buttons.length === 0) return

    for (let i = 0; i < this._buttons.length; i++) {
      const btn = this._buttons[i]
      if (!btn) continue

      const isActive = i === this._activeIndex
      if (isActive) {
        btn.classList.add("ring-1", "ring-inset", "ring-purple-500")
      } else {
        btn.classList.remove("ring-1", "ring-inset", "ring-purple-500")
      }
    }
  }

  _scrollActiveIntoView() {
    if (!Array.isArray(this._buttons) || this._buttons.length === 0) return
    const btn = this._buttons[this._activeIndex]
    if (btn && typeof btn.scrollIntoView === "function") {
      btn.scrollIntoView({ block: "nearest" })
    }
  }

  requestSubmit() {
    const el = this.element

    // requestSubmit exists only on <form>
    if (el && typeof el.requestSubmit === "function") {
      el.requestSubmit()
      return
    }

    const form = el?.closest?.("form")
    if (form && typeof form.requestSubmit === "function") {
      form.requestSubmit()
      return
    }

    // last resort
    if (form) form.submit()
  }

  _score(tokens, hay) {
    let score = 0

    for (let k = 0; k < tokens.length; k++) {
      const t = tokens[k]
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

    return i === needle.length ? (first === null ? 0 : first) : null
  }
}

// Avoid class fields (better compatibility with older mobile Safari).
ModelPickerController.targets = ["input", "hidden", "panel", "list"]
ModelPickerController.values = {
  endpoint: String,
  favorites: Array,
  selected: String,
  selectedLabel: String,
  limit: { type: Number, default: 30 },
  autoSubmit: { type: Boolean, default: true },
}

export default ModelPickerController
