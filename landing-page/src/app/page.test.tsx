import { cleanup, render, screen, within } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";

import Home from "./page";

afterEach(cleanup);

describe("WonderLens landing page", () => {
  it("introduces the product and its family-facing trust model", () => {
    render(<Home />);

    expect(
      screen.getByRole("heading", {
        level: 1,
        name: /mỗi đồ vật đều có một lịch sử để kể/i,
      }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", {
        name: /xem lịch sử cốc giấy/i,
      }),
    ).toHaveAttribute("href", "#lich-su");
    expect(
      screen.getByRole("navigation", {
        name: /điều hướng chính/i,
      }),
    ).toBeInTheDocument();
    expect(screen.getByText(/không tài khoản trẻ/i)).toBeInTheDocument();
  });

  it("prioritizes object history and the real manufacturing journey", () => {
    render(<Home />);

    expect(
      screen.getByRole("link", { name: /cách làm ra/i }),
    ).toHaveAttribute("href", "#cach-lam-ra");

    const history = screen.getByRole("region", {
      name: /hơn một trăm năm trong một chiếc cốc giấy/i,
    });
    expect(
      within(history).getByText(/nhiều người từng dùng chung cốc uống nước/i),
    ).toBeInTheDocument();

    const making = screen.getByRole("region", {
      name: /cách chiếc cốc giấy được làm ra/i,
    });
    expect(within(making).getAllByRole("figure")).toHaveLength(4);
    expect(
      within(making).getByRole("heading", {
        level: 3,
        name: /sau khi dùng, câu chuyện chưa kết thúc/i,
      }),
    ).toBeInTheDocument();
  });

  it("puts explicit family and AI guardrails before the story", () => {
    const { container } = render(<Home />);

    const guardrails = screen.getByRole("region", {
      name: /giới hạn được nói rõ, không giấu ở cuối trang/i,
    });
    expect(
      within(guardrails).getByText(/không phải công cụ để trẻ tự dùng/i),
    ).toBeInTheDocument();
    expect(
      within(guardrails).getByText(/ảnh chụp đi qua proxy tới AI/i),
    ).toBeInTheDocument();
    expect(
      within(guardrails).getByText(/AI-live có thể sai/i),
    ).toBeInTheDocument();
    expect(
      within(guardrails).getByText(
        /runtime kid-safety audit chưa hoàn tất/i,
      ),
    ).toBeInTheDocument();

    const sectionIds = Array.from(
      container.querySelector("main")?.children ?? [],
      (section) => section.id,
    );
    expect(sectionIds.indexOf("rao-chan")).toBeLessThan(
      sectionIds.indexOf("lich-su"),
    );
  });

  it("gives each content section the accessible name of its heading", () => {
    const { getByRole } = render(<Home />);

    expect(
      getByRole("region", {
        name: /hơn một trăm năm trong một chiếc cốc giấy/i,
      }),
    ).toBeInTheDocument();
    expect(
      getByRole("region", {
        name: /cách chiếc cốc giấy được làm ra/i,
      }),
    ).toBeInTheDocument();
    expect(
      getByRole("region", {
        name: /từ chiếc camera đến câu chuyện vật liệu/i,
      }),
    ).toBeInTheDocument();
    expect(
      getByRole("region", {
        name: /tò mò hôm nay trở thành bộ sưu tập ngày mai/i,
      }),
    ).toBeInTheDocument();
    expect(
      getByRole("region", {
        name: /giới hạn được nói rõ, không giấu ở cuối trang/i,
      }),
    ).toBeInTheDocument();
  });
});
