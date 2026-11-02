import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "progress"]

  connect() {
    this.progressTarget.hidden = false
    this.update()
  }

  update() {
    const gathered = this.itemTargets.filter(item => item.checked).length
    this.progressTarget.max = Math.max(this.itemTargets.length, 1)
    this.progressTarget.value = gathered
    this.progressTarget.setAttribute("aria-valuetext", `${gathered} of ${this.itemTargets.length} gathered`)
  }
}
