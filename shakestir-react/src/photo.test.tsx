import { expect, test } from "vitest";
import { fireEvent, render, screen } from "@testing-library/react";
import { Photo } from "./ui";

test("failed photography shows the accessible fallback and a changed URL can load", () => {
  const { rerender } = render(
    <Photo src="/missing-image" name="Snowfall Sidecar" />,
  );
  fireEvent.error(screen.getByRole("img", { name: "Snowfall Sidecar" }));
  expect(
    screen.getByLabelText("No photo for Snowfall Sidecar"),
  ).toBeInTheDocument();
  expect(
    screen.queryByRole("img", { name: "Snowfall Sidecar" }),
  ).not.toBeInTheDocument();
  rerender(<Photo src="/repaired-image" name="Snowfall Sidecar" />);
  expect(screen.getByRole("img", { name: "Snowfall Sidecar" })).toHaveAttribute(
    "src",
    "/repaired-image",
  );
});

test("a failed recipe photograph uses its permitted canonical photo before the placeholder", () => {
  render(
    <Photo
      src="/recipe-image"
      fallbackSrc="/canonical-image"
      name="Snowfall Sidecar"
    />,
  );
  fireEvent.error(screen.getByRole("img", { name: "Snowfall Sidecar" }));
  expect(screen.getByRole("img", { name: "Snowfall Sidecar" })).toHaveAttribute(
    "src",
    "/canonical-image",
  );
  fireEvent.error(screen.getByRole("img", { name: "Snowfall Sidecar" }));
  expect(
    screen.getByLabelText("No photo for Snowfall Sidecar"),
  ).toBeInTheDocument();
});
