import { useState } from "react";
import { Link } from "react-router";
import { readQueue, type QueueItem } from "./mixing-store";
import { Heading, Empty } from "./ui";
export function QueuePage() {
  const [items, setItems] = useState(readQueue);
  const [active, setActive] = useState(0);
  const item = items[active];
  function save(next: QueueItem[]) {
    setItems(next);
    sessionStorage.setItem("shakestir-mixing", JSON.stringify(next));
    window.dispatchEvent(new Event("queue-change"));
  }
  function update(patch: Partial<QueueItem>) {
    save(items.map((i, n) => (n === active ? { ...i, ...patch } : i)));
  }
  return (
    <main>
      <Heading
        eyebrow="Your session · saved in this tab"
        title="Let’s make a drink."
      >
        <p>One step at a time. Your saved collections stay separate.</p>
      </Heading>
      {!item ? (
        <Empty>
          <h2>Your mixing queue is clear.</h2>
          <Link className="button" to="/">
            Find a recipe
          </Link>
        </Empty>
      ) : (
        <div className="mix-layout">
          <aside className="panel">
            <h2>On the bar</h2>
            {items.map((i, n) => (
              <button
                className={active === n ? "selected" : ""}
                key={i.id}
                onClick={() => setActive(n)}
              >
                {i.done ? "✓ " : ""}
                {i.name}
              </button>
            ))}
            <button
              onClick={() => {
                save(items.filter((_, n) => n !== active));
                setActive(0);
              }}
            >
              Remove this drink
            </button>
          </aside>
          <section className="panel mixing">
            <span className="eyebrow">
              {item.done
                ? "Finished"
                : `Step ${item.step + 1} of ${item.steps.length}`}
            </span>
            <h2>{item.name}</h2>
            <p className="mix-step" aria-live="polite">
              {item.done
                ? "Cheers. Ready for the next drink?"
                : item.steps[item.step] || "No preparation steps supplied."}
            </p>
            <div className="actions">
              <button
                disabled={item.step === 0 && !item.done}
                onClick={() =>
                  update({ step: Math.max(0, item.step - 1), done: false })
                }
              >
                Previous
              </button>
              <button
                className="primary"
                disabled={item.done}
                onClick={() =>
                  item.step + 1 < item.steps.length
                    ? update({ step: item.step + 1 })
                    : update({ done: true })
                }
              >
                {item.step + 1 < item.steps.length
                  ? "Next step"
                  : "Finish drink"}
              </button>
            </div>
            <details>
              <summary>Ingredients & tools</summary>
              <ul>
                {[...item.ingredients, ...item.tools].map((line, n) => (
                  <li key={n}>{line}</li>
                ))}
              </ul>
            </details>
            <Link to={`/recipes/${item.id}`}>Full recipe</Link>
          </section>
        </div>
      )}
    </main>
  );
}
