import { test } from "node:test"
import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"

const source = (await readFile(new URL("../../app/javascript/controllers/recipe_star_controller.js", import.meta.url), "utf8"))
  .replace('import { Controller } from "@hotwired/stimulus"', "class Controller {}")
const { default: RecipeStar } = await import(`data:text/javascript,${encodeURIComponent(source)}`)

function control() {
  const attributes = { "aria-pressed": "false" }
  let override = null
  const controller = new RecipeStar()
  Object.assign(controller, {
    recipeIdValue: 7, recipeNameValue: "Negroni", hasButtonTarget: true,
    buttonTarget: { disabled: false, getAttribute: name => attributes[name], setAttribute: (name, value) => { attributes[name] = value } },
    formTarget: { action: "/recipes/7/star", querySelector: () => override, append: node => { override = node } },
    countTarget: { textContent: "0" },
    statusTarget: { classList: { add() {}, remove() {} } }
  })
  return { controller, attributes }
}

function browser(controller) {
  globalThis.document = {
    querySelector: () => ({ content: "csrf" }),
    createElement: () => ({ remove() {} })
  }
  globalThis.CustomEvent = class { constructor(type, options) { this.type = type; this.detail = options.detail } }
  globalThis.window = { dispatchEvent: event => controller.sync(event) }
}

test("star toggles use server state and restore the button after saving", async () => {
  const { controller, attributes } = control()
  browser(controller)
  const methods = []
  globalThis.fetch = async (_url, options) => {
    methods.push(options.method)
    return { ok: true, headers: { get: () => "application/json" }, json: async () => ({ recipe_id: 7, starred: options.method === "POST", star_count: options.method === "POST" ? 1 : 0 }) }
  }
  const event = { preventDefault() {} }
  await controller.toggle(event)
  assert.equal(attributes["aria-pressed"], "true")
  assert.equal(controller.countTarget.textContent, 1)
  assert.equal(controller.buttonTarget.disabled, false)
  await controller.toggle(event)
  assert.deepEqual(methods, ["POST", "DELETE"])
  assert.equal(attributes["aria-pressed"], "false")
  assert.equal(controller.countTarget.textContent, 0)
})

test("failed requests leave counts unchanged and provide a retry message", async () => {
  const { controller, attributes } = control()
  browser(controller)
  globalThis.fetch = async () => ({ ok: false })
  await controller.toggle({ preventDefault() {} })
  assert.equal(attributes["aria-pressed"], "false")
  assert.equal(controller.countTarget.textContent, "0")
  assert.match(controller.statusTarget.textContent, /try again/)
  assert.equal(controller.buttonTarget.disabled, false)
})

test("Favorites events update matching recipes without changing unrelated controls", () => {
  const { controller, attributes } = control()
  browser(controller)
  controller.sync({ detail: { recipe_id: 8, starred: true, star_count: 3 } })
  assert.equal(attributes["aria-pressed"], "false")
  controller.sync({ detail: { recipe_id: 7, starred: true, star_count: 3 } })
  assert.equal(attributes["aria-pressed"], "true")
  assert.equal(controller.countTarget.textContent, 3)
  assert.equal(attributes["aria-label"], "Unstar Negroni, 3 stars")
})
