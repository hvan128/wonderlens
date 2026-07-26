import { cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";

import Home from "./page";

afterEach(cleanup);

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

  it("gives each content section the accessible name of its heading", () => {
    const { getByRole } = render(<Home />);

    expect(
      getByRole("region", {
        name: /từ chiếc camera đến câu chuyện vật liệu/i,
      }),
    ).toBeInTheDocument();
    expect(
      getByRole("region", {
        name: /chiếc cốc giấy bắt đầu từ đâu/i,
      }),
    ).toBeInTheDocument();
    expect(
      getByRole("region", {
        name: /tò mò hôm nay trở thành bộ sưu tập ngày mai/i,
      }),
    ).toBeInTheDocument();
    expect(
      getByRole("region", {
        name: /để gia đình biết điều gì đang xảy ra/i,
      }),
    ).toBeInTheDocument();
  });
});
