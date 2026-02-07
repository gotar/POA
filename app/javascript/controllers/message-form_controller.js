import { Controller } from "@hotwired/stimulus"

// Handles message form interactions
export default class extends Controller {
  static targets = ["input", "submit", "todoPanel", "questionsPanel"]

  connect() {
    this.autoResize()
  }

  // Submit on Enter (without Shift)
  submitExceptShift(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  // Auto-resize textarea
  autoResize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = Math.min(input.scrollHeight, 128) + "px"
  }

  // Reset form after submit
  reset() {
    this.element.reset()
    this.inputTarget.style.height = "auto"
    this.inputTarget.focus()
  }

  // Toggle TODO panel
  toggleTodoPanel() {
    if (this.hasTodoPanelTarget) {
      this.todoPanelTarget.classList.toggle("hidden")
    }
    // Hide questions panel if open
    if (this.hasQuestionsPanelTarget) {
      this.questionsPanelTarget.classList.add("hidden")
    }
  }

  // Toggle questions panel
  toggleQuestions() {
    if (this.hasQuestionsPanelTarget) {
      this.questionsPanelTarget.classList.toggle("hidden")
    }
    // Hide todo panel if open
    if (this.hasTodoPanelTarget) {
      this.todoPanelTarget.classList.add("hidden")
    }
  }

  // Complete a todo
  completeTodo(event) {
    const todoId = event.target.dataset.messageFormTodoIdParam
    if (todoId && confirm("Mark this TODO as completed?")) {
      // Submit to complete the todo
      const form = document.createElement("form")
      form.method = "POST"
      form.action = `/projects/${this.getProjectId()}/todos/${todoId}/complete`

      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      if (csrfToken) {
        const csrfInput = document.createElement("input")
        csrfInput.type = "hidden"
        csrfInput.name = "authenticity_token"
        csrfInput.value = csrfToken
        form.appendChild(csrfInput)
      }

      document.body.appendChild(form)
      form.submit()
    } else {
      event.target.checked = false
    }
  }

  // Edit a todo (placeholder for future enhancement)
  editTodo(event) {
    const todoId = event.target.dataset.messageFormTodoIdParam
    alert(`Edit TODO ${todoId} - Feature coming soon!`)
  }

  // Add new todo (from the quick TODO panel)
  addTodo(event) {
    // Can be triggered by submit, click, or keydown.enter
    if (event) event.preventDefault()

    const container = event?.target?.closest?.("[data-message-form-todo-add-container]") || event?.target
    const input = container?.querySelector?.('input[type="text"]')

    const content = (input?.value || "").trim()
    if (!content) return

    // Submit to create new todo
    const createForm = document.createElement("form")
    createForm.method = "POST"
    createForm.action = `/projects/${this.getProjectId()}/todos`

    const contentInput = document.createElement("input")
    contentInput.type = "hidden"
    contentInput.name = "todo[content]"
    contentInput.value = content

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken
      createForm.appendChild(csrfInput)
    }

    createForm.appendChild(contentInput)
    document.body.appendChild(createForm)
    createForm.submit()

    // Optimistic UI reset
    if (input) input.value = ""
  }

  // Ask a predefined question
  askQuestion(event) {
    // Use currentTarget (the <button>) because clicks can originate from nested <div>s
    const question = event.currentTarget?.dataset?.messageFormQuestionParam
    if (question) {
      this.inputTarget.value = question
      this.inputTarget.focus()
      this.autoResize()
      // Hide the panel
      if (this.hasQuestionsPanelTarget) {
        this.questionsPanelTarget.classList.add("hidden")
      }
    }
  }

  // Get project ID from URL
  getProjectId() {
    const match = window.location.pathname.match(/\/projects\/(\d+)/)
    return match ? match[1] : null
  }
}
