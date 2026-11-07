const apiBase = (import.meta.env.VITE_API_BASE_URL || "/api").replace(
  /\/$/,
  "",
);
export const railsBase = (
  import.meta.env.VITE_BACKEND_URL || "http://localhost:3000"
).replace(/\/$/, "");
let csrf = "";
export class ApiError extends Error {
  status: number;
  errors: Record<string, string[]>;
  constructor(status: number, errors: Record<string, string[]>) {
    super(
      Object.entries(errors)
        .map(
          ([key, values]) =>
            `${key === "base" ? "" : `${key}: `}${values.join(", ")}`,
        )
        .join("; "),
    );
    this.status = status;
    this.errors = errors;
  }
}
export async function request<T>(
  path: string,
  method = "GET",
  body?: unknown,
  signal?: AbortSignal,
): Promise<T> {
  if (method !== "GET" && !csrf) await getJson<Session>("/session.json");
  const response = await fetch(`${apiBase}${path}`, {
    method,
    credentials: "include",
    signal,
    headers: {
      Accept: "application/json",
      ...(body instanceof FormData
        ? {}
        : body
          ? { "Content-Type": "application/json" }
          : {}),
      ...(method !== "GET" ? { "X-CSRF-Token": csrf } : {}),
    },
    body:
      body instanceof FormData ? body : body ? JSON.stringify(body) : undefined,
  });
  if (response.status === 204) return undefined as T;
  const data = await response.json().catch(() => ({
    errors: {
      base: [`Request failed (${response.status}). Please try again.`],
    },
  }));
  if (!response.ok)
    throw new ApiError(
      response.status,
      data.errors || { base: [`Request failed (${response.status}).`] },
    );
  if (data.metadata?.csrf_token) csrf = data.metadata.csrf_token;
  return data as T;
}
export const getJson = <T>(path: string, signal?: AbortSignal) =>
  request<T>(path, "GET", undefined, signal);
export interface Option {
  id: number;
  name: string;
  description?: string;
  image_url?: string | null;
}
export interface Technique extends Option {
  slug: string;
  instructions: string;
  tip: string;
}
export interface IngredientLine {
  id?: number;
  ingredient_id: number;
  submitted_text: string;
  quantity?: string;
  measuring_unit?: string;
  preparation_note?: string;
  optional?: boolean;
  role?: string;
  position?: number;
  _destroy?: boolean;
}
export interface ToolLine {
  id?: number;
  utensil_id: number;
  submitted_text: string;
  role?: string;
  _destroy?: boolean;
}
export interface Recipe {
  id: number;
  name: string;
  author: string;
  image_url: string | null;
  fallback_image_url?: string | null;
  star_count: number;
  starred: boolean;
  author_profile: { id: number; handle: string; name: string };
  can_edit: boolean;
  can_delete: boolean;
  steps: string;
  servings: number;
  visibility: string;
  publication_state: string;
  source_reference: string;
  source_url: string;
  recipe_ingredients: IngredientLine[];
  recipe_utensils: ToolLine[];
  recipe_steps: { id: number; position: number; body: string }[];
  techniques: Technique[];
  cocktail: { id: number; name: string } | null;
  saved_collection_ids: number[];
  sweetness: number | null;
  sourness: number | null;
  bitterness: number | null;
  steps_editable: boolean;
}
export interface RecipePage {
  data: Recipe[];
  metadata: {
    current_page: number;
    next_page: number | null;
    total_count: number;
  };
}
export interface OptionsResponse {
  data: Option[];
}
export interface User {
  id: number;
  name: string;
  handle: string;
  display_name: string;
  bio: string;
  image_url: string | null;
  owned: boolean;
  email_address: string;
  recipes: Recipe[];
  collections: Collection[];
}
export interface Session {
  data: User | null;
  metadata: { csrf_token: string };
}
export interface Collection {
  id: number;
  name: string;
  visibility: string;
  system_key: string | null;
  owned: boolean;
  can_edit: boolean;
  can_delete: boolean;
  can_change_visibility: boolean;
  recipe_count: number;
  owner: { id: number; handle: string; name: string };
  recipes: Recipe[];
  previews: { id: number; image_url: string | null }[];
}

export function mediaUrl(url: string) {
  return url.startsWith(railsBase + "/")
    ? apiBase + url.slice(railsBase.length)
    : url;
}
