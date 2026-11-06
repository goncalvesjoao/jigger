import { test } from "node:test"
import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"

const source = (await readFile(new URL("../../app/javascript/controllers/marketplace_search_controller.js", import.meta.url), "utf8"))
  .replace('import { Controller } from "@hotwired/stimulus"', "class Controller {}")
const { default: MarketplaceSearch } = await import(`data:text/javascript,${encodeURIComponent(source)}`)

test("picker subtitle follows selection and mode changes independently", () => {
  const controller = new MarketplaceSearch()
  const fields = { ingredient_mode: { value: "include" }, utensil_mode: { value: "only" } }
  const pickers = ["Ingredients", "Utensils"].map((label, index) => {
    const nodes = {
      strong: { textContent: label },
      "[data-picker-clear]": {},
      "[data-picker-count]": {},
      "[data-picker-selection-count]": {},
      "[data-mode-hint]": {}
    }
    return {
      dataset: { modeKey: index ? "utensil_mode" : "ingredient_mode" },
      count: 0,
      querySelector: selector => nodes[selector],
      querySelectorAll(selector) { return selector === "[data-mode]" ? [] : Array(this.count) }
    }
  })
  Object.assign(controller, {
    element: { elements: fields }, pickerTargets: pickers, choiceTargets: [],
    chipsTarget: { replaceChildren() {} }, apply() {}
  })
  controller.selections()
  assert.equal(pickers[0].querySelector("[data-picker-count]").textContent, "Add ingredients")
  assert.equal(pickers[1].querySelector("[data-picker-count]").textContent, "Add utensils")
  pickers.forEach(picker => { picker.count = 3 })
  controller.selections()
  assert.equal(pickers[0].querySelector("[data-picker-count]").textContent, "3 selected")
  assert.equal(pickers[1].querySelector("[data-picker-count]").textContent, "3 available · Only these")
  controller.changeMode({ currentTarget: { closest: () => pickers[0], dataset: { mode: "only" } } })
  assert.equal(pickers[0].querySelector("[data-picker-count]").textContent, "3 available · Only these")
  pickers[0].count = 0
  controller.changeSelections()
  assert.equal(pickers[0].querySelector("[data-picker-count]").textContent, "Add ingredients")
  assert.equal(pickers[1].querySelector("[data-picker-count]").textContent, "3 available · Only these")
})
