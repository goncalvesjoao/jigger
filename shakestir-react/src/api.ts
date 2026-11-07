const apiBase = (import.meta.env.VITE_API_BASE_URL || '/api').replace(/\/$/, '')
export const railsBase = (import.meta.env.VITE_BACKEND_URL || 'http://localhost:3000').replace(/\/$/, '')

export async function getJson<T>(path: string, signal?: AbortSignal): Promise<T> {
  const response = await fetch(`${apiBase}${path}`, {
    headers: { Accept: 'application/json' }, credentials: 'include', signal,
  })
  if (!response.ok) throw new Error(`Request failed (${response.status}). Please try again.`)
  return response.json() as Promise<T>
}

export interface Option { id: number; name: string }
export interface Recipe {
  id: number; name: string; author: string; image_url: string | null; star_count: number
}
export interface RecipePage {
  data: Recipe[]
  metadata: { current_page: number; next_page: number | null; total_count: number }
}
export interface OptionsResponse { data: Option[] }
