import { Controller } from "@hotwired/stimulus"

// Opens a modal to save a snippet into personal knowledge.
// Extracts text from the message DOM (no huge data-* payloads).
class RememberController extends Controller {
  connect() {
    this._esc = (e) => {
      if (e.key === "Escape") this.close()
    }
    document.addEventListener("keydown", this._esc)

    this.refreshTopicFields()
  }

  disconnect() {
    document.removeEventListener("keydown", this._esc)
  }

  open(event) {
    event.preventDefault()

    const messageEl = event.currentTarget?.closest?.('[id^="message_"]')
    const containerEl = messageEl || event.currentTarget?.closest?.("[data-remember-container]")

    const role = messageEl?.getAttribute("data-message-role") || containerEl?.dataset?.rememberRole || ""

    // Default destination:
    // - user messages often contain user prefs -> USER.md
    // - assistant messages often contain distilled learnings -> MEMORY.md
    const dest = role === "user" ? "user" : (containerEl?.dataset?.rememberDestination || "memory")
    if (this.hasDestinationTarget) this.destinationTarget.value = dest

    const prose = containerEl?.querySelector?.(".prose")
    const txt = prose ? prose.innerText.trim() : ""

    if (this.hasContentTarget) this.contentTarget.value = txt
    if (this.hasTitleTarget) this.titleTarget.value = ""

    this.refreshTopicFields()

    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
    }

    setTimeout(() => {
      try {
        this.contentTarget?.focus?.()
      } catch (_) {}
    }, 50)
  }

  close() {
    if (this.hasModalTarget) this.modalTarget.classList.add("hidden")
  }

  destinationChanged() {
    this.refreshTopicFields()
  }

  refreshTopicFields() {
    if (!this.hasTopicFieldsTarget || !this.hasDestinationTarget) return

    const show = this.destinationTarget.value === "topic"
    if (show) this.topicFieldsTarget.classList.remove("hidden")
    else this.topicFieldsTarget.classList.add("hidden")
  }
}

RememberController.targets = ["modal", "destination", "title", "content", "topicFields", "tags", "version", "source"]

export default RememberController
