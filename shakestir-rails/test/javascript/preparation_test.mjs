import { test } from "node:test"
import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"

// Exercise the actual controller methods without a browser or a new test dependency.
const source = (await readFile(new URL("../../app/javascript/controllers/preparation_controller.js", import.meta.url), "utf8"))
  .replace('import { Controller } from "@hotwired/stimulus"', "class Controller {}")
const { default: Preparation } = await import(`data:text/javascript,${encodeURIComponent(source)}`)

test("preparation tracks check, uncheck, completion and reset", () => {
  const controller = new Preparation()
  Object.assign(controller, {
    hasStatusTarget: true,
    statusTarget: { hidden: true },
    summaryTarget: {}, progressTarget: {},
    stepTargets: [{ checked: false }, { checked: false }]
  })
  controller.connect()
  assert.equal(controller.statusTarget.hidden, false)
  assert.equal(controller.summaryTarget.textContent, "0 of 2 steps complete")
  controller.stepTargets[0].checked = true
  controller.update()
  assert.equal(controller.progressTarget.value, 1)
  controller.stepTargets[1].checked = true
  controller.update()
  assert.equal(controller.summaryTarget.textContent, "All steps complete. Enjoy your cocktail.")
  controller.stepTargets[0].checked = false
  controller.update()
  assert.equal(controller.summaryTarget.textContent, "1 of 2 steps complete")
  controller.reset()
  assert.equal(controller.progressTarget.value, 0)
  assert.ok(controller.stepTargets.every(step => !step.checked))
})

test("empty preparation connects without progress controls", () => {
  const controller = new Preparation()
  controller.hasStatusTarget = false
  assert.doesNotThrow(() => controller.connect())
})
