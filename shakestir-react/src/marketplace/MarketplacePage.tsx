import { useEffect, useState } from "react";
import { useInfiniteQuery, useQuery } from "@tanstack/react-query";
import { useSearchParams } from "react-router";
import { getJson, type OptionsResponse, type RecipePage } from "../api";
import { RecipeCards } from "../ui";
import { FilterPicker } from "./FilterPicker";
import { readFilters, writeFilters, type Filters } from "./filters";

function useDebouncedSearch(value: string) {
  const [search, setSearch] = useState(value);
  useEffect(() => {
    const timer = window.setTimeout(() => setSearch(value), 300);
    return () => window.clearTimeout(timer);
  }, [value]);
  return search;
}

export function MarketplacePage() {
  const [params, setParams] = useSearchParams();
  const filters = readFilters(params);
  const search = useDebouncedSearch(filters.q);
  const queryFilters = { ...filters, q: search };
  const searchPending = search !== filters.q;
  const update = (patch: Partial<Filters>, replace = false) => {
    const next = writeFilters({ ...filters, ...patch });
    for (const taste of ["sweetness", "sourness", "bitterness"]) {
      const value = params.get(taste);
      if (value) next.set(taste, value);
    }
    setParams(next, { replace });
  };
  const ingredients = useQuery({
    queryKey: ["ingredients"],
    queryFn: ({ signal }) =>
      getJson<OptionsResponse>("/ingredients.json", signal),
    staleTime: 300_000,
  });
  const utensils = useQuery({
    queryKey: ["utensils"],
    queryFn: ({ signal }) => getJson<OptionsResponse>("/utensils.json", signal),
    staleTime: 300_000,
  });
  const recipes = useInfiniteQuery({
    queryKey: [
      "marketplace",
      queryFilters,
      params.get("sweetness"),
      params.get("sourness"),
      params.get("bitterness"),
    ],
    initialPageParam: 1,
    queryFn: ({ signal, pageParam }) => {
      const query = writeFilters(queryFilters);
      for (const taste of ["sweetness", "sourness", "bitterness"]) {
        const value = params.get(taste);
        if (value) query.set(taste, value);
      }
      query.set("page", String(pageParam));
      return getJson<RecipePage>(`/recipes.json?${query}`, signal);
    },
    getNextPageParam: (page) => page.metadata.next_page ?? undefined,
  });
  const items = recipes.data?.pages.flatMap((page) => page.data) || [];
  return (
    <main>
      <header className="discovery-hero">
        <div>
          <span className="eyebrow">Good drinks. Your way.</span>
          <h1>
            A little inspiration.
            <br />
            <i>A very good drink.</i>
          </h1>
          <p>
            Find your next pour, with what’s on your bar.
            <br />
            Recipes from people who love making them.
          </p>
          <a className="button primary" href="#find-recipes">
            Find your drink ↓
          </a>
        </div>
        <div
          className="hero-photo"
          role="img"
          aria-label="Cocktails, citrus and bar tools"
        />
        <span className="hero-note">Shake. Stir. Make it yours.</span>
      </header>
      <form
        id="find-recipes"
        className="discovery-search panel"
        role="search"
        aria-label="Find recipes"
        onSubmit={(event) => event.preventDefault()}
      >
        <label>
          Search recipes
          <input
            type="search"
            placeholder="Try Negroni, sour, highball…"
            value={filters.q}
            onChange={(event) => update({ q: event.target.value }, true)}
          />
        </label>
        <div className="filters">
          {(["ingredient", "utensil"] as const).map((kind) => {
            const query = kind === "ingredient" ? ingredients : utensils;
            return (
              <FilterPicker
                key={kind}
                label={kind === "ingredient" ? "Ingredients" : "Utensils"}
                options={query.data?.data || []}
                selected={filters[`${kind}Ids`]}
                mode={filters[`${kind}Mode`]}
                loading={query.isPending}
                error={query.isError}
                retry={() => {
                  void query.refetch();
                }}
                onChange={(ids, mode) =>
                  update({ [`${kind}Ids`]: ids, [`${kind}Mode`]: mode })
                }
              />
            );
          })}
        </div>
        <div aria-label="Selected filters">
          {(["ingredient", "utensil"] as const).flatMap((kind) => {
            const options =
              (kind === "ingredient" ? ingredients : utensils).data?.data || [];
            return filters[`${kind}Ids`].map((id) => (
              <button
                key={`${kind}-${id}`}
                type="button"
                aria-label={`Remove ${options.find((item) => String(item.id) === id)?.name || id}`}
                onClick={() =>
                  update({
                    [`${kind}Ids`]: filters[`${kind}Ids`].filter(
                      (value) => value !== id,
                    ),
                  })
                }
              >
                {options.find((item) => String(item.id) === id)?.name || id} ×
              </button>
            ));
          })}
        </div>
        <details className="taste-filter">
          <summary>
            Explore by taste{" "}
            <span className="muted">Author-supplied notes</span>
          </summary>
          <div className="taste-grid">
            {["sweetness", "sourness", "bitterness"].map((taste) => (
              <label key={taste}>
                {taste}
                <select
                  value={params.get(taste) || ""}
                  onChange={(e) => {
                    const next = new URLSearchParams(params);
                    if (e.target.value) {
                      next.set(taste, e.target.value);
                    } else {
                      next.delete(taste);
                    }
                    setParams(next);
                  }}
                >
                  <option value="">Any intensity</option>
                  <option value="unknown">Not assessed</option>
                  {[0, 1, 2, 3, 4, 5].map((n) => (
                    <option key={n} value={n}>
                      {n} —{" "}
                      {
                        [
                          "None",
                          "Very low",
                          "Low",
                          "Moderate",
                          "High",
                          "Very high",
                        ][n]
                      }
                    </option>
                  ))}
                </select>
              </label>
            ))}
          </div>
          <p>
            Intensity from 0 to 5, supplied by each author. Unassessed recipes
            have no inferred scores.
          </p>
        </details>
        <button type="button" onClick={() => setParams({})}>
          Clear all
        </button>
      </form>
      <section
        aria-label="Recipes"
        aria-busy={recipes.isFetching || searchPending}
      >
        <div role="status">
          {searchPending
            ? "Searching…"
            : recipes.isPending
              ? "Loading recipes…"
              : recipes.data
                ? `${recipes.data.pages[0].metadata.total_count} recipes found`
                : ""}
        </div>
        {recipes.isError && (
          <p role="alert">
            Could not load recipes. {recipes.error.message}{" "}
            <button
              onClick={() => {
                void recipes.refetch();
              }}
            >
              Retry recipes
            </button>
          </p>
        )}
        {recipes.isSuccess && !items.length && (
          <div>
            <h2>No recipes found.</h2>
            <p>Try another name or remove a filter to see more drinks.</p>
            <button onClick={() => setParams({})}>All recipes</button>
          </div>
        )}
        <RecipeCards recipes={items} />
        {recipes.hasNextPage && (
          <button
            disabled={recipes.isFetching || searchPending}
            onClick={() => {
              void recipes.fetchNextPage();
            }}
          >
            {recipes.isFetchingNextPage ? "Loading more…" : "Load more recipes"}
          </button>
        )}
      </section>
    </main>
  );
}
