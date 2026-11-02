import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progress"]

  connect() {
    if (!this.hasProgressTarget) return
    this.progressTarget.hidden = false
    this.update()
  }

  update() {
    const total = this.stepTargets.length
    const completed = this.stepTargets.filter(step => step.checked).length
    this.progressTarget.max = Math.max(total, 1)
    this.progressTarget.value = completed
    this.progressTarget.setAttribute("aria-valuetext", completed === total ? "All steps complete. Enjoy your cocktail." : `${completed} of ${total} steps complete`)
  }
}
