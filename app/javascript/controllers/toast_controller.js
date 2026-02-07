import { Controller } from "@hotwired/stimulus"

class ToastController extends Controller {
  connect() {
    this._t = setTimeout(() => {
      try {
        this.element.remove()
      } catch (_) {}
    }, 3500)
  }

  disconnect() {
    if (this._t) clearTimeout(this._t)
  }
}

export default ToastController
