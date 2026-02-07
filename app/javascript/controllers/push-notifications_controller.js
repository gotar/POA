import { Controller } from "@hotwired/stimulus"

// Enables Web Push notifications for scheduled jobs (per project).
// iOS: requires iOS 16.4+ and the app installed to Home Screen.
export default class extends Controller {
  static values = {
    enabledText: { type: String, default: "Disable notifications" },
    disabledText: { type: String, default: "Enable notifications" },
  }

  connect() {
    this.refreshLabel()
  }

  async toggle() {
    if (!this.supported()) {
      alert("Push notifications are not supported in this browser.")
      return
    }

    const reg = await navigator.serviceWorker.ready
    const existing = await reg.pushManager.getSubscription()

    if (existing) {
      await existing.unsubscribe()
      await this.unregisterOnServer(existing)
      await this.refreshLabel()
      return
    }

    const vapidPublicKey = document.querySelector('meta[name="vapid-public-key"]')?.content
    if (!vapidPublicKey) {
      alert("Push is not configured on the server (missing VAPID_PUBLIC_KEY).")
      return
    }

    const perm = await Notification.requestPermission()
    if (perm !== "granted") {
      await this.refreshLabel()
      return
    }

    const sub = await reg.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(vapidPublicKey),
    })

    await this.registerOnServer(sub)
    await this.refreshLabel()
  }

  supported() {
    return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window
  }

  async refreshLabel() {
    if (!this.supported()) {
      this.element.textContent = "Notifications unavailable"
      this.element.disabled = true
      return
    }

    const reg = await navigator.serviceWorker.ready
    const existing = await reg.pushManager.getSubscription()
    if (existing) {
      this.element.textContent = this.enabledTextValue
    } else {
      this.element.textContent = this.disabledTextValue
    }
  }

  projectId() {
    const match = window.location.pathname.match(/\/projects\/(\d+)/)
    return match ? match[1] : null
  }

  async registerOnServer(sub) {
    const projectId = this.projectId()
    if (!projectId) return

    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    await fetch(`/projects/${projectId}/push_subscription`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrf,
      },
      body: JSON.stringify({ subscription: sub.toJSON() }),
      credentials: "same-origin",
    })
  }

  async unregisterOnServer(sub) {
    const projectId = this.projectId()
    if (!projectId) return

    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    await fetch(`/projects/${projectId}/push_subscription`, {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrf,
      },
      body: JSON.stringify({ endpoint: sub.endpoint }),
      credentials: "same-origin",
    })
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")

    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }
}
