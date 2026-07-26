import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Home from "./page";

describe("WonderLens landing page", () => {
  it("introduces the product and its family-facing trust model", () => {
    render(<Home />);

    expect(
      screen.getByRole("heading", {
        level: 1,
        name: /mọi đồ vật đều có một câu chuyện khoa học/i,
      }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", {
        name: /xem cách wonderlens hoạt động/i,
      }),
    ).toHaveAttribute("href", "#cach-hoat-dong");
    expect(
      screen.getByRole("navigation", {
        name: /điều hướng chính/i,
      }),
    ).toBeInTheDocument();
    expect(screen.getByText(/không tài khoản trẻ/i)).toBeInTheDocument();
  });
});
