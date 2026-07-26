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
    expect(
      screen.getByRole("link", { name: "An tâm khám phá" }),
    ).toHaveAttribute("href", "#rao-chan");
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

  it("puts parent-facing safety information before the story", () => {
    const { container } = render(<Home />);

    const safety = screen.getByRole("region", {
      name: /cùng con khám phá, với những lớp bảo vệ rõ ràng/i,
    });
    expect(
      within(safety).getByText(/có các lớp kiểm tra an toàn/i),
    ).toBeInTheDocument();
    expect(
      within(safety).getAllByText(/nội dung do AI hỗ trợ.*luôn có nhãn/i),
    ).toHaveLength(2);
    expect(
      within(safety).getByText(/AI đôi khi có thể nhầm/i),
    ).toBeInTheDocument();
    expect(
      within(safety).getByText(/ảnh chụp được gửi tới dịch vụ AI/i),
    ).toBeInTheDocument();
    expect(
      within(safety).getByText(/không cần tài khoản trẻ.*không quảng cáo/i),
    ).toBeInTheDocument();
    expect(safety).not.toHaveTextContent(
      /runtime|kid-safety|safety pass|prompt|moderation|proxy|tracking|cookie|analytics|AI-live/i,
    );

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
        name: /cùng con khám phá, với những lớp bảo vệ rõ ràng/i,
      }),
    ).toBeInTheDocument();
  });
});
