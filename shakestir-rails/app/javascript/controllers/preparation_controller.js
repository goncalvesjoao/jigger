import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progress", "status", "reset", "controls"]

  connect() {
    if (!this.hasProgressTarget) return
    this.progressTarget.hidden = false
    if (this.hasControlsTarget) this.controlsTarget.hidden = false
    this.update()
  }

  update() {
    if (!this.hasProgressTarget) return
    const total = this.stepTargets.length
    const completed = this.stepTargets.filter(step => step.checked).length
    const message = completed === total ? "All steps complete. Enjoy your drink." : `${completed} of ${total} steps complete`
    this.progressTarget.max = Math.max(total, 1)
    this.progressTarget.value = completed
    this.progressTarget.setAttribute("aria-valuetext", message)
    if (this.hasStatusTarget) this.statusTarget.textContent = message
    if (this.hasResetTarget) this.resetTarget.disabled = completed === 0
  }

  reset() {
    this.stepTargets.forEach(step => { step.checked = false })
    this.update()
  }
}
