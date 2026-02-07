import { Controller } from "@hotwired/stimulus"

// Chat functionality - auto-scroll, etc.
export default class extends Controller {
  static targets = ["messages"]

  connect() {
    this.scrollToBottom()

    // Observe for new messages
    if (this.hasMessagesTarget) {
      this.observer = new MutationObserver(() => {
        this.scrollToBottom()
      })
      this.observer.observe(this.messagesTarget, { childList: true })
    }
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
