import { useSession } from "./session";
import {
  useEffect,
  useRef,
  useState,
  type FormEvent,
  type ReactNode,
} from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Link, useNavigate, useParams, useSearchParams } from "react-router";
import {
  ApiError,
  getJson,
  mediaUrl,
  request,
  type Recipe,
  type RecipePage,
  type Collection,
  type User,
  type Technique,
  type Option,
  type IngredientLine,
  type ToolLine,
} from "./api";
import {
  Heading,
  Loading,
  Failure,
  Empty,
  Photo,
  Star,
  RecipeCards,
} from "./ui";
import { addToQueue, clearQueue } from "./mixing-store";
function useResource<T>(path: string) {
  return useQuery({
    queryKey: [path],
    queryFn: ({ signal }) => getJson<T>(path, signal),
    retry: false,
  });
}
function Resource<T>({
  path,
  children,
}: {
  path: string;
  children: (data: T) => ReactNode;
}) {
  const q = useResource<T>(path);
  return q.isPending ? (
    <Loading />
  ) : q.error ? (
    <Failure error={q.error} retry={() => void q.refetch()} />
  ) : (
    children(q.data)
  );
}
export function Catalog({
  kind,
}: {
  kind: "ingredients" | "utensils" | "techniques" | "cocktails";
}) {
  const [params, setParams] = useSearchParams();
  const search = params.get("q") || "";
  return (
    <main>
      <Heading
        eyebrow="Build your bar knowledge"
        title={
          {
            ingredients: "Every good ingredient.",
            utensils: "Tools of the trade.",
            techniques: "A little technique goes a long way.",
            cocktails: "The classics, and their stories.",
          }[kind]
        }
      />
      <label className="search-label">
        Search {kind}
        <input
          type="search"
          value={search}
          onChange={(e) => setParams({ q: e.target.value })}
        />
      </label>
      <Resource<{
        data: (Option & { slug?: string })[];
        metadata?: { next_page: number | null };
      }>
        path={`/${kind}.json?${params}`}
      >
        {(data) => (
          <>
            <div className="catalog-grid">
              {data.data
                .filter(
                  (i) =>
                    kind === "cocktails" ||
                    i.name.toLowerCase().includes(search.toLowerCase()),
                )
                .map((item) => (
                  <article className="panel" key={item.id}>
                    {item.image_url && (
                      <Photo src={item.image_url} name={item.name} />
                    )}
                    <h2>
                      {kind === "techniques" || kind === "cocktails" ? (
                        <Link to={`/${kind}/${item.slug || item.id}`}>
                          {item.name}
                        </Link>
                      ) : (
                        item.name
                      )}
                    </h2>
                    <p>{item.description}</p>
                    {kind === "ingredients" || kind === "utensils" ? (
                      <Link
                        to={`/?${kind === "ingredients" ? "ingredient" : "utensil"}_ids[]=${item.id}`}
                      >
                        Find recipes with this{" "}
                        {kind === "ingredients" ? "ingredient" : "tool"} →
                      </Link>
                    ) : null}
                  </article>
                ))}
            </div>
            {!data.data.length && <Empty>No entries found.</Empty>}
            {data.metadata?.next_page && (
              <button
                onClick={() =>
                  setParams({
                    q: search,
                    page: String(data.metadata?.next_page),
                  })
                }
              >
                Next page
              </button>
            )}
          </>
        )}
      </Resource>
    </main>
  );
}
export function TechniquePage() {
  const { id } = useParams();
  return (
    <main className="reading">
      <Resource<Technique> path={`/techniques/${id}.json`}>
        {(t) => (
          <>
            <Heading eyebrow="Technique guide" title={t.name} />
            <p className="lead">{t.description}</p>
            <h2>How to do it</h2>
            <p className="prose">{t.instructions}</p>
            {t.tip && (
              <aside className="panel">
                <h2>A useful tip</h2>
                <p>{t.tip}</p>
              </aside>
            )}
            <Link to="/techniques">All techniques</Link>
          </>
        )}
      </Resource>
    </main>
  );
}
export function CocktailPage() {
  const { id } = useParams();
  const [params] = useSearchParams();
  return (
    <main>
      <Resource<{
        name: string;
        description: string;
        history: string;
        image_url: string;
        recipes: Recipe[];
        filters_applied: boolean;
        other_recipes?: Recipe[];
        source_reference: string;
        source_url: string;
        source_published_on: string | null;
        source_date_note: string | null;
      }>
        path={`/cocktails/${id}.json?${params}`}
      >
        {(c) => (
          <>
            <div className="detail-hero">
              <Heading eyebrow="The canonical cocktail" title={c.name}>
                <p>{c.description}</p>
              </Heading>
              <Photo src={c.image_url} name={c.name} />
            </div>
            <section className="reading">
              <h2>The story</h2>
              <p className="prose">
                {c.history || "No history has been supplied for this cocktail."}
              </p>
              {c.source_published_on && (
                <p>Historical source publication: {c.source_published_on}</p>
              )}
              {c.source_date_note && (
                <p className="prose">{c.source_date_note}</p>
              )}
              {(c.source_reference || c.source_url) && (
                <p>
                  Source: {c.source_reference}{" "}
                  {c.source_url && <a href={c.source_url}>Original source ↗</a>}
                </p>
              )}
            </section>
            <h2>Ways to make it</h2>
            {c.filters_applied && (
              <p>
                Showing recipes matching the filters in this link.{" "}
                <Link to={`/cocktails/${id}`}>Show all recipes</Link>
              </p>
            )}
            <RecipeCards recipes={c.recipes} />
            {!c.recipes.length && (
              <Empty>No recipes match these filters.</Empty>
            )}
            {!!c.other_recipes?.length && (
              <details>
                <summary>
                  Other public recipes ({c.other_recipes.length})
                </summary>
                <RecipeCards recipes={c.other_recipes} />
              </details>
            )}
          </>
        )}
      </Resource>
    </main>
  );
}
export function RecipeDetail() {
  const { id } = useParams();
  return (
    <main>
      <Resource<Recipe> path={`/recipes/${id}.json`}>
        {(r) => <RecipeContent recipe={r} />}
      </Resource>
    </main>
  );
}
function RecipeContent({ recipe: r }: { recipe: Recipe }) {
  const client = useQueryClient();
  const navigate = useNavigate();
  const session = useSession();
  const [message, setMessage] = useState("");
  const [gathered, setGathered] = useState<number[]>([]);
  const [completed, setCompleted] = useState<number[]>([]);
  const [guide, setGuide] = useState<Technique | null>(null);
  const collections = useQuery({
    queryKey: ["save-collections"],
    queryFn: () => getJson<{ data: Collection[] }>("/my/collections.json"),
    enabled: !!session.data?.data,
  });
  const [collectionId, setCollectionId] = useState("");
  const [busy, setBusy] = useState(false);
  async function remove() {
    if (!confirm(`Permanently delete ${r.name}?`)) return;
    setBusy(true);
    try {
      await request(`/recipes/${r.id}.json`, "DELETE");
      await client.invalidateQueries();
      navigate("/my/recipes");
    } catch (e) {
      setMessage((e as Error).message);
    } finally {
      setBusy(false);
    }
  }
  return (
    <>
      <div className="detail-hero">
        <Heading eyebrow="A recipe worth making" title={r.name}>
          <Link className="author" to={`/profiles/${r.author_profile.id}`}>
            {r.author} / {r.name}
          </Link>
          <p>
            {r.servings || 1} serving{r.servings > 1 ? "s" : ""} ·{" "}
            {r.publication_state} · {r.visibility}
          </p>
          <div className="actions">
            <button
              className="primary"
              onClick={() => {
                addToQueue(r);
                setMessage("Added to your mixing queue.");
              }}
            >
              Make this drink
            </button>
            <Star recipe={r} />
            {r.can_edit && (
              <Link className="button" to={`/recipes/${r.id}/edit`}>
                Edit recipe
              </Link>
            )}
          </div>
          <p role="status">{message}</p>
        </Heading>
        <Photo
          src={r.image_url}
          fallbackSrc={r.fallback_image_url}
          name={r.name}
        />
      </div>
      <div className="recipe-layout">
        <aside>
          <section className="panel">
            <h2>Ingredients</h2>
            {r.recipe_ingredients.length ? (
              <ul className="requirements">
                {r.recipe_ingredients.map((i) => (
                  <li key={i.id}>
                    <label className="check">
                      <input
                        type="checkbox"
                        aria-label={`Gather ${i.submitted_text}`}
                        checked={gathered.includes(i.id || 0)}
                        onChange={(e) =>
                          setGathered(
                            e.target.checked
                              ? [...gathered, i.id || 0]
                              : gathered.filter((id) => id !== i.id),
                          )
                        }
                      />
                      <span>
                        {i.quantity && (
                          <strong>
                            {Number(i.quantity)} {i.measuring_unit}{" "}
                          </strong>
                        )}
                        <Link to={`/?ingredient_ids[]=${i.ingredient_id}`}>
                          {i.submitted_text}
                        </Link>
                      </span>
                    </label>
                    {i.role && i.role !== "mixing" && <small>{i.role}</small>}
                    {i.optional && <small>Optional</small>}
                    {i.preparation_note && <small>{i.preparation_note}</small>}
                  </li>
                ))}
              </ul>
            ) : (
              <p>No ingredients supplied.</p>
            )}
            {gathered.length > 0 && (
              <button onClick={() => setGathered([])}>
                Reset ingredients ({gathered.length} gathered)
              </button>
            )}
            <h2>Tools</h2>
            <ul className="requirements">
              {r.recipe_utensils.map((t) => (
                <li key={t.id}>
                  <Link to={`/?utensil_ids[]=${t.utensil_id}`}>
                    {t.submitted_text}
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        </aside>
        <section>
          <h2>Preparation</h2>
          <ol className="steps">
            {r.recipe_steps.map((s) => (
              <li key={s.id}>
                <label className="check preparation-check">
                  <input
                    type="checkbox"
                    aria-label={`Complete step ${s.position + 1}`}
                    checked={completed.includes(s.id)}
                    onChange={(e) =>
                      setCompleted(
                        e.target.checked
                          ? [...completed, s.id]
                          : completed.filter((id) => id !== s.id),
                      )
                    }
                  />
                  <span className="prose">{s.body}</span>
                </label>
              </li>
            ))}
          </ol>
          {completed.length > 0 && (
            <button onClick={() => setCompleted([])}>
              Reset steps ({completed.length} complete)
            </button>
          )}
          <h2>Techniques</h2>
          <div className="actions">
            {r.techniques.map((t) => (
              <button key={t.id} onClick={() => setGuide(t)}>
                {t.name} ↗
              </button>
            ))}
            {!r.techniques.length && <p>No techniques linked.</p>}
          </div>
          <section className="panel">
            <h2>Taste, in the author’s words</h2>
            <p>Author-supplied intensity: 0 (none) to 5 (very high).</p>
            <div className="taste-grid">
              {(["sweetness", "sourness", "bitterness"] as const).map((t) => (
                <div key={t}>
                  <strong>{t}</strong>
                  <p>
                    {r[t] === null || r[t] === undefined
                      ? "Not supplied"
                      : `${r[t]} / 5`}
                  </p>
                </div>
              ))}
            </div>
          </section>
          {(r.source_reference || r.source_url) && (
            <p>
              Source: {r.source_reference}{" "}
              {r.source_url && <a href={r.source_url}>View source ↗</a>}
            </p>
          )}
        </section>
        <aside>
          {r.cocktail && (
            <section className="panel">
              <span className="eyebrow">Connected to a classic</span>
              <h2>{r.cocktail.name}</h2>
              <Resource<{ description: string; history: string }>
                path={`/cocktails/${r.cocktail.id}.json`}
              >
                {(c) => (
                  <>
                    <p>{c.description}</p>
                    {c.history && (
                      <details>
                        <summary>The story</summary>
                        <p className="prose">{c.history}</p>
                      </details>
                    )}
                  </>
                )}
              </Resource>
              <Link to={`/cocktails/${r.cocktail.id}`}>
                Read the cocktail’s story →
              </Link>
            </section>
          )}
          <section className="panel">
            <h2>Keep it close</h2>
            {session.data?.data ? (
              <>
                <label>
                  Collection
                  <select
                    value={collectionId}
                    onChange={(e) => setCollectionId(e.target.value)}
                  >
                    <option value="">Choose a collection</option>
                    {collections.data?.data.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name}
                        {r.saved_collection_ids.includes(c.id)
                          ? " · saved"
                          : ""}
                      </option>
                    ))}
                  </select>
                </label>
                <button
                  disabled={!collectionId || busy}
                  onClick={async () => {
                    setBusy(true);
                    try {
                      const saved = r.saved_collection_ids.includes(
                        Number(collectionId),
                      );
                      await request(
                        saved
                          ? `/collections/${collectionId}/collection_recipes/${r.id}.json`
                          : `/collections/${collectionId}/collection_recipes.json`,
                        saved ? "DELETE" : "POST",
                        saved ? undefined : { recipe_id: r.id },
                      );
                      await client.invalidateQueries();
                      setMessage(
                        saved
                          ? "Removed from collection."
                          : "Saved to collection.",
                      );
                    } catch (e) {
                      setMessage((e as Error).message);
                    } finally {
                      setBusy(false);
                    }
                  }}
                >
                  {r.saved_collection_ids.includes(Number(collectionId))
                    ? "Remove from collection"
                    : "Save recipe"}
                </button>
                <Link to="/collections/new">New collection</Link>
              </>
            ) : (
              <Link to="/session/new">Sign in to save this recipe</Link>
            )}
          </section>
          {r.can_delete && (
            <button
              className="danger"
              disabled={busy}
              onClick={() => void remove()}
            >
              Delete recipe
            </button>
          )}
        </aside>
      </div>
      {guide && (
        <dialog
          open
          ref={(node) => {
            if (node && !node.hasAttribute("data-ready")) {
              node.removeAttribute("open");
              node.showModal();
              node.setAttribute("data-ready", "true");
            }
          }}
          onCancel={() => setGuide(null)}
        >
          <button
            className="dialog-close"
            autoFocus
            onClick={() => setGuide(null)}
          >
            Close guide ×
          </button>
          <h2>{guide.name}</h2>
          <p>{guide.description}</p>
          <p className="prose">{guide.instructions}</p>
          <p>{guide.tip}</p>
          <Link to={`/techniques/${guide.slug}`}>Open full guide</Link>
        </dialog>
      )}
    </>
  );
}
export function MyRecipes() {
  const [params, setParams] = useSearchParams();
  return (
    <main>
      <Heading eyebrow="Your recipe notebook" title="Good ideas start here.">
        <Link className="button primary" to="/recipes/new">
          Create a recipe
        </Link>
      </Heading>
      <div className="actions">
        <label>
          Find your recipe
          <input
            type="search"
            value={params.get("q") || ""}
            onChange={(e) =>
              setParams({ q: e.target.value, state: params.get("state") || "" })
            }
          />
        </label>
        <label>
          Status
          <select
            value={params.get("state") || ""}
            onChange={(e) =>
              setParams({ q: params.get("q") || "", state: e.target.value })
            }
          >
            <option value="">All recipes</option>
            <option value="draft">Draft</option>
            <option value="published">Published</option>
          </select>
        </label>
      </div>
      <Resource<RecipePage> path={`/my/recipes.json?${params}`}>
        {(data) => (
          <>
            {data.data.length ? (
              <RecipeCards recipes={data.data} />
            ) : (
              <Empty>
                <h2>A fresh page.</h2>
                <p>Create a recipe or adjust your search.</p>
              </Empty>
            )}
            {data.metadata.next_page && (
              <button
                onClick={() => {
                  params.set("page", String(data.metadata.next_page));
                  setParams(params);
                }}
              >
                Next page
              </button>
            )}
          </>
        )}
      </Resource>
    </main>
  );
}
export function CollectionsPage() {
  return (
    <main>
      <Heading
        eyebrow="Your personal shelves"
        title="A collection for every occasion."
      >
        <Link className="button primary" to="/collections/new">
          New collection
        </Link>
      </Heading>
      <Resource<{ data: Collection[] }> path="/my/collections.json">
        {(d) => <CollectionCards collections={d.data} />}
      </Resource>
    </main>
  );
}
function CollectionCards({ collections }: { collections: Collection[] }) {
  return (
    <div className="catalog-grid">
      {collections.map((c) => (
        <article className="panel collection-card" key={c.id}>
          <div className="collection-art">
            {c.previews.slice(0, 4).map((p) => (
              <Photo key={p.id} src={p.image_url} name="Recipe preview" />
            ))}
            {!c.previews.length && <span>Room for something good.</span>}
          </div>
          <span className="eyebrow">
            {c.visibility} · {c.recipe_count} recipes
          </span>
          <h2>
            <Link to={`/collections/${c.id}`}>{c.name}</Link>
          </h2>
        </article>
      ))}
    </div>
  );
}
export function CollectionDetail() {
  const { id } = useParams();
  const client = useQueryClient();
  const [error, setError] = useState("");
  return (
    <main>
      <Resource<{ data: Collection }> path={`/collections/${id}.json`}>
        {({ data: c }) => (
          <>
            <Heading eyebrow={`${c.visibility} collection`} title={c.name}>
              {c.owner && (
                <p>
                  Collected by{" "}
                  <Link to={`/profiles/${c.owner.id}`}>{c.owner.name}</Link>
                </p>
              )}
              {c.can_edit && (
                <Link className="button" to={`/collections/${id}/edit`}>
                  Edit collection
                </Link>
              )}
            </Heading>
            <p role="alert">{error}</p>
            {c.recipes.length ? (
              <RecipeCards recipes={c.recipes} />
            ) : (
              <Empty>
                <h2>Make room for your favorites.</h2>
                <Link to="/">Find recipes to save</Link>
              </Empty>
            )}
            {c.owned &&
              c.recipes.map((r) => (
                <div className="collection-remove" key={r.id}>
                  <span>{r.name}</span>
                  <button
                    onClick={async () => {
                      try {
                        await request(
                          `/collections/${id}/collection_recipes/${r.id}.json`,
                          "DELETE",
                        );
                        await client.invalidateQueries();
                      } catch (e) {
                        setError((e as Error).message);
                      }
                    }}
                  >
                    Remove from collection
                  </button>
                </div>
              ))}
          </>
        )}
      </Resource>
    </main>
  );
}
export function CollectionEditor() {
  const { id } = useParams();
  const session = useSession();
  if (session.isPending)
    return (
      <main>
        <Loading />
      </main>
    );
  if (session.error)
    return (
      <main>
        <Failure error={session.error} retry={() => void session.refetch()} />
      </main>
    );
  if (!session.data?.data)
    return (
      <main className="reading">
        <Heading title="Your notebook is waiting." />
        <p>Sign in to create and manage your work.</p>
        <Link className="button primary" to="/session/new">
          Sign in
        </Link>
      </main>
    );
  return (
    <main className="reading">
      <Heading
        title={id ? "Edit your collection." : "Start a new collection."}
      />
      {id ? (
        <Resource<{ data: Collection }> path={`/collections/${id}.json`}>
          {({ data }) =>
            data.can_edit ? (
              <CollectionForm collection={data} />
            ) : (
              <Empty>You cannot edit this collection.</Empty>
            )
          }
        </Resource>
      ) : (
        <CollectionForm />
      )}
    </main>
  );
}
function CollectionForm({ collection: c }: { collection?: Collection }) {
  const [name, setName] = useState(c?.name || "");
  const [visibility, setVisibility] = useState(c?.visibility || "private");
  const [deleteError, setDeleteError] = useState<Error>();
  const navigate = useNavigate();
  const client = useQueryClient();
  return (
    <AsyncForm
      onSubmit={async () => {
        const data = await request<{ data: Collection }>(
          c ? `/collections/${c.id}.json` : "/collections.json",
          c ? "PATCH" : "POST",
          { collection: { name, visibility } },
        );
        await client.invalidateQueries();
        navigate(`/collections/${data.data.id}`);
      }}
      submit="Save collection"
    >
      {deleteError && <Failure error={deleteError} />}
      <label>
        Name
        <input
          required
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
      </label>
      <label>
        Visibility
        <select
          disabled={c?.can_change_visibility === false}
          value={visibility}
          onChange={(e) => setVisibility(e.target.value)}
        >
          <option value="private">Private</option>
          <option value="public">Public</option>
        </select>
      </label>
      {c?.system_key === "favorites" && (
        <p>
          Favorites is your permanent private collection. You can rename it.
        </p>
      )}
      {c?.can_delete && (
        <button
          type="button"
          className="danger"
          onClick={async () => {
            if (confirm("Delete this collection? Recipes will remain.")) {
              try {
                await request(`/collections/${c.id}.json`, "DELETE");
                await client.invalidateQueries();
                navigate("/my/collections");
              } catch (error) {
                setDeleteError(error as Error);
              }
            }
          }}
        >
          Delete collection
        </button>
      )}
    </AsyncForm>
  );
}
export function ProfilePage() {
  const { id } = useParams();
  return (
    <main>
      <Resource<{ data: User }>
        path={id ? `/profiles/${id}.json` : "/my/profile.json"}
      >
        {({ data: u }) => (
          <>
            <div className="profile-heading">
              {u.image_url ? (
                <img
                  className="avatar"
                  src={mediaUrl(u.image_url)}
                  alt={u.name}
                />
              ) : (
                <div className="avatar initials">{u.name.slice(0, 2)}</div>
              )}
              <Heading eyebrow={`@${u.handle}`} title={u.name}>
                <p className="prose">{u.bio}</p>
                {u.owned && (
                  <Link className="button" to="/my/profile/edit">
                    Edit profile
                  </Link>
                )}
              </Heading>
            </div>
            <h2>Published recipes</h2>
            {u.recipes.length ? (
              <RecipeCards recipes={u.recipes} />
            ) : (
              <Empty>No public recipes yet.</Empty>
            )}
            <h2>Public collections</h2>
            <CollectionCards collections={u.collections} />
          </>
        )}
      </Resource>
    </main>
  );
}
export function ProfileEditor() {
  return (
    <main className="reading">
      <Heading title="Make yourself at home." />
      <Resource<{ data: User }> path="/my/profile.json">
        {({ data }) => <ProfileForm user={data} />}
      </Resource>
    </main>
  );
}
function ProfileForm({ user: u }: { user: User }) {
  const navigate = useNavigate();
  const client = useQueryClient();
  const [handle, setHandle] = useState(u.handle);
  const [name, setName] = useState(u.display_name || "");
  const [bio, setBio] = useState(u.bio || "");
  const [image, setImage] = useState<File>();
  const [remove, setRemove] = useState(false);
  return (
    <AsyncForm
      submit="Save profile"
      onSubmit={async () => {
        const body = new FormData();
        body.set("user[handle]", handle);
        body.set("user[display_name]", name);
        body.set("user[bio]", bio);
        body.set("user[remove_image]", String(remove));
        if (image) body.set("user[image]", image);
        await request("/my/profile.json", "PATCH", body);
        await client.invalidateQueries();
        navigate("/my/profile");
      }}
    >
      <label>
        Public handle
        <input
          required
          value={handle}
          onChange={(e) => setHandle(e.target.value)}
        />
      </label>
      <label>
        Display name
        <input value={name} onChange={(e) => setName(e.target.value)} />
      </label>
      <label>
        About you
        <textarea value={bio} onChange={(e) => setBio(e.target.value)} />
      </label>
      <label>
        Public profile photo
        <input
          type="file"
          accept="image/jpeg,image/png,image/webp"
          onChange={(e) => setImage(e.target.files?.[0])}
        />
      </label>
      <small>JPEG, PNG or WebP; up to 10 MB and 25 megapixels.</small>
      {u.image_url && (
        <label className="check">
          <input
            type="checkbox"
            checked={remove}
            onChange={(e) => setRemove(e.target.checked)}
          />
          Remove current photo
        </label>
      )}
    </AsyncForm>
  );
}
export function AsyncForm({
  children,
  onSubmit,
  submit,
}: {
  children: ReactNode;
  onSubmit: () => Promise<void>;
  submit: string;
}) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<Error>();
  const formRef = useRef<HTMLFormElement>(null);
  const errorRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (error) errorRef.current?.focus();
  }, [error]);
  async function save(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(undefined);
    try {
      await onSubmit();
    } catch (e) {
      setError(e as Error);
    } finally {
      setBusy(false);
    }
  }
  return (
    <form className="editor panel" onSubmit={save} ref={formRef}>
      {error && (
        <div ref={errorRef} tabIndex={-1} role="alert" className="notice error">
          <h2>Check these details</h2>
          {error instanceof ApiError ? (
            <ul>
              {Object.entries(error.errors).map(([field, messages]) => (
                <li key={field}>
                  <a
                    href="#"
                    onClick={(event) => {
                      event.preventDefault();
                      const label = Array.from(
                        formRef.current?.querySelectorAll("label") || [],
                      ).find((l) =>
                        l.textContent
                          ?.toLowerCase()
                          .includes(field.replaceAll("_", " ")),
                      );
                      label
                        ?.querySelector<HTMLInputElement>(
                          "input,select,textarea",
                        )
                        ?.focus();
                    }}
                  >
                    {field === "base" ? "" : `${field.replaceAll("_", " ")}: `}
                    {messages.join(", ")}
                  </a>
                </li>
              ))}
            </ul>
          ) : (
            <p>{error.message}</p>
          )}
        </div>
      )}{" "}
      {children}
      <div className="actions">
        <button className="primary" disabled={busy}>
          {busy ? "Saving…" : submit}
        </button>
        <Link to="/">Back to explore</Link>
      </div>
    </form>
  );
}
export function AuthPage({
  kind,
}: {
  kind: "login" | "register" | "recover" | "reset";
}) {
  const { token } = useParams();
  const validity = useQuery({
    queryKey: ["reset-token", token],
    queryFn: () =>
      getJson(`/passwords/${encodeURIComponent(token || "")}/edit.json`),
    enabled: kind === "reset",
    retry: false,
  });
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [message, setMessage] = useState("");
  const navigate = useNavigate();
  const client = useQueryClient();
  const title = {
    login: "Welcome back.",
    register: "Your next chapter starts here.",
    recover: "Let’s get you back in.",
    reset: "A fresh start.",
  }[kind];
  return (
    <main className="reading auth">
      <Heading eyebrow="A place for your good taste" title={title} />
      {kind === "reset" && validity.isPending ? (
        <Loading />
      ) : kind === "reset" && validity.error ? (
        <>
          <Failure error={validity.error} />
          <Link to="/passwords/new">Request a new reset link</Link>
        </>
      ) : message ? (
        <div className="notice" role="status">
          <p>{message}</p>
          <Link to="/session/new">Sign in</Link>
        </div>
      ) : (
        <AsyncForm
          submit={
            {
              login: "Sign in",
              register: "Create account",
              recover: "Send reset instructions",
              reset: "Reset password",
            }[kind]
          }
          onSubmit={async () => {
            if (kind === "recover") {
              const d = await request<{ data: { message: string } }>(
                "/passwords.json",
                "POST",
                { email_address: email },
              );
              setMessage(d.data.message);
            } else if (kind === "reset") {
              const d = await request<{ data: { message: string } }>(
                `/passwords/${encodeURIComponent(token || "")}.json`,
                "PATCH",
                { password, password_confirmation: confirmation },
              );
              await client.invalidateQueries();
              setMessage(d.data.message);
            } else {
              await request(
                kind === "login" ? "/session.json" : "/registration.json",
                "POST",
                kind === "login"
                  ? { email_address: email, password }
                  : {
                      user: {
                        email_address: email,
                        password,
                        password_confirmation: confirmation,
                      },
                    },
              );
              await client.invalidateQueries();
              navigate("/my/recipes");
            }
          }}
        >
          {kind !== "reset" && (
            <label>
              Email address
              <input
                autoComplete="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </label>
          )}
          {kind !== "recover" && (
            <label>
              Password
              <input
                autoComplete={
                  kind === "login" ? "current-password" : "new-password"
                }
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </label>
          )}
          {(kind === "register" || kind === "reset") && (
            <label>
              Confirm password
              <input
                type="password"
                autoComplete="new-password"
                required
                value={confirmation}
                onChange={(e) => setConfirmation(e.target.value)}
              />
            </label>
          )}
          {kind === "login" && (
            <>
              <Link to="/passwords/new">Forgot password?</Link>
              <Link to="/registration/new">Create an account</Link>
            </>
          )}
        </AsyncForm>
      )}
    </main>
  );
}
export function AccountPage() {
  const [password, setPassword] = useState("");
  const client = useQueryClient();
  const navigate = useNavigate();
  return (
    <main className="reading">
      <Heading eyebrow="Private account settings" title="Your account." />
      <Resource<{ data: User }> path="/my/account.json">
        {({ data: u }) => (
          <>
            <section className="panel">
              <h2>{u.name}</h2>
              <p>{u.email_address}</p>
              <Link to="/my/profile/edit">Edit public profile</Link>
            </section>
            <h2>Delete your account</h2>
            <p>
              This permanently deletes your recipes, collections, Favorites,
              profile, photos and sessions. Shared catalog records and other
              authors’ recipes remain.
            </p>
            <AsyncForm
              submit="Permanently delete account"
              onSubmit={async () => {
                if (
                  !confirm(
                    "Permanently delete your account and all your content?",
                  )
                )
                  return;
                await request("/my/account.json", "DELETE", { password });
                clearQueue();
                await client.invalidateQueries();
                navigate("/");
              }}
            >
              <label>
                Confirm with your password
                <input
                  required
                  type="password"
                  autoComplete="current-password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              </label>
            </AsyncForm>
          </>
        )}
      </Resource>
    </main>
  );
}
export function RecipeEditor() {
  const { id } = useParams();
  const session = useSession();
  if (session.isPending)
    return (
      <main>
        <Loading />
      </main>
    );
  if (session.error)
    return (
      <main>
        <Failure error={session.error} retry={() => void session.refetch()} />
      </main>
    );
  if (!session.data?.data)
    return (
      <main className="reading">
        <Heading title="Your notebook is waiting." />
        <p>Sign in to create and manage your work.</p>
        <Link className="button primary" to="/session/new">
          Sign in
        </Link>
      </main>
    );
  return (
    <main>
      <Heading
        eyebrow="Your recipe notebook"
        title={id ? "Refine your recipe." : "Something good is taking shape."}
      />
      {id ? (
        <Resource<Recipe> path={`/recipes/${id}.json`}>
          {(r) =>
            r.can_edit ? (
              <RecipeForm recipe={r} />
            ) : (
              <Empty>You cannot edit this recipe.</Empty>
            )
          }
        </Resource>
      ) : (
        <RecipeForm />
      )}
    </main>
  );
}
function RecipeForm({ recipe: r }: { recipe?: Recipe }) {
  const navigate = useNavigate();
  const client = useQueryClient();
  const [name, setName] = useState(r?.name || "");
  const [servings, setServings] = useState(r?.servings || 1);
  const [structuredSteps, setStructuredSteps] = useState<
    { id?: number; position: number; body: string; _destroy?: boolean }[]
  >(r?.recipe_steps.length ? r.recipe_steps : [{ position: 0, body: "" }]);
  const [visibility, setVisibility] = useState(r?.visibility || "private");
  const [state, setState] = useState(r?.publication_state || "draft");
  const [source, setSource] = useState(r?.source_reference || "");
  const [url, setUrl] = useState(r?.source_url || "");
  const [image, setImage] = useState<File>();
  const [techniques, setTechniques] = useState(
    r?.techniques.map((t) => t.id) || [],
  );
  const [lines, setLines] = useState<IngredientLine[]>(
    r?.recipe_ingredients || [],
  );
  const [tools, setTools] = useState<ToolLine[]>(r?.recipe_utensils || []);
  const [taste, setTaste] = useState({
    sweetness: r?.sweetness ?? "",
    sourness: r?.sourness ?? "",
    bitterness: r?.bitterness ?? "",
  });
  const ingredients = useResource<{ data: Option[] }>("/ingredients.json");
  const utensils = useResource<{ data: Option[] }>("/utensils.json");
  const guides = useResource<{ data: Technique[] }>("/techniques.json");
  function field(key: number, patch: Partial<IngredientLine>) {
    setLines(lines.map((l, i) => (i === key ? { ...l, ...patch } : l)));
  }
  return (
    <AsyncForm
      submit={r ? "Save changes" : "Create recipe"}
      onSubmit={async () => {
        const data = new FormData();
        const values = {
          name,
          servings,
          visibility,
          publication_state: state,
          source_reference: source,
          source_url: url,
          ...taste,
        };
        Object.entries(values).forEach(([k, v]) =>
          data.set(`recipe[${k}]`, String(v)),
        );
        data.append("recipe[technique_ids][]", "");
        techniques.forEach((id) =>
          data.append("recipe[technique_ids][]", String(id)),
        );
        structuredSteps
          .filter((step) => step.id || step.body.trim())
          .forEach((step, n) => {
            data.set(
              `recipe[recipe_steps_attributes][${n}][id]`,
              step.id ? String(step.id) : "",
            );
            data.set(
              `recipe[recipe_steps_attributes][${n}][position]`,
              String(step.position),
            );
            data.set(`recipe[recipe_steps_attributes][${n}][body]`, step.body);
            if (step._destroy)
              data.set(
                `recipe[recipe_steps_attributes][${n}][_destroy]`,
                "true",
              );
          });
        lines.forEach((line, n) =>
          Object.entries({ ...line, position: line.position ?? n }).forEach(
            ([k, v]) => {
              if (v !== undefined)
                data.set(
                  `recipe[recipe_ingredients_attributes][${n}][${k}]`,
                  v == null ? "" : String(v),
                );
            },
          ),
        );
        tools.forEach((line, n) =>
          Object.entries(line).forEach(([k, v]) => {
            if (v !== undefined)
              data.set(
                `recipe[recipe_utensils_attributes][${n}][${k}]`,
                v == null ? "" : String(v),
              );
          }),
        );
        if (image) data.set("recipe[image]", image);
        const saved = await request<Recipe>(
          r ? `/recipes/${r.id}.json` : "/recipes.json",
          r ? "PATCH" : "POST",
          data,
        );
        await client.invalidateQueries();
        navigate(`/recipes/${saved.id}`);
      }}
    >
      <section className="form-section">
        <div>
          <h2>The basics</h2>
          <p>A name worth remembering.</p>
        </div>
        <div>
          <label>
            Recipe name
            <input value={name} onChange={(e) => setName(e.target.value)} />
          </label>
          <label>
            Servings
            <input
              type="number"
              min="1"
              value={servings}
              onChange={(e) => setServings(Number(e.target.value))}
            />
          </label>
        </div>
      </section>
      <section className="form-section">
        <div>
          <h2>Every pour counts</h2>
          <p>
            Choose catalog ingredients and preserve your exact measurement
            wording.
          </p>
        </div>
        <div>
          {ingredients.error && <Failure error={ingredients.error} />}{" "}
          {lines.map((line, n) =>
            line._destroy ? null : (
              <fieldset key={n}>
                <legend>Ingredient {n + 1}</legend>
                <label>
                  Ingredient
                  <select
                    required
                    value={line.ingredient_id || ""}
                    onChange={(e) =>
                      field(n, { ingredient_id: Number(e.target.value) })
                    }
                  >
                    <option value="">Choose an ingredient</option>
                    {ingredients.data?.data.map((i) => (
                      <option key={i.id} value={i.id}>
                        {i.name}
                      </option>
                    ))}
                  </select>
                </label>
                <label>
                  Amount and ingredient, exactly as written
                  <input
                    required
                    placeholder="45 ml gin"
                    value={line.submitted_text}
                    onChange={(e) =>
                      field(n, { submitted_text: e.target.value })
                    }
                  />
                </label>
                <div className="taste-grid">
                  <label>
                    Quantity (optional)
                    <input
                      type="number"
                      min="0.0001"
                      step="any"
                      value={line.quantity || ""}
                      onChange={(e) => field(n, { quantity: e.target.value })}
                    />
                  </label>
                  <label>
                    Measuring unit
                    <input
                      value={line.measuring_unit || ""}
                      onChange={(e) =>
                        field(n, { measuring_unit: e.target.value })
                      }
                    />
                  </label>
                </div>
                <label>
                  Preparation note
                  <input
                    value={line.preparation_note || ""}
                    onChange={(e) =>
                      field(n, { preparation_note: e.target.value })
                    }
                  />
                </label>
                <label>
                  Role
                  <select
                    value={line.role || "mixing"}
                    onChange={(e) => field(n, { role: e.target.value })}
                  >
                    <option value="mixing">Mixing</option>
                    <option value="garnish">Garnish</option>
                    <option value="rim">Rim</option>
                  </select>
                </label>
                <label className="check">
                  <input
                    type="checkbox"
                    checked={!!line.optional}
                    onChange={(e) => field(n, { optional: e.target.checked })}
                  />
                  Optional
                </label>
                <button
                  type="button"
                  onClick={() => field(n, { _destroy: true })}
                >
                  Remove ingredient
                </button>
              </fieldset>
            ),
          )}
          <button
            type="button"
            onClick={() =>
              setLines([
                ...lines,
                {
                  ingredient_id: 0,
                  submitted_text: "",
                  position:
                    Math.max(-1, ...lines.map((l) => l.position ?? 0)) + 1,
                },
              ])
            }
          >
            Add ingredient
          </button>
        </div>
      </section>
      <section className="form-section">
        <div>
          <h2>Tools & preparation</h2>
          <p>Keep instructions practical and clear.</p>
        </div>
        <div>
          {tools.map((tool, n) =>
            tool._destroy ? null : (
              <fieldset key={n}>
                <legend>Tool {n + 1}</legend>
                <label>
                  Tool
                  <select
                    required
                    value={tool.utensil_id || ""}
                    onChange={(e) => {
                      const id = Number(e.target.value);
                      setTools(
                        tools.map((t, i) =>
                          i === n
                            ? {
                                ...t,
                                utensil_id: id,
                                submitted_text:
                                  utensils.data?.data.find((u) => u.id === id)
                                    ?.name || "",
                              }
                            : t,
                        ),
                      );
                    }}
                  >
                    <option value="">Choose a tool</option>
                    {utensils.data?.data.map((i) => (
                      <option key={i.id} value={i.id}>
                        {i.name}
                      </option>
                    ))}
                  </select>
                </label>
                <label>
                  Description
                  <input
                    required
                    value={tool.submitted_text}
                    onChange={(e) =>
                      setTools(
                        tools.map((t, i) =>
                          i === n
                            ? { ...t, submitted_text: e.target.value }
                            : t,
                        ),
                      )
                    }
                  />
                </label>
                <button
                  type="button"
                  onClick={() =>
                    setTools(
                      tools.map((t, i) =>
                        i === n ? { ...t, _destroy: true } : t,
                      ),
                    )
                  }
                >
                  Remove tool
                </button>
              </fieldset>
            ),
          )}
          <button
            type="button"
            onClick={() =>
              setTools([...tools, { utensil_id: 0, submitted_text: "" }])
            }
          >
            Add tool
          </button>
          {structuredSteps.map((step, n) =>
            step._destroy ? null : (
              <div key={step.id || `new-${n}`}>
                <label>
                  {n === 0 ? "Preparation steps" : `Preparation step ${n + 1}`}
                  <textarea
                    rows={5}
                    value={step.body}
                    onChange={(e) =>
                      setStructuredSteps(
                        structuredSteps.map((s, i) =>
                          i === n ? { ...s, body: e.target.value } : s,
                        ),
                      )
                    }
                  />
                </label>
                <button
                  type="button"
                  onClick={() =>
                    setStructuredSteps(
                      structuredSteps.map((s, i) =>
                        i === n ? { ...s, _destroy: true } : s,
                      ),
                    )
                  }
                >
                  Remove step {n + 1}
                </button>
              </div>
            ),
          )}
          <button
            type="button"
            onClick={() =>
              setStructuredSteps([
                ...structuredSteps,
                {
                  position:
                    Math.max(-1, ...structuredSteps.map((s) => s.position)) + 1,
                  body: "",
                },
              ])
            }
          >
            Add preparation step
          </button>
          <fieldset>
            <legend>Techniques</legend>
            {guides.data?.data.map((t) => (
              <label className="check" key={t.id}>
                <input
                  type="checkbox"
                  checked={techniques.includes(t.id)}
                  onChange={(e) =>
                    setTechniques(
                      e.target.checked
                        ? [...techniques, t.id]
                        : techniques.filter((id) => id !== t.id),
                    )
                  }
                />
                {t.name}
              </label>
            ))}
          </fieldset>
        </div>
      </section>
      <section className="form-section">
        <div>
          <h2>Your taste notes</h2>
          <p>
            Optional author-supplied intensity, 0 (none) to 5 (very high). Leave
            unknown when you haven’t assessed it.
          </p>
        </div>
        <div>
          {(["sweetness", "sourness", "bitterness"] as const).map((t) => (
            <label key={t}>
              {t}
              <select
                value={taste[t]}
                onChange={(e) => setTaste({ ...taste, [t]: e.target.value })}
              >
                <option value="">Unknown / not assessed</option>
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
      </section>
      <section className="form-section">
        <div>
          <h2>Make it yours</h2>
          <p>Photos, credits and sharing.</p>
        </div>
        <div>
          <label>
            Recipe photo
            <input
              type="file"
              accept="image/jpeg,image/png,image/webp"
              onChange={(e) => setImage(e.target.files?.[0])}
            />
          </label>
          <small>JPEG, PNG or WebP; up to 10 MB and 25 megapixels.</small>
          <label>
            Source or credit
            <input value={source} onChange={(e) => setSource(e.target.value)} />
          </label>
          <label>
            Source link
            <input
              type="url"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
            />
          </label>
          <label>
            Status
            <select value={state} onChange={(e) => setState(e.target.value)}>
              <option value="draft">Draft</option>
              <option value="published">Published</option>
            </select>
          </label>
          <label>
            Visibility
            <select
              value={visibility}
              onChange={(e) => setVisibility(e.target.value)}
            >
              <option value="private">Private</option>
              <option value="public">Public</option>
            </select>
          </label>
          <p>
            Public, published recipes with ingredients and preparation appear in
            discovery. Drafts remain yours.
          </p>
        </div>
      </section>
    </AsyncForm>
  );
}
