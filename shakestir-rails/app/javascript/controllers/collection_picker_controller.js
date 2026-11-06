import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "status", "choices", "create", "trigger"]
  static values = { removeUrl: String, recipeId: Number }

  open() { this.dialogTarget.showModal() }
  close() { this.dialogTarget.close() }
  backdrop(event) { if (event.target === this.dialogTarget) this.close() }

  save(event) { this.submit(event, false) }
  create(event) { this.submit(event, true) }

  updateChoice(button, saved) {
    button.setAttribute("aria-pressed", String(saved))
    button.querySelector(".collection-choice-indicator").textContent = saved ? "✓" : "+"
  }

  syncStar(event) {
    const state = event.detail
    if (state.recipe_id !== this.recipeIdValue) return
    const choice = this.choicesTarget.querySelector(`[value="${state.favorites_collection_id}"]`)
    if (choice) this.updateChoice(choice, state.starred)
    this.updateTrigger()
  }

  updateTrigger() {
    const anySaved = this.choicesTarget.querySelector('[aria-pressed="true"]') !== null
    this.triggerTarget.querySelector("span").textContent = anySaved ? "✓" : "+"
  }

  async submit(event, creating) {
    event.preventDefault()
    if (this.saving) return
    this.saving = true
    const button = event.submitter
    const data = new FormData(event.target)
    if (button?.name) data.set(button.name, button.value)
    const removing = !creating && button?.getAttribute("aria-pressed") === "true"
    const url = removing ? this.removeUrlValue.replace(/:collection_id|%3Acollection_id/gi, button.value) : event.target.action
    if (button) button.disabled = true
    this.statusTarget.textContent = removing ? "Removing…" : "Saving…"
    try {
      const response = await fetch(url, {
        method: removing ? "DELETE" : "POST",
        headers: { Accept: "application/json", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content },
        body: data
      })
      if (!response.headers.get("content-type")?.includes("application/json")) throw new Error("Please reload the page and sign in again.")
      const collection = await response.json()
      if (!response.ok) throw new Error(collection.error || "Could not update collection. Please try again.")
      if (creating) {
        const choice = document.createElement("button")
        choice.type = "submit"
        choice.name = "collection_id"
        choice.value = collection.id
        choice.className = "collection-choice"
        const name = document.createElement("span")
        name.textContent = collection.name
        const visibility = document.createElement("small")
        visibility.textContent = collection.visibility === "public" ? "Public" : "Private"
        const indicator = document.createElement("span")
        indicator.className = "collection-choice-indicator"
        indicator.setAttribute("aria-hidden", "true")
        choice.append(name, visibility, indicator)
        this.updateChoice(choice, collection.saved)
        this.choicesTarget.append(choice)
        this.createTarget.open = false
        event.target.reset()
      }
      if (!creating) this.updateChoice(button, collection.saved)
      this.updateTrigger()
      window.dispatchEvent(new CustomEvent("recipe-star:changed", { detail: collection }))
      this.statusTarget.textContent = collection.saved ? `Saved to ${collection.name}.` : `Removed from ${collection.name}.`
    } catch (error) {
      this.statusTarget.textContent = error.message
    } finally {
      if (button) button.disabled = false
      this.saving = false
    }
  }
}
