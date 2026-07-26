import { Brand } from "./brand";
import { ButtonLink } from "./button-link";
import styles from "./site-header.module.css";

const navigation = [
  { href: "#cach-hoat-dong", label: "Cách hoạt động" },
  { href: "#hanh-trinh", label: "Hành trình" },
  { href: "#ung-dung", label: "Trong ứng dụng" },
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
            href={`${sectionHrefPrefix}#cach-hoat-dong`}
            variant="secondary"
          >
            Khám phá
          </ButtonLink>
        </div>
      </nav>
    </header>
  );
}
