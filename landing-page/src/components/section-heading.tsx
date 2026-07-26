import styles from "./section-heading.module.css";

type SectionHeadingProps = {
  eyebrow: string;
  title: string;
  description?: string;
  align?: "start" | "center";
  headingId?: string;
};

export function SectionHeading({
  eyebrow,
  title,
  description,
  align = "start",
  headingId,
}: SectionHeadingProps) {
  return (
    <div className={`${styles.heading} ${styles[align]}`}>
      <p className={styles.eyebrow}>{eyebrow}</p>
      <h2 id={headingId}>{title}</h2>
      {description ? (
        <p className={styles.description}>{description}</p>
      ) : null}
    </div>
  );
}
