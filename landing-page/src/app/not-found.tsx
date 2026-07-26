import type { Metadata } from "next";

import { ButtonLink } from "@/components/button-link";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";

import styles from "./not-found.module.css";

export const metadata: Metadata = {
  title: "Không tìm thấy trang | WonderLens",
};

export default function NotFound() {
  return (
    <>
      <a className="skip-link" href="#noi-dung-chinh">
        Bỏ qua điều hướng
      </a>
      <SiteHeader sectionHrefPrefix="/" />
      <main className={styles.main} id="noi-dung-chinh" tabIndex={-1}>
        <p className={styles.eyebrow}>Lạc khỏi hành trình rồi</p>
        <h1>Không tìm thấy trang này.</h1>
        <p>
          Đường dẫn có thể đã thay đổi. Mình quay lại trang giới thiệu
          WonderLens nhé.
        </p>
        <ButtonLink href="/">Về trang chủ</ButtonLink>
      </main>
      <SiteFooter />
    </>
  );
}
