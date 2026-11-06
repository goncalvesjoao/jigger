import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "progress", "status", "reset", "controls"]

  connect() {
    this.progressTarget.hidden = this.itemTargets.length === 0
    if (this.hasControlsTarget) this.controlsTarget.hidden = false
    this.update()
  }

  update() {
    const total = this.itemTargets.length
    const gathered = this.itemTargets.filter(item => item.checked).length
    const message = `${gathered} of ${total} gathered`
    this.progressTarget.max = Math.max(total, 1)
    this.progressTarget.value = gathered
    this.progressTarget.setAttribute("aria-valuetext", message)
    if (this.hasStatusTarget) this.statusTarget.textContent = message
    if (this.hasResetTarget) this.resetTarget.disabled = gathered === 0
  }

  reset() {
    this.itemTargets.forEach(item => { item.checked = false })
    this.update()
  }
}
