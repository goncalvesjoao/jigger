import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["picker", "choice", "chips", "help"]

  connect() {
    this.selections()
    this.mode()
    this.sync()
  }

  close() {
    const active = this.pickerTargets.find(picker => picker.open)
    this.pickerTargets.forEach(picker => { picker.open = false })
    active?.querySelector("summary").focus()
  }

  dismiss(event) {
    this.pickerTargets.forEach(picker => {
      if (!event.composedPath().includes(picker)) picker.open = false
    })
  }

  sync(event) {
    const current = event?.target
    if (current?.open) {
      this.pickerTargets.forEach(picker => { if (picker !== current) picker.open = false })
    }
    this.pickerTargets.forEach(picker => {
      picker.querySelector("summary").setAttribute("aria-expanded", String(picker.open))
    })
  }

  filter(event) {
    const picker = event.target.closest("details")
    const query = event.target.value.trim().toLocaleLowerCase()
    const options = [...picker.querySelectorAll("[data-search-option]")]
    options.forEach(option => { option.hidden = !option.textContent.toLocaleLowerCase().includes(query) })
    picker.querySelector("[data-picker-empty]").hidden = options.some(option => !option.hidden)
  }

  clearPicker(event) {
    event.target.closest("details").querySelectorAll("input[type=checkbox]").forEach(choice => { choice.checked = false })
    this.selections()
  }

  done(event) {
    const picker = event.target.closest("details")
    picker.open = false
    picker.querySelector("summary").focus()
  }

  mode() {
    const makeable = this.element.querySelector('input[name="makeable"]:checked').value === "1"
    this.helpTarget.textContent = makeable
      ? "Select everything you have, including ice and tools. Recipes needing anything else are excluded; optional ingredients are ignored."
      : "Find recipes containing every selected ingredient and utensil. Other items may also be needed."
  }

  selections() {
    this.chipsTarget.replaceChildren()
    this.choiceTargets.filter(choice => choice.checked).forEach(choice => {
      const chip = document.createElement("button")
      chip.type = "button"
      chip.textContent = choice.dataset.label
      chip.className = "marketplace-chip"
      chip.setAttribute("aria-label", `Remove ${choice.dataset.label}`)
      chip.addEventListener("click", () => {
        const next = chip.nextElementSibling || chip.previousElementSibling
        choice.checked = false
        this.selections()
        const replacement = next && [...this.chipsTarget.children].find(item => item.textContent === next.textContent)
        ;(replacement || this.element.querySelector("#marketplace-query")).focus()
      })
      this.chipsTarget.append(chip)
    })
    this.pickerTargets.forEach(picker => {
      const count = picker.querySelectorAll("input[type=checkbox]:checked").length
      const label = picker.querySelector("strong").textContent.toLowerCase()
      picker.querySelector("[data-picker-count]").textContent = count ? `${count} selected` : `Add ${label}`
    })
  }
}
