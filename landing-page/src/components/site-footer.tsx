import { Brand } from "./brand";
import styles from "./site-footer.module.css";

const legalLinks = [
  {
    href: "https://wonderlens-proxy.vercel.app/privacy",
    label: "Quyền riêng tư",
  },
  {
    href: "https://wonderlens-proxy.vercel.app/terms",
    label: "Điều khoản",
  },
  {
    href: "https://wonderlens-proxy.vercel.app/support",
    label: "Hỗ trợ",
  },
];

export function SiteFooter() {
  return (
    <footer className={styles.footer}>
      <div className={styles.inner}>
        <div className={styles.brand}>
          <Brand compact />
          <p>
            Bản giới thiệu sản phẩm. Hiện chưa có liên kết tải công khai.
          </p>
        </div>
        <nav className={styles.legal} aria-label="Pháp lý và hỗ trợ">
          {legalLinks.map((link) => (
            <a href={link.href} key={link.href}>
              {link.label}
            </a>
          ))}
        </nav>
      </div>
    </footer>
  );
}
