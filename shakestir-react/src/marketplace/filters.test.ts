import { expect, test } from 'vitest'
import { readFilters, writeFilters } from './filters'
test('supports legacy makeable links and explicit mode overrides', () => {
  const filters = readFilters(new URLSearchParams('makeable=1&ingredient_ids[]=2&ingredient_ids[]=2&ingredient_ids[]=&utensil_mode=include'))
  expect(filters.ingredientIds).toEqual(['2'])
  expect(filters.ingredientMode).toBe('only')
  expect(filters.utensilMode).toBe('include')
  expect(readFilters(writeFilters(filters))).toEqual(filters)
})
