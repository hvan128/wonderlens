import { Brand } from "./brand";
import { ButtonLink } from "./button-link";
import styles from "./site-header.module.css";

const navigation = [
  { href: "#lich-su", label: "Lịch sử" },
  { href: "#cach-lam-ra", label: "Cách làm ra" },
  { href: "#rao-chan", label: "Rào chắn" },
];

type SiteHeaderProps = {
  sectionHrefPrefix?: string;
};

export function SiteHeader({ sectionHrefPrefix = "" }: SiteHeaderProps) {
  return (
    <header className={styles.header}>
      <nav className={styles.navigation} aria-label="Điều hướng chính">
        <a
          className={styles.brandLink}
          href={`${sectionHrefPrefix}#dau-trang`}
          aria-label="WonderLens — về đầu trang"
        >
          <Brand compact />
        </a>
        <ul className={styles.links}>
          {navigation.map((item) => (
            <li key={item.href}>
              <a href={`${sectionHrefPrefix}${item.href}`}>{item.label}</a>
            </li>
          ))}
        </ul>
        <div className={styles.action}>
          <ButtonLink
            href={`${sectionHrefPrefix}#lich-su`}
            variant="secondary"
          >
            Xem câu chuyện
          </ButtonLink>
        </div>
      </nav>
    </header>
  );
}
