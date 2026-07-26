import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { ButtonLink } from "./button-link";

describe("ButtonLink", () => {
  it("renders a semantic link with an optional accessible name", () => {
    render(
      <ButtonLink
        href="#cach-hoat-dong"
        variant="secondary"
        ariaLabel="Khám phá cách WonderLens hoạt động"
      >
        Xem chi tiết
      </ButtonLink>,
    );

    expect(
      screen.getByRole("link", {
        name: "Khám phá cách WonderLens hoạt động",
      }),
    ).toHaveAttribute("href", "#cach-hoat-dong");
  });
});
