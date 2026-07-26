import type { ReactNode } from "react";

import styles from "./button-link.module.css";

type ButtonLinkProps = {
  href: string;
  children: ReactNode;
  variant?: "primary" | "secondary";
  ariaLabel?: string;
};

export function ButtonLink({
  href,
  children,
  variant = "primary",
  ariaLabel,
}: ButtonLinkProps) {
  return (
    <a
      className={`${styles.button} ${styles[variant]}`}
      href={href}
      aria-label={ariaLabel}
    >
      {children}
    </a>
  );
}
