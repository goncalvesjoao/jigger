import type { Recipe } from "./api";
export interface QueueItem {
  id: number;
  name: string;
  steps: string[];
  ingredients: string[];
  tools: string[];
  step: number;
  done: boolean;
}
export function readQueue(): QueueItem[] {
  try {
    const data: unknown = JSON.parse(
      sessionStorage.getItem("shakestir-mixing") || "[]",
    );
    return Array.isArray(data)
      ? data.filter(
          (item) =>
            item &&
            typeof item.id === "number" &&
            typeof item.name === "string" &&
            Array.isArray(item.steps) &&
            item.steps.every((step: unknown) => typeof step === "string") &&
            Array.isArray(item.ingredients) &&
            Array.isArray(item.tools) &&
            Number.isInteger(item.step) &&
            item.step >= 0 &&
            typeof item.done === "boolean",
        )
      : [];
  } catch {
    return [];
  }
}
export function addToQueue(recipe: Recipe) {
  const items = readQueue();
  if (!items.some((item) => item.id === recipe.id)) {
    items.push({
      id: recipe.id,
      name: recipe.name,
      steps: recipe.recipe_steps.map((s) => s.body),
      ingredients: recipe.recipe_ingredients.map((i) => i.submitted_text),
      tools: recipe.recipe_utensils.map((t) => t.submitted_text),
      step: 0,
      done: false,
    });
    sessionStorage.setItem("shakestir-mixing", JSON.stringify(items));
  }
  window.dispatchEvent(new Event("queue-change"));
}

export function clearQueue() {
  sessionStorage.removeItem("shakestir-mixing");
  window.dispatchEvent(new Event("queue-change"));
}
