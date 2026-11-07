import { useEffect, useState } from 'react'
import { useInfiniteQuery, useQuery } from '@tanstack/react-query'
import { useSearchParams } from 'react-router'
import { getJson, railsBase, type OptionsResponse, type RecipePage } from '../api'
import { FilterPicker } from './FilterPicker'
import { readFilters, writeFilters, type Filters } from './filters'

function useDebouncedSearch(value: string) {
  const [search, setSearch] = useState(value)
  useEffect(() => {
    const timer = window.setTimeout(() => setSearch(value), 300)
    return () => window.clearTimeout(timer)
  }, [value])
  return search
}

export function MarketplacePage() {
  const [params, setParams] = useSearchParams()
  const filters = readFilters(params)
  const search = useDebouncedSearch(filters.q)
  const queryFilters = { ...filters, q: search }
  const searchPending = search !== filters.q
  const update = (patch: Partial<Filters>, replace = false) => setParams(writeFilters({ ...filters, ...patch }), { replace })
  const ingredients = useQuery({ queryKey: ['ingredients'], queryFn: ({ signal }) => getJson<OptionsResponse>('/ingredients.json', signal), staleTime: 300_000 })
  const utensils = useQuery({ queryKey: ['utensils'], queryFn: ({ signal }) => getJson<OptionsResponse>('/utensils.json', signal), staleTime: 300_000 })
  const recipes = useInfiniteQuery({
    queryKey: ['marketplace', queryFilters], initialPageParam: 1,
    queryFn: ({ signal, pageParam }) => {
      const query = writeFilters(queryFilters)
      query.set('page', String(pageParam))
      return getJson<RecipePage>(`/recipes.json?${query}`, signal)
    },
    getNextPageParam: page => page.metadata.next_page ?? undefined,
  })
  const items = recipes.data?.pages.flatMap(page => page.data) || []
  return <main>
    <header><a href="/">ShakeStir</a><h1>Find your next drink</h1><p>Search by name, or choose the ingredients and utensils you have.</p></header>
    <form role="search" aria-label="Find recipes" onSubmit={event => event.preventDefault()}>
      <label>Search recipes<input type="search" placeholder="Try Negroni, sour, highball…" value={filters.q} onChange={event => update({ q: event.target.value }, true)} /></label>
      <div className="filters">{(['ingredient', 'utensil'] as const).map(kind => {
        const query = kind === 'ingredient' ? ingredients : utensils
        return <FilterPicker key={kind} label={kind === 'ingredient' ? 'Ingredients' : 'Utensils'} options={query.data?.data || []}
          selected={filters[`${kind}Ids`]} mode={filters[`${kind}Mode`]} loading={query.isPending} error={query.isError} retry={() => { void query.refetch() }}
          onChange={(ids, mode) => update({ [`${kind}Ids`]: ids, [`${kind}Mode`]: mode })} />
      })}</div>
      <div aria-label="Selected filters">{(['ingredient', 'utensil'] as const).flatMap(kind => {
        const options = (kind === 'ingredient' ? ingredients : utensils).data?.data || []
        return filters[`${kind}Ids`].map(id => <button key={`${kind}-${id}`} type="button" aria-label={`Remove ${options.find(item => String(item.id) === id)?.name || id}`} onClick={() => update({ [`${kind}Ids`]: filters[`${kind}Ids`].filter(value => value !== id) })}>{options.find(item => String(item.id) === id)?.name || id} ×</button>)
      })}</div>
      <button type="button" onClick={() => setParams({})}>Clear all</button>
    </form>
    <section aria-label="Recipes" aria-busy={recipes.isFetching || searchPending}>
      <div role="status">{searchPending ? 'Searching…' : recipes.isPending ? 'Loading recipes…' : recipes.data ? `${recipes.data.pages[0].metadata.total_count} recipes found` : ''}</div>
      {recipes.isError && <p role="alert">Could not load recipes. {recipes.error.message} <button onClick={() => { void recipes.refetch() }}>Retry recipes</button></p>}
      {recipes.isSuccess && !items.length && <div><h2>No recipes found.</h2><p>Try another name or remove a filter to see more drinks.</p><button onClick={() => setParams({})}>All recipes</button></div>}
      <div className="recipe-grid">{items.map(recipe => <article key={recipe.id}>
        {recipe.image_url && <img src={recipe.image_url} alt="" loading="lazy" />}
        <h2><a href={`${railsBase}/recipes/${recipe.id}`}>{recipe.name || 'Untitled recipe'}</a></h2>
        <p>By {recipe.author}</p><p>{recipe.star_count} stars</p>
      </article>)}</div>
      {recipes.hasNextPage && <button disabled={recipes.isFetching || searchPending} onClick={() => { void recipes.fetchNextPage() }}>{recipes.isFetchingNextPage ? 'Loading more…' : 'Load more recipes'}</button>}
    </section>
  </main>
}
