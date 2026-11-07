import { afterEach, expect, test, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { MemoryRouter, useLocation, useNavigate } from 'react-router'
import App from '../App'

const recipe = { id: 1, name: 'Negroni', author: 'João', image_url: null, star_count: 3 }
function mount(entry = '/', scenario: 'success' | 'empty' | 'error' = 'success') {
  const fetcher = vi.fn(async (input: RequestInfo | URL) => {
    const url = String(input)
    if (scenario === 'error') return new Response('', { status: 500 })
    if (scenario === 'empty') return new Response(JSON.stringify({ data: [], metadata: { total_count: 0, next_page: null } }))
    const body = url.includes('ingredients.json') ? { data: [{ id: 1, name: 'Gin' }, { id: 2, name: 'Ice' }] }
      : url.includes('utensils.json') ? { data: [{ id: 3, name: 'Shaker' }] }
      : { data: [{ ...recipe, id: url.includes('page=2') ? 2 : 1 }], metadata: { total_count: 2, next_page: url.includes('page=2') ? null : 2 } }
    return new Response(JSON.stringify(body))
  })
  vi.stubGlobal('fetch', fetcher)
  function Location() {
    const location = useLocation()
    const navigate = useNavigate()
    return <><output aria-label="URL">{location.search}</output><button onClick={() => navigate(-1)}>Back</button></>
  }
  render(<QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
    <MemoryRouter initialEntries={[entry]}><App /><Location /></MemoryRouter>
  </QueryClientProvider>)
  return fetcher
}
afterEach(() => vi.unstubAllGlobals())

test('restores Rails filters from a URL and requests the matching API page', async () => {
  const fetcher = mount('/?q=Negroni&ingredient_ids[]=1&ingredient_mode=only&utensil_ids[]=3')
  expect(await screen.findByRole('link', { name: 'Negroni' })).toHaveAttribute('href', 'http://localhost:3000/recipes/1')
  expect(screen.getByRole('searchbox', { name: 'Search recipes' })).toHaveValue('Negroni')
  const url = new URL(String(fetcher.mock.calls.find(([path]) => String(path).includes('recipes.json'))?.[0]), 'http://localhost')
  expect(url.searchParams.getAll('ingredient_ids[]')).toEqual(['1'])
  expect(url.searchParams.get('ingredient_mode')).toBe('only')
  expect(url.searchParams.getAll('utensil_ids[]')).toEqual(['3'])
})

test('selects items, changes match modes, searches options, removes chips and navigates back', async () => {
  const user = userEvent.setup()
  mount()
  await screen.findByRole('link', { name: 'Negroni' })
  await user.click(screen.getByText('Ingredients · Add ingredients'))
  await user.click(screen.getByRole('checkbox', { name: 'Gin' }))
  await user.click(screen.getAllByRole('radio', { name: 'Use only what I have' })[0])
  expect(screen.getByLabelText('URL').textContent).toContain('ingredient_mode=only')
  await user.type(screen.getByRole('searchbox', { name: 'Find ingredients' }), 'ice')
  expect(screen.queryByRole('checkbox', { name: 'Gin' })).not.toBeInTheDocument()
  expect(screen.getByRole('checkbox', { name: 'Ice' })).toBeInTheDocument()
  await user.click(screen.getByRole('button', { name: 'Remove Gin' }))
  expect(screen.getByLabelText('URL').textContent).not.toContain('ingredient_ids')
  await user.click(screen.getByRole('button', { name: 'Back' }))
  expect(await screen.findByRole('button', { name: 'Remove Gin' })).toBeInTheDocument()
  await user.click(screen.getByRole('button', { name: 'Clear all' }))
  expect(screen.getByLabelText('URL').textContent).toBe('')
})

test('loads the next page without losing filters or the first page', async () => {
  const user = userEvent.setup()
  const fetcher = mount('/?q=gin')
  await user.click(await screen.findByRole('button', { name: 'Load more recipes' }))
  await waitFor(() => expect(screen.getAllByRole('link', { name: 'Negroni' })).toHaveLength(2))
  expect(fetcher.mock.calls.some(([url]) => String(url).includes('q=gin') && String(url).includes('page=2'))).toBe(true)
  expect(screen.queryByRole('button', { name: 'Load more recipes' })).not.toBeInTheDocument()
})

test('shows an empty state', async () => {
  mount('/', 'empty')
  expect(await screen.findByText('No recipes found.')).toBeInTheDocument()
})

test('reports API failures and lets the user retry', async () => {
  const user = userEvent.setup()
  const fetcher = mount('/', 'error')
  expect(await screen.findByRole('button', { name: 'Retry recipes' })).toBeInTheDocument()
  fetcher.mockImplementation(async () => new Response(JSON.stringify({ data: [recipe], metadata: { total_count: 1, next_page: null } })))
  await user.click(screen.getByRole('button', { name: 'Retry recipes' }))
  expect(await screen.findByRole('link', { name: 'Negroni' })).toBeInTheDocument()
})


test('searches by name and resets loaded pages after a filter change', async () => {
  const user = userEvent.setup()
  const fetcher = mount()
  await user.click(await screen.findByRole('button', { name: 'Load more recipes' }))
  await waitFor(() => expect(screen.getAllByRole('link', { name: 'Negroni' })).toHaveLength(2))
  await user.type(screen.getByRole('searchbox', { name: 'Search recipes' }), 'sour')
  await waitFor(() => expect(fetcher.mock.calls.some(([url]) => String(url).includes('q=sour') && String(url).includes('page=1'))).toBe(true))
  await waitFor(() => expect(screen.getAllByRole('link', { name: 'Negroni' })).toHaveLength(1))
})
