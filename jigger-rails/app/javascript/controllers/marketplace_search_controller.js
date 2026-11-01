import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "picker", "choice", "chips"]

  connect() {
    this.selections()
    this.sync()
  }

  open() {
    this.panelTarget.open = true
  }

  close() {
    this.panelTarget.open = false
    this.pickerTargets.forEach(picker => { picker.open = false })
    this.panelTarget.querySelector("summary").focus()
  }

  dismiss(event) {
    if (!event.composedPath().includes(this.element)) this.panelTarget.open = false
  }

  sync() {
    const query = this.element.querySelector("#navbar-query")
    query.setAttribute("aria-expanded", String(this.panelTarget.open))
    query.setAttribute("aria-controls", "marketplace-filters")
    this.panelTarget.id = "marketplace-filters"
  }

  filter(event) {
    const query = event.target.value.trim().toLocaleLowerCase()
    event.target.closest("details").querySelectorAll("[data-search-option]").forEach(option => {
      option.hidden = !option.textContent.toLocaleLowerCase().includes(query)
    })
  }

  selections() {
    this.chipsTarget.replaceChildren()
    this.choiceTargets.filter(choice => choice.checked).forEach(choice => {
      const chip = document.createElement("button")
      chip.type = "button"
      chip.textContent = `${choice.dataset.label} ×`
      chip.setAttribute("aria-label", `Remove ${choice.dataset.label}`)
      chip.addEventListener("click", () => {
        choice.checked = false
        this.selections()
      })
      this.chipsTarget.append(chip)
    })
  }
}
