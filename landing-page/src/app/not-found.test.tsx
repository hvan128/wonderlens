import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import NotFound from "./not-found";

describe("WonderLens not-found page", () => {
  it("links its header navigation back to sections on the home page", () => {
    render(<NotFound />);

    expect(
      screen.getByRole("link", { name: "Lịch sử" }),
    ).toHaveAttribute("href", "/#lich-su");
    expect(screen.getByRole("link", { name: "Cách làm ra" })).toHaveAttribute(
      "href",
      "/#cach-lam-ra",
    );
    expect(screen.getByRole("link", { name: "Rào chắn" })).toHaveAttribute(
      "href",
      "/#rao-chan",
    );
    expect(
      screen.getByRole("link", { name: /WonderLens — về đầu trang/i }),
    ).toHaveAttribute("href", "/#dau-trang");
  });
});
