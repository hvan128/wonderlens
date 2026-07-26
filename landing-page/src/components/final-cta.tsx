import Image from "next/image";

import { ButtonLink } from "./button-link";
import styles from "./final-cta.module.css";

const cutouts = [
  {
    src: "/images/objects/paper-cup-cutout.png",
    width: 634,
    height: 634,
    className: styles.cup,
  },
  {
    src: "/images/objects/ball-pen-cutout.png",
    width: 1024,
    height: 1536,
    className: styles.pen,
  },
  {
    src: "/images/objects/ruler-cutout.png",
    width: 1024,
    height: 1536,
    className: styles.ruler,
  },
];

export function FinalCta() {
  return (
    <section className={styles.section} aria-labelledby="final-cta-title">
      <div className={styles.content}>
        <p className={styles.eyebrow}>Một món đồ. Một câu hỏi mới.</p>
        <h2 id="final-cta-title">
          Bắt đầu bằng thứ đang nằm ngay trên bàn.
        </h2>
        <p>
          Xem cách WonderLens đưa chiếc cốc giấy từ camera vào một hành trình
          khoa học có thể cùng nhau trò chuyện.
        </p>
        <ButtonLink href="#cach-hoat-dong">
          Xem lại cách hoạt động
        </ButtonLink>
      </div>
      <div className={styles.objects} aria-hidden="true">
        {cutouts.map((cutout) => (
          <Image
            alt=""
            className={cutout.className}
            height={cutout.height}
            key={cutout.src}
            src={cutout.src}
            width={cutout.width}
            sizes="18vw"
          />
        ))}
      </div>
    </section>
  );
}
