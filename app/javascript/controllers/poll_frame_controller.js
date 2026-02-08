import { Controller } from "@hotwired/stimulus"

// PollFrameController
//
// Attaches to a <turbo-frame> and reloads it until the response includes
// an element with [data-poll-frame-done].
//
// Example:
// <turbo-frame id="kb_search" src="..." data-controller="poll-frame"></turbo-frame>
export default class extends Controller {
  static values = {
    interval: { type: Number, default: 1500 },
    maxSeconds: { type: Number, default: 120 }
  }

  connect() {
    this._startedAt = Date.now()
    this._timer = null

    this._onLoad = this.onLoad.bind(this)
    this.element.addEventListener("turbo:frame-load", this._onLoad)

    this.schedule()
  }

  disconnect() {
    this.stop()
    if (this._onLoad) {
      this.element.removeEventListener("turbo:frame-load", this._onLoad)
    }
  }

  onLoad() {
    if (this.isDone()) {
      this.stop()
    }
  }

  schedule() {
    if (this._timer) return

    this._timer = setInterval(() => {
      if (this.isDone()) {
        this.stop()
        return
      }

      const elapsed = (Date.now() - this._startedAt) / 1000
      if (elapsed > this.maxSecondsValue) {
        this.stop()
        return
      }

      if (typeof this.element.reload === "function") {
        this.element.reload()
      }
    }, this.intervalValue)
  }

  stop() {
    if (this._timer) {
      clearInterval(this._timer)
      this._timer = null
    }
  }

  isDone() {
    return !!this.element.querySelector("[data-poll-frame-done]")
  }
}
