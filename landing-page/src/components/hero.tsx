import Image from "next/image";

import { ButtonLink } from "./button-link";
import { PhoneFrame } from "./phone-frame";
import styles from "./hero.module.css";

const objectCutouts = [
  {
    src: "/images/objects/ball-pen-cutout.png",
    className: styles.pen,
  },
  {
    src: "/images/objects/ruler-cutout.png",
    className: styles.ruler,
  },
  {
    src: "/images/objects/plastic-bottle-cutout.png",
    className: styles.bottle,
  },
  {
    src: "/images/objects/paper-clip-cutout.png",
    className: styles.clip,
  },
];

export function Hero() {
  return (
    <section className={styles.hero} id="dau-trang" aria-labelledby="hero-title">
      <div className={styles.copy}>
        <p className={styles.eyebrow}>Khám phá STEM từ thế giới thật</p>
        <h1 id="hero-title">
          Mọi đồ vật đều có một câu chuyện khoa học.
        </h1>
        <p className={styles.intro}>
          WonderLens giúp bố mẹ cùng trẻ 6–10 tuổi chụp một món đồ, khám phá vật
          liệu và theo dõi hành trình nó được tạo ra — bằng tiếng Việt, hình ảnh
          và giọng kể.
        </p>
        <div className={styles.actions}>
          <ButtonLink
            href="#cach-hoat-dong"
            ariaLabel="Xem cách WonderLens hoạt động"
          >
            Xem cách WonderLens hoạt động
          </ButtonLink>
          <ButtonLink href="#hanh-trinh" variant="secondary">
            Theo dấu chiếc cốc giấy
          </ButtonLink>
        </div>
      </div>

      <div className={styles.cinema}>
        <div className={styles.aperture} aria-hidden="true">
          <Image
            src="/images/brand/brand-logo.png"
            alt=""
            width={1024}
            height={1024}
            preload
            sizes="(max-width: 767px) 86vw, 46vw"
          />
        </div>
        <PhoneFrame
          className={styles.result}
          src="/images/screens/result.png"
          alt="Màn hình WonderLens nhận diện cốc giấy"
          preload
        />
        <PhoneFrame
          className={styles.timeline}
          src="/images/screens/timeline.png"
          alt="Màn hình WonderLens kể hành trình khoa học của cốc giấy"
        />
        {objectCutouts.map((object) => (
          <Image
            aria-hidden="true"
            alt=""
            className={`${styles.object} ${object.className}`}
            height={1536}
            key={object.src}
            src={object.src}
            width={1024}
            sizes="10vw"
          />
        ))}
      </div>
    </section>
  );
}
