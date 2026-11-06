import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "trigger", "frame", "external"]

  open(event) {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || typeof this.dialogTarget.showModal !== "function") return
    event.preventDefault()
    this.activeTrigger = event.currentTarget
    const url = new URL(this.activeTrigger.href)
    url.searchParams.set("panel", "1")
    const title = this.activeTrigger.dataset.panelTitle
    const kind = this.activeTrigger.dataset.panelKind
    this.dialogTarget.setAttribute("aria-label", title)
    this.frameTarget.title = title
    this.externalTarget.href = this.activeTrigger.href
    this.externalTarget.setAttribute("aria-label", `Open ${kind} in a new tab`)
    this.externalTarget.title = `Open ${kind} in a new tab`
    const closeButton = this.dialogTarget.querySelector(".cocktail-panel-close")
    closeButton.setAttribute("aria-label", `Close ${kind}`)
    closeButton.title = `Close ${kind}`
    if (this.frameTarget.src !== url.href) this.frameTarget.src = url.href
    this.dialogTarget.showModal()
    document.documentElement.classList.add("cocktail-panel-open")
  }

  close() {
    if (this.hasDialogTarget && this.dialogTarget.open) this.dialogTarget.close()
    document.documentElement.classList.remove("cocktail-panel-open")
  }

  restoreFocus() {
    document.documentElement.classList.remove("cocktail-panel-open")
    if (this.activeTrigger?.isConnected) this.activeTrigger.focus()
  }

  backdrop(event) {
    if (event.target !== this.dialogTarget) return
    const rect = this.dialogTarget.getBoundingClientRect()
    if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) this.close()
  }

  disconnect() { this.close() }
}
