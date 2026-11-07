import { useSession } from "./session";
import { useState, type ReactNode } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router";
import { mediaUrl, request, type Recipe } from "./api";
export function Failure({
  error,
  retry,
}: {
  error: Error;
  retry?: () => void;
}) {
  return (
    <div className="notice error" role="alert">
      <h2>
        {"status" in error && error.status === 401
          ? "Sign in to continue"
          : "Something needs attention"}
      </h2>
      <p>{error.message}</p>
      {"status" in error && error.status === 401 ? (
        <Link to="/session/new">Sign in</Link>
      ) : (
        retry && <button onClick={retry}>Try again</button>
      )}
    </div>
  );
}
export function Loading() {
  return (
    <p className="notice" role="status">
      Getting things ready…
    </p>
  );
}
export function Heading({
  eyebrow,
  title,
  children,
}: {
  eyebrow?: string;
  title: string;
  children?: ReactNode;
}) {
  return (
    <header className="page-heading">
      <span className="eyebrow">{eyebrow || "The ShakeStir notebook"}</span>
      <h1>{title}</h1>
      {children}
    </header>
  );
}
export function Photo({
  src,
  fallbackSrc,
  name,
}: {
  src?: string | null;
  fallbackSrc?: string | null;
  name: string;
}) {
  const [failedSources, setFailedSources] = useState<string[]>([]);
  const activeSrc = [src, fallbackSrc].find(
    (url) => url && !failedSources.includes(url),
  );
  return activeSrc ? (
    <img
      src={mediaUrl(activeSrc)}
      alt={name}
      loading="lazy"
      onError={() => setFailedSources((current) => [...current, activeSrc])}
    />
  ) : (
    <div
      className="photo-placeholder"
      role="img"
      aria-label={`No photo for ${name}`}
    >
      <span>
        Shake
        <br />
        <i>& Stir.</i>
      </span>
    </div>
  );
}
export function Star({ recipe }: { recipe: Recipe }) {
  const session = useSession();
  const client = useQueryClient();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  return (
    <>
      <button
        className="star"
        aria-label={`${recipe.starred ? "Unstar" : "Star"} ${recipe.name}`}
        aria-pressed={recipe.starred}
        disabled={busy}
        onClick={async () => {
          if (!session.data?.data) {
            location.assign("/session/new");
            return;
          }
          setBusy(true);
          try {
            await request(
              `/recipes/${recipe.id}/star.json`,
              recipe.starred ? "DELETE" : "POST",
            );
            await client.invalidateQueries();
          } catch (e) {
            setError((e as Error).message);
          } finally {
            setBusy(false);
          }
        }}
      >
        {recipe.starred ? "★" : "☆"} {recipe.star_count}
      </button>
      {error && <p role="alert">{error}</p>}
    </>
  );
}
export function RecipeCards({ recipes }: { recipes: Recipe[] }) {
  return (
    <div className="recipe-grid">
      {recipes.map((recipe) => (
        <article className="recipe-card" key={recipe.id}>
          <div className="card-photo">
            <Link to={`/recipes/${recipe.id}`}>
              <Photo
                src={recipe.image_url}
                fallbackSrc={recipe.fallback_image_url}
                name={recipe.name}
              />
            </Link>
            <Star recipe={recipe} />
          </div>
          <Link
            className="author"
            to={`/profiles/${recipe.author_profile?.id}`}
          >
            {recipe.author}
          </Link>
          <h2>
            <Link to={`/recipes/${recipe.id}`}>
              {recipe.name || "Untitled recipe"}
            </Link>
          </h2>
          {recipe.publication_state === "draft" && (
            <span className="tag">Draft · {recipe.visibility}</span>
          )}
        </article>
      ))}
    </div>
  );
}
export function Empty({ children }: { children: ReactNode }) {
  return <div className="empty">{children}</div>;
}
