# ShakeStir React

React + TypeScript marketplace using React Router, TanStack Query, and Vitest.

## Development

Run the Rails application from `../shakestir-rails` on port 3000 (`bin/rails server`), then run:

```sh
npm install
npm run dev
```

Vite proxies `/api/*` to `http://localhost:3000/*`. The marketplace at `/` uses the existing `/recipes.json`, `/ingredients.json`, and `/utensils.json` endpoints. Rails remains responsible for matching filters, optional ingredient handling, visibility, ordering, and pagination.

Search, ingredient selections, utensil selections, and each picker’s include/only mode live in URL search parameters and support browser history. Legacy `makeable=1` links are also supported. More results load with an explicit button. Recipe links open the Rails recipe page; other React pages and authenticated actions are outside this first page’s scope.

## Configuration

Optional Vite environment variables:

- `VITE_API_BASE_URL`: API prefix (default `/api`).
- `VITE_BACKEND_URL`: Rails origin for recipe detail links (default `http://localhost:3000`).

For production, configure a same-origin reverse proxy for `/api/*` (removing `/api` before forwarding), and set `VITE_BACKEND_URL` to the deployed Rails origin at build time. Using a separate API origin instead requires Rails CORS and cookie configuration. Vite’s development proxy does not apply to production or `vite preview`.

## Checks

```sh
npm test
npm run test:watch
npm run lint
npm run build
```

Vitest and Testing Library cover filter URL serialization, selection and removal, match modes, browser history, pagination, empty results, and failure/retry behavior. Tests mock the HTTP boundary; they require no running Rails server.

Styling is deliberately minimal so a later design pass can replace it.
