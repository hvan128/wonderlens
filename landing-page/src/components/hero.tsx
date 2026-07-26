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
        <p className={styles.eyebrow}>
          Lịch sử và khoa học từ thế giới thật
        </p>
        <h1 id="hero-title">Mỗi đồ vật đều có một lịch sử để kể.</h1>
        <p className={styles.intro}>
          WonderLens giúp bố mẹ cùng trẻ 6–10 tuổi chụp một món đồ, tìm hiểu vì
          sao nó xuất hiện, vật liệu từ đâu và từng bước được làm ra — bằng tiếng
          Việt, hình ảnh và giọng kể.
        </p>
        <div className={styles.actions}>
          <ButtonLink
            href="#lich-su"
            ariaLabel="Xem lịch sử cốc giấy"
          >
            Xem lịch sử cốc giấy
          </ButtonLink>
          <ButtonLink href="#cach-lam-ra" variant="secondary">
            Theo cách chiếc cốc được làm ra
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
