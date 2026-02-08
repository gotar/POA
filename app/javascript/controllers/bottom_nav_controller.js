import { Controller } from "@hotwired/stimulus"

// BottomNavController
//
// Turbo should re-render the layout on navigation, but in some cases (frame
// navigation, cached snapshots, PWA quirks) the server-rendered "active" state
// can appear stale.
//
// This controller enforces the active state client-side based on
// window.location.pathname.
export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.refresh()

    this._refreshBound = () => this.refresh()
    document.addEventListener("turbo:load", this._refreshBound)
    document.addEventListener("turbo:frame-load", this._refreshBound)
  }

  disconnect() {
    if (this._refreshBound) {
      document.removeEventListener("turbo:load", this._refreshBound)
      document.removeEventListener("turbo:frame-load", this._refreshBound)
    }
  }

  refresh() {
    const path = window.location?.pathname || ""

    this.linkTargets.forEach((el) => {
      const prefix = el.dataset.bottomNavPrefix || ""
      const exact = el.dataset.bottomNavExact === "true"

      const isActive = exact ? path === prefix : (prefix && path.startsWith(prefix))

      // We keep a stable base class list in HTML, and toggle only these.
      el.classList.toggle("bg-gray-800", isActive)
      el.classList.toggle("text-white", isActive)

      el.classList.toggle("text-gray-300", !isActive)

      if (isActive) {
        el.setAttribute("aria-current", "page")
      } else {
        el.removeAttribute("aria-current")
      }
    })
  }
}
