import { useEffect, useState } from "react";
import {
  Link,
  NavLink,
  Navigate,
  Route,
  Routes,
  useLocation,
} from "react-router";
import { useQueryClient } from "@tanstack/react-query";
import { MarketplacePage } from "./marketplace/MarketplacePage";
import {
  AccountPage,
  AuthPage,
  Catalog,
  CocktailPage,
  CollectionDetail,
  CollectionEditor,
  CollectionsPage,
  MyRecipes,
  ProfileEditor,
  ProfilePage,
  RecipeDetail,
  RecipeEditor,
  TechniquePage,
} from "./pages";
import { mediaUrl, request } from "./api";
import { useSession } from "./session";
import { QueuePage } from "./queue";
import { readQueue, clearQueue } from "./mixing-store";
export default function App() {
  const session = useSession();
  const client = useQueryClient();
  const [queue, setQueue] = useState(readQueue().length);
  const [menu, setMenu] = useState(false);
  const [error, setError] = useState("");
  const location = useLocation();
  useEffect(() => {
    const update = () => setQueue(readQueue().length);
    window.addEventListener("queue-change", update);
    return () => window.removeEventListener("queue-change", update);
  }, []);
  useEffect(() => {
    window.scrollTo(0, 0);
    document.getElementById("content")?.focus({ preventScroll: true });
    document.title = `${location.pathname === "/" ? "Discover recipes" : location.pathname.split("/").filter(Boolean).join(" · ")} · ShakeStir`;
  }, [location.pathname]);
  return (
    <>
      <a className="skip-link" href="#content">
        Skip to content
      </a>
      <header className="site-header">
        <Link className="wordmark" to="/">
          Shake<span>&</span>Stir<span className="brand-dot">●</span>
        </Link>
        <button
          className="menu-toggle"
          aria-expanded={menu}
          aria-controls="main-nav"
          onClick={() => setMenu(!menu)}
        >
          Menu {menu ? "−" : "+"}
        </button>
        <nav
          id="main-nav"
          className={menu ? "open" : ""}
          aria-label="Main navigation"
          onClick={() => setMenu(false)}
        >
          <NavLink to="/" end>
            Explore
          </NavLink>
          <NavLink to="/cocktails">Cocktails</NavLink>
          <NavLink to="/techniques">Techniques</NavLink>
          <NavLink to="/ingredients">Ingredients</NavLink>
          <NavLink to="/utensils">Tools</NavLink>
          <NavLink className="queue-link" to="/mixing">
            Mixing <span>{queue}</span>
          </NavLink>
        </nav>
        <details className="account-menu">
          <summary>
            {session.data?.data ? (
              <>
                {session.data.data.image_url ? (
                  <img src={mediaUrl(session.data.data.image_url)} alt="" />
                ) : (
                  <span className="menu-avatar" aria-hidden="true">
                    {session.data.data.handle.slice(0, 1).toUpperCase()}
                  </span>
                )}
                <span
                  className="account-handle"
                  title={`@${session.data.data.handle}`}
                >
                  @{session.data.data.handle}
                </span>
              </>
            ) : (
              "Your notebook"
            )}
          </summary>
          <div>
            {session.data?.data ? (
              <>
                <Link to="/my/recipes">My recipes</Link>
                <Link to="/my/collections">My collections</Link>
                <Link to="/my/profile">My profile</Link>
                <Link to="/my/account">My account</Link>
                <button
                  onClick={async () => {
                    try {
                      await request("/session.json", "DELETE");
                      clearQueue();
                      client.clear();
                      await client.invalidateQueries();
                    } catch (e) {
                      setError((e as Error).message);
                    }
                  }}
                >
                  Sign out
                </button>
              </>
            ) : (
              <>
                <Link to="/session/new">Sign in</Link>
                <Link to="/registration/new">Create account</Link>
              </>
            )}
          </div>
        </details>
      </header>
      {error && <p role="alert">{error}</p>}
      <div id="content" tabIndex={-1}>
        <Routes>
          <Route path="/" element={<MarketplacePage />} />
          <Route path="/recipes" element={<MarketplacePage />} />
          <Route path="/recipes/new" element={<RecipeEditor />} />
          <Route path="/recipes/:id/edit" element={<RecipeEditor />} />
          <Route path="/recipes/:id" element={<RecipeDetail />} />
          <Route path="/cocktails" element={<Catalog kind="cocktails" />} />
          <Route path="/cocktails/:id" element={<CocktailPage />} />
          <Route path="/techniques" element={<Catalog kind="techniques" />} />
          <Route path="/techniques/:id" element={<TechniquePage />} />
          <Route path="/ingredients" element={<Catalog kind="ingredients" />} />
          <Route path="/utensils" element={<Catalog kind="utensils" />} />
          <Route path="/my/recipes" element={<MyRecipes />} />
          <Route path="/my/collections" element={<CollectionsPage />} />
          <Route path="/collections" element={<CollectionsPage />} />
          <Route
            path="/my/lists"
            element={<Navigate replace to="/my/collections" />}
          />
          <Route path="/collections/new" element={<CollectionEditor />} />
          <Route path="/collections/:id/edit" element={<CollectionEditor />} />
          <Route path="/collections/:id" element={<CollectionDetail />} />
          <Route path="/my/profile/edit" element={<ProfileEditor />} />
          <Route path="/my/profile" element={<ProfilePage />} />
          <Route path="/profiles/:id" element={<ProfilePage />} />
          <Route path="/my/account" element={<AccountPage />} />
          <Route path="/session/new" element={<AuthPage kind="login" />} />
          <Route
            path="/registration/new"
            element={<AuthPage kind="register" />}
          />
          <Route path="/passwords/new" element={<AuthPage kind="recover" />} />
          <Route
            path="/passwords/:token/edit"
            element={<AuthPage kind="reset" />}
          />
          <Route path="/mixing" element={<QueuePage />} />
          <Route
            path="*"
            element={
              <main>
                <span className="eyebrow">404 · A wrong turn</span>
                <h1>This page isn’t on the menu.</h1>
                <Link className="button primary" to="/">
                  Back to explore
                </Link>
              </main>
            }
          />
        </Routes>
      </div>
      <footer className="site-footer">
        <Link className="wordmark" to="/">
          Shake<span>&</span>Stir.
        </Link>
        <p>Good drinks. Shared knowledge. No distractions.</p>
        <Link to="/recipes/new">Share your recipe ↗</Link>
      </footer>
    </>
  );
}
