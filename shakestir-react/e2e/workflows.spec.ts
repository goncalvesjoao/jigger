import { test, expect } from "@playwright/test";

test.afterEach(async ({ page }) => {
  const response = await page.request.get("/api/session.json");
  const session = await response.json();
  if (session.data?.handle.startsWith("react-qa-"))
    await page.request.delete("/api/my/account.json", {
      headers: { "X-CSRF-Token": session.metadata.csrf_token },
      data: { password: "Reviewable!Password9" },
    });
});

test("desktop discovery, exact recipe, queue and mobile navigation", async ({
  page,
}) => {
  await page.goto("/");
  await expect(
    page.getByRole("heading", { name: /A little inspiration/ }),
  ).toBeVisible();
  await expect(page.locator(".recipe-card").first()).toBeVisible();
  await page
    .locator(".recipe-card img")
    .evaluateAll((images) =>
      images.forEach(
        (image) => ((image as HTMLImageElement).loading = "eager"),
      ),
    );
  await expect
    .poll(() =>
      page
        .locator(".recipe-card img")
        .evaluateAll((images) =>
          images.every((image) => (image as HTMLImageElement).naturalWidth > 0),
        ),
    )
    .toBe(true);
  await page.screenshot({
    path: "artifacts/discovery-desktop.png",
    fullPage: true,
  });
  await page.locator(".recipe-card h2 a").first().click();
  await expect(
    page.getByRole("heading", { name: "Preparation", exact: true }),
  ).toBeVisible();
  const title = await page.locator("h1").innerText();
  await page.getByRole("button", { name: "Make this drink" }).click();
  await page.getByRole("link", { name: /Mixing/ }).click();
  await expect(
    page.getByRole("heading", { name: title, exact: true }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Finish drink", exact: true }).click();
  await expect(
    page.getByText("Cheers. Ready for the next drink?"),
  ).toBeVisible();
  await page.reload();
  await expect(
    page.getByText("Cheers. Ready for the next drink?"),
  ).toBeVisible();
  await page.setViewportSize({ width: 375, height: 812 });
  await page.goto("/");
  await expect(page.locator(".recipe-card").first()).toBeVisible();
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    ),
  ).toBe(true);
  await page.getByRole("button", { name: /Menu/ }).click();
  await expect(
    page.getByRole("link", { name: "Techniques", exact: true }),
  ).toBeVisible();
  await page.getByRole("link", { name: "Techniques", exact: true }).click();
  await expect(page.locator(".catalog-grid article").first()).toBeVisible();
  await page.goto("/");
  await expect(page.locator(".recipe-card").first()).toBeVisible();
  await page
    .locator(".recipe-card img")
    .evaluateAll((images) =>
      images.forEach(
        (image) => ((image as HTMLImageElement).loading = "eager"),
      ),
    );
  await expect
    .poll(() =>
      page
        .locator(".recipe-card img")
        .evaluateAll((images) =>
          images.every((image) => (image as HTMLImageElement).naturalWidth > 0),
        ),
    )
    .toBe(true);
  await page.screenshot({
    path: "artifacts/discovery-mobile.png",
    fullPage: true,
  });
});

test("new account creates a published recipe, manages collections and deletes account", async ({
  page,
}) => {
  const email = `react-qa-${Date.now()}@example.com`;
  const password = "Reviewable!Password9";
  await page.goto("/registration/new");
  await page.getByLabel("Email address").fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByLabel("Confirm password").fill(password);
  await page
    .getByRole("button", { name: "Create account", exact: true })
    .click();
  await expect(page).toHaveURL(/my\/recipes/);
  await page.locator(".account-menu summary").click();
  await page.getByRole("button", { name: "Sign out", exact: true }).click();
  await page.goto("/session/new");
  await page.getByLabel("Email address").fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(page).toHaveURL(/my\/recipes/);
  await page.getByRole("link", { name: "Create a recipe" }).click();
  await page.getByLabel("Recipe name").fill("React QA citrus");
  await page
    .getByRole("button", { name: "Add ingredient", exact: true })
    .click();
  await page
    .getByRole("combobox", { name: "Ingredient", exact: true })
    .selectOption({ index: 1 });
  await page
    .getByLabel("Amount and ingredient, exactly as written")
    .fill("45 ml of the selected ingredient");
  await page
    .getByLabel("Preparation steps", { exact: true })
    .fill("Stir with care. Serve.");
  await page
    .getByRole("combobox", { name: "sweetness", exact: true })
    .selectOption("2");
  await page
    .getByRole("combobox", { name: "Status", exact: true })
    .selectOption("published");
  await page
    .getByRole("combobox", { name: "Visibility", exact: true })
    .selectOption("public");
  await page
    .getByRole("button", { name: "Create recipe", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "React QA citrus", exact: true }),
  ).toBeVisible();
  await page.getByRole("button", { name: /Star React QA/ }).click();
  await expect(
    page.getByRole("button", { name: /Unstar React QA/ }),
  ).toBeVisible();
  const recipePath = new URL(page.url()).pathname;
  await page.getByRole("link", { name: "Edit recipe", exact: true }).click();
  await page
    .getByRole("button", { name: "Add preparation step", exact: true })
    .click();
  await page
    .getByLabel("Preparation step 2", { exact: true })
    .fill("Finish with a twist.");
  await page.getByRole("button", { name: "Save changes", exact: true }).click();
  await expect(page).toHaveURL(recipePath);
  await expect(
    page.getByText("Finish with a twist.", { exact: true }),
  ).toBeVisible();
  await page.screenshot({
    path: "artifacts/recipe-desktop.png",
    fullPage: true,
  });
  await page.getByRole("link", { name: "New collection", exact: true }).click();
  await page.getByLabel("Name", { exact: true }).fill("QA collection");
  await page.getByRole("button", { name: "Save collection" }).click();
  await expect(
    page.getByRole("heading", { name: "QA collection" }),
  ).toBeVisible();
  const collectionPath = new URL(page.url()).pathname;
  await page.goto(recipePath);
  await page
    .getByRole("combobox", { name: "Collection", exact: true })
    .selectOption({ label: "QA collection" });
  await page.getByRole("button", { name: "Save recipe", exact: true }).click();
  await expect(
    page.getByRole("button", { name: "Remove from collection", exact: true }),
  ).toBeVisible();
  await page.goto(collectionPath);
  await expect(
    page.getByRole("link", { name: "React QA citrus", exact: true }),
  ).toBeVisible();
  await page
    .getByRole("button", { name: "Remove from collection", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Make room for your favorites." }),
  ).toBeVisible();
  await page
    .getByRole("link", { name: "Edit collection", exact: true })
    .click();
  await page.getByLabel("Name", { exact: true }).fill("QA collection renamed");
  await page.getByRole("button", { name: "Save collection" }).click();
  await expect(
    page.getByRole("heading", { name: "QA collection renamed" }),
  ).toBeVisible();
  await page.goto("/my/collections");
  await page.getByRole("link", { name: "Favorites", exact: true }).click();
  await page
    .getByRole("link", { name: "Edit collection", exact: true })
    .click();
  await expect(
    page.getByRole("combobox", { name: "Visibility", exact: true }),
  ).toBeDisabled();
  await expect(
    page.getByRole("button", { name: "Delete collection", exact: true }),
  ).toHaveCount(0);
  await page.goto("/my/profile/edit");
  await page.getByLabel("Display name").fill("React QA author");
  await page.getByLabel("About you").fill("A test profile.");
  await page
    .getByLabel("Public profile photo")
    .setInputFiles("src/assets/hero-cocktail.jpg");
  await page.getByRole("button", { name: "Save profile" }).click();
  await expect(
    page.getByRole("heading", { name: "React QA author" }),
  ).toBeVisible();
  await expect(page.locator("img.avatar")).toBeVisible();
  await page.goto("/my/profile/edit");
  await page.getByRole("checkbox", { name: "Remove current photo" }).check();
  await page.getByRole("button", { name: "Save profile" }).click();
  await expect(page.locator("img.avatar")).toHaveCount(0);
  await page.goto("/my/account");
  await page.getByLabel("Confirm with your password").fill(password);
  page.once("dialog", (d) => d.accept());
  await page
    .getByRole("button", { name: "Permanently delete account" })
    .click();
  await expect(page).toHaveURL("/");
});

test("public knowledge routes, missing pages and signed-out authoring", async ({
  page,
}) => {
  for (const route of [
    "/cocktails",
    "/ingredients",
    "/utensils",
    "/techniques",
  ]) {
    await page.goto(route);
    await expect(page.locator(".catalog-grid article").first()).toBeVisible();
  }
  await page.locator(".catalog-grid article h2 a").first().click();
  await expect(
    page.getByRole("heading", { name: "How to do it", exact: true }),
  ).toBeVisible();
  await page.goto("/recipes/new");
  await expect(
    page.getByRole("link", { name: "Sign in", exact: true }),
  ).toBeVisible();
  await page.goto("/not-a-route");
  await expect(
    page.getByRole("heading", { name: "This page isn’t on the menu." }),
  ).toBeVisible();
  await page.goto("/passwords/invalid/edit");
  await expect(
    page.getByText("Password reset link is invalid or has expired."),
  ).toBeVisible();
});
