import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progress", "summary", "status"]

  connect() {
    if (!this.hasStatusTarget) return
    this.statusTarget.hidden = false
    this.update()
  }

  update() {
    const total = this.stepTargets.length
    const completed = this.stepTargets.filter(step => step.checked).length
    this.progressTarget.max = total
    this.progressTarget.value = completed
    this.summaryTarget.textContent = completed === total ? "All steps complete. Enjoy your cocktail." : `${completed} of ${total} steps complete`
  }

  reset() {
    this.stepTargets.forEach(step => { step.checked = false })
    this.update()
  }
}
