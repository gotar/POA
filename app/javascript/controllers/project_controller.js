import { Controller } from "@hotwired/stimulus"

// Manages mobile tab switching between chats, todos, notes, knowledge base, and scheduled jobs
export default class extends Controller {
  static targets = ["chatsPanel", "todosPanel", "notesPanel", "knowledgePanel", "scheduledPanel", "chatsTab", "todosTab", "notesTab", "knowledgeTab", "scheduledTab"]

  showChats() {
    this.hideAll()
    if (this.hasChatsPanelTarget) {
      this.chatsPanelTarget.classList.remove("hidden")
      this.chatsPanelTarget.classList.add("flex")
    }
    this.setActiveTab(this.chatsTabTarget)
  }

  showTodos() {
    this.hideAll()
    if (this.hasTodosPanelTarget) {
      this.todosPanelTarget.classList.remove("hidden")
      this.todosPanelTarget.classList.add("flex", "flex-col")
    }
    this.setActiveTab(this.todosTabTarget)
  }

  showNotes() {
    this.hideAll()
    if (this.hasNotesPanelTarget) {
      this.notesPanelTarget.classList.remove("hidden")
      this.notesPanelTarget.classList.add("flex", "flex-col")
    }
    this.setActiveTab(this.notesTabTarget)
  }

  showKnowledge() {
    this.hideAll()
    if (this.hasKnowledgePanelTarget) {
      this.knowledgePanelTarget.classList.remove("hidden")
      this.knowledgePanelTarget.classList.add("flex", "flex-col")
    }
    this.setActiveTab(this.knowledgeTabTarget)
  }

  showScheduled() {
    this.hideAll()
    if (this.hasScheduledPanelTarget) {
      this.scheduledPanelTarget.classList.remove("hidden")
      this.scheduledPanelTarget.classList.add("flex", "flex-col")
    }
    this.setActiveTab(this.scheduledTabTarget)
  }

  hideAll() {
    // Hide all panels if they exist
    if (this.hasChatsPanelTarget) {
      this.chatsPanelTarget.classList.add("hidden")
      this.chatsPanelTarget.classList.remove("flex", "flex-col")
    }
    if (this.hasTodosPanelTarget) {
      this.todosPanelTarget.classList.add("hidden")
      this.todosPanelTarget.classList.remove("flex", "flex-col")
    }
    if (this.hasNotesPanelTarget) {
      this.notesPanelTarget.classList.add("hidden")
      this.notesPanelTarget.classList.remove("flex", "flex-col")
    }
    if (this.hasKnowledgePanelTarget) {
      this.knowledgePanelTarget.classList.add("hidden")
      this.knowledgePanelTarget.classList.remove("flex", "flex-col")
    }
    if (this.hasScheduledPanelTarget) {
      this.scheduledPanelTarget.classList.add("hidden")
      this.scheduledPanelTarget.classList.remove("flex", "flex-col")
    }

    // Reset all tabs if they exist
    if (this.hasChatsTabTarget) {
      this.chatsTabTarget.classList.remove("bg-gray-600", "text-white")
      this.chatsTabTarget.classList.add("text-gray-400")
    }
    if (this.hasTodosTabTarget) {
      this.todosTabTarget.classList.remove("bg-gray-600", "text-white")
      this.todosTabTarget.classList.add("text-gray-400")
    }
    if (this.hasNotesTabTarget) {
      this.notesTabTarget.classList.remove("bg-gray-600", "text-white")
      this.notesTabTarget.classList.add("text-gray-400")
    }
    if (this.hasKnowledgeTabTarget) {
      this.knowledgeTabTarget.classList.remove("bg-gray-600", "text-white")
      this.knowledgeTabTarget.classList.add("text-gray-400")
    }
    if (this.hasScheduledTabTarget) {
      this.scheduledTabTarget.classList.remove("bg-gray-600", "text-white")
      this.scheduledTabTarget.classList.add("text-gray-400")
    }
  }

  setActiveTab(tab) {
    if (tab) {
      tab.classList.add("bg-gray-600", "text-white")
      tab.classList.remove("text-gray-400")
    }
  }
}
