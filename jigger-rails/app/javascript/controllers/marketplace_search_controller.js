import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["picker", "choice", "chips", "help", "status"]

  connect() {
    this.selections()
    this.mode()
    this.sync()
  }

  disconnect() {
    clearTimeout(this.searchTimer)
    this.request?.abort()
  }

  search(event) {
    clearTimeout(this.searchTimer)
    this.request?.abort()
    if (event.isComposing) return
    this.searchTimer = setTimeout(() => this.apply(), 300)
  }

  submit(event) {
    event.preventDefault()
    this.apply()
  }

  changeSelections() {
    this.selections()
    this.apply()
  }

  changeMode(event) {
    const picker = event.currentTarget.closest("details")
    this.element.elements[picker.dataset.modeKey].value = event.currentTarget.dataset.mode
    this.mode()
    this.apply()
  }

  async apply() {
    clearTimeout(this.searchTimer)
    this.request?.abort()
    const request = new AbortController()
    this.request = request
    const url = new URL(this.element.action)
    url.search = new URLSearchParams(new FormData(this.element)).toString()
    const results = document.getElementById("marketplace-results")
    results.setAttribute("aria-busy", "true")
    this.statusTarget.hidden = true
    try {
      const response = await fetch(url, { signal: request.signal, headers: { Accept: "text/html" } })
      if (!response.ok) throw new Error("Search failed")
      const page = new DOMParser().parseFromString(await response.text(), "text/html")
      const updated = page.getElementById("marketplace-results")
      if (!updated) throw new Error("Missing results")
      if (request.signal.aborted) return
      results.replaceChildren(...updated.childNodes)
      history.replaceState(history.state, "", url)
    } catch (error) {
      if (error.name !== "AbortError") {
        this.statusTarget.textContent = "Couldn’t update results. Please try Search again."
        this.statusTarget.hidden = false
      }
    } finally {
      if (this.request === request) results.removeAttribute("aria-busy")
    }
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
    this.changeSelections()
    event.target.closest("details").querySelector("input[type=search]").focus()
  }

  done(event) {
    const picker = event.target.closest("details")
    picker.open = false
    picker.querySelector("summary").focus()
  }

  mode() {
    const summaries = this.pickerTargets.map(picker => {
      const value = this.element.elements[picker.dataset.modeKey].value
      picker.querySelectorAll("[data-mode]").forEach(button => {
        button.setAttribute("aria-pressed", String(button.dataset.mode === value))
      })
      picker.querySelector("[data-mode-hint]").hidden = value !== "only"
      const label = picker.querySelector("summary strong").textContent
      return `${label}: ${value === "only" ? "Use only what I have" : "Include these items"}`
    })
    this.helpTarget.textContent = summaries.join(" · ")
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
        this.changeSelections()
        const replacement = next && [...this.chipsTarget.children].find(item => item.textContent === next.textContent)
        ;(replacement || this.element.querySelector("#marketplace-query")).focus()
      })
      this.chipsTarget.append(chip)
    })
    this.pickerTargets.forEach(picker => {
      const count = picker.querySelectorAll("input[type=checkbox]:checked").length
      picker.querySelector("[data-picker-clear]").hidden = count === 0
      const label = picker.querySelector("strong").textContent.toLowerCase()
      const countLabel = count ? `${count} selected` : `Add ${label}`
      picker.querySelector("[data-picker-count]").textContent = countLabel
      picker.querySelector("[data-picker-selection-count]").textContent = countLabel
    })
  }
}
