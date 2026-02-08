import { Controller } from "@hotwired/stimulus"

// Chat functionality - auto-scroll, etc.
export default class extends Controller {
  static targets = ["messages"]

  connect() {
    this.queueScrollToBottom()

    // Observe for new messages or streaming updates
    if (this.hasMessagesTarget) {
      this.observer = new MutationObserver(() => {
        this.queueScrollToBottom()
      })
      this.observer.observe(this.messagesTarget, {
        childList: true,
        subtree: true,
        characterData: true
      })
    }
  }

  queueScrollToBottom() {
    if (this.scrollQueued) return
    this.scrollQueued = true
    requestAnimationFrame(() => {
      this.scrollQueued = false
      this.scrollToBottom()
    })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}
