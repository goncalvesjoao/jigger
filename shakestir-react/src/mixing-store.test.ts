import { beforeEach, expect, test } from "vitest";
import { addToQueue, readQueue } from "./mixing-store";
import type { Recipe } from "./api";
beforeEach(() => sessionStorage.clear());
test("session queue preserves exact preparation and deduplicates recipe identity", () => {
  const r = {
    id: 7,
    name: "My sour",
    recipe_steps: [
      { body: "Shake. Do not translate." },
      { body: "Strain slowly." },
    ],
    recipe_ingredients: [{ submitted_text: "45 ml gin" }],
    recipe_utensils: [{ submitted_text: "Shaker" }],
  } as Recipe;
  addToQueue(r);
  addToQueue(r);
  expect(readQueue()).toEqual([
    {
      id: 7,
      name: "My sour",
      steps: ["Shake. Do not translate.", "Strain slowly."],
      ingredients: ["45 ml gin"],
      tools: ["Shaker"],
      step: 0,
      done: false,
    },
  ]);
  expect(localStorage.getItem("shakestir-mixing")).toBeNull();
});
test("invalid stored JSON recovers to an empty queue", () => {
  sessionStorage.setItem("shakestir-mixing", "invalid");
  expect(readQueue()).toEqual([]);
});
