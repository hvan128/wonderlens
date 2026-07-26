import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import NotFound from "./not-found";

describe("WonderLens not-found page", () => {
  it("links its header navigation back to sections on the home page", () => {
    render(<NotFound />);

    expect(
      screen.getByRole("link", { name: "Cách hoạt động" }),
    ).toHaveAttribute("href", "/#cach-hoat-dong");
    expect(screen.getByRole("link", { name: "Hành trình" })).toHaveAttribute(
      "href",
      "/#hanh-trinh",
    );
    expect(
      screen.getByRole("link", { name: "Trong ứng dụng" }),
    ).toHaveAttribute("href", "/#ung-dung");
    expect(
      screen.getByRole("link", { name: /WonderLens — về đầu trang/i }),
    ).toHaveAttribute("href", "/#dau-trang");
  });
});
