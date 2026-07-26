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
        <p className={styles.eyebrow}>Một món đồ. Hai câu hỏi lớn.</p>
        <h2 id="final-cta-title">
          Nó xuất hiện vì sao? Nó được làm ra thế nào?
        </h2>
        <p>
          Bắt đầu với chiếc cốc giấy, rồi đem cùng cách hỏi ấy tới những đồ vật
          đang nằm ngay trên bàn.
        </p>
        <ButtonLink href="#lich-su">Xem lại lịch sử cốc giấy</ButtonLink>
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
