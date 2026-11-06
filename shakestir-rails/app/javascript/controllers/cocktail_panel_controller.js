import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "trigger", "frame"]

  open(event) {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || typeof this.dialogTarget.showModal !== "function") return
    event.preventDefault()
    if (!this.frameTarget.hasAttribute("src")) {
      const url = new URL(event.currentTarget.href)
      url.searchParams.set("panel", "1")
      this.frameTarget.src = url.href
    }
    this.dialogTarget.showModal()
    document.documentElement.classList.add("cocktail-panel-open")
  }

  close() {
    if (this.hasDialogTarget && this.dialogTarget.open) this.dialogTarget.close()
    document.documentElement.classList.remove("cocktail-panel-open")
  }

  restoreFocus() {
    document.documentElement.classList.remove("cocktail-panel-open")
    if (this.hasTriggerTarget && this.triggerTarget.isConnected) this.triggerTarget.focus()
  }

  backdrop(event) {
    if (event.target !== this.dialogTarget) return
    const rect = this.dialogTarget.getBoundingClientRect()
    if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) this.close()
  }

  disconnect() { this.close() }
}
