import Image from "next/image";

import styles from "./brand.module.css";

type BrandProps = {
  compact?: boolean;
};

export function Brand({ compact = false }: BrandProps) {
  return (
    <span className={`${styles.brand} ${compact ? styles.compact : ""}`}>
      <Image
        className={styles.mark}
        src="/images/brand/brand-logo.png"
        alt=""
        width={1024}
        height={1024}
        sizes="48px"
        aria-hidden="true"
      />
      <span className={styles.wordmark}>WonderLens</span>
    </span>
  );
}
