import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "trigger"]

  connect() {
    if (typeof this.dialogTarget.showModal === "function") {
      this.triggerTarget.setAttribute("aria-haspopup", "dialog")
    }
  }

  open(event) {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
    if (typeof this.dialogTarget.showModal !== "function") return
    event.preventDefault()
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  restoreFocus() {
    if (this.triggerTarget.isConnected) this.triggerTarget.focus()
  }

  backdrop(event) {
    if (event.target !== this.dialogTarget) return
    const rect = this.dialogTarget.getBoundingClientRect()
    if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) this.close()
  }

  disconnect() {
    this.close()
  }
}
