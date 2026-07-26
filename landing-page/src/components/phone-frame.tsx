import Image from "next/image";

import styles from "./phone-frame.module.css";

type PhoneFrameProps = {
  src: string;
  alt: string;
  preload?: boolean;
  className?: string;
};

export function PhoneFrame({
  src,
  alt,
  preload = false,
  className,
}: PhoneFrameProps) {
  return (
    <div className={`${styles.frame} ${className ?? ""}`}>
      <span className={styles.speaker} aria-hidden="true" />
      <Image
        className={styles.screen}
        src={src}
        alt={alt}
        width={1290}
        height={2796}
        preload={preload}
        sizes="(max-width: 767px) 66vw, (max-width: 1199px) 34vw, 24vw"
      />
    </div>
  );
}
