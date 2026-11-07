export type FilterKind = 'ingredient' | 'utensil'
export type MatchMode = 'include' | 'only'
export interface Filters {
  q: string
  ingredientIds: string[]
  utensilIds: string[]
  ingredientMode: MatchMode
  utensilMode: MatchMode
}
export function readFilters(params: URLSearchParams): Filters {
  const ids = (kind: FilterKind) => [...new Set(params.getAll(`${kind}_ids[]`).filter(Boolean))].sort()
  const mode = (kind: FilterKind): MatchMode => params.get(`${kind}_mode`) === 'only' ||
    (!params.has(`${kind}_mode`) && params.get('makeable') === '1') ? 'only' : 'include'
  return { q: params.get('q') || '', ingredientIds: ids('ingredient'), utensilIds: ids('utensil'),
    ingredientMode: mode('ingredient'), utensilMode: mode('utensil') }
}
export function writeFilters(filters: Filters): URLSearchParams {
  const params = new URLSearchParams()
  if (filters.q) params.set('q', filters.q)
  for (const kind of ['ingredient', 'utensil'] as const) {
    params.set(`${kind}_mode`, filters[`${kind}Mode`])
    for (const id of filters[`${kind}Ids`]) params.append(`${kind}_ids[]`, id)
  }
  return params
}
