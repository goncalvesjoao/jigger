import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "button", "count", "status"]
  static values = { recipeId: Number, recipeName: String }

  async toggle(event) {
    event.preventDefault()
    if (this.saving) return
    this.saving = true
    this.buttonTarget.disabled = true
    this.statusTarget.classList.add("visually-hidden")
    this.statusTarget.textContent = "Saving star…"
    try {
      const response = await fetch(this.formTarget.action, {
        method: this.buttonTarget.getAttribute("aria-pressed") === "true" ? "DELETE" : "POST",
        headers: { Accept: "application/json", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
      })
      if (!response.ok || !response.headers.get("content-type")?.includes("application/json")) {
        throw new Error("Could not save your star. Please try again or sign in again.")
      }
      const state = await response.json()
      window.dispatchEvent(new CustomEvent("recipe-star:changed", { detail: state }))
      this.statusTarget.textContent = state.starred ? "Recipe starred in your Favorites." : "Recipe unstarred."
    } catch (error) {
      this.statusTarget.classList.remove("visually-hidden")
      this.statusTarget.textContent = error.message
    } finally {
      this.buttonTarget.disabled = false
      this.saving = false
    }
  }

  sync(event) {
    const state = event.detail
    if (state.recipe_id !== this.recipeIdValue || !this.hasButtonTarget) return
    const action = state.starred ? "Unstar" : "Star"
    this.buttonTarget.setAttribute("aria-pressed", String(state.starred))
    this.buttonTarget.setAttribute("aria-label", `${action} ${this.recipeNameValue}, ${state.star_count} ${state.star_count === 1 ? "star" : "stars"}`)
    this.buttonTarget.title = state.starred ? "Unstar recipe" : "Star recipe in your private Favorites"
    this.countTarget.textContent = state.star_count
    const override = this.formTarget.querySelector('input[name="_method"]')
    if (override) override.remove()
    if (state.starred) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "_method"
      input.value = "delete"
      this.formTarget.append(input)
    }
  }
}
