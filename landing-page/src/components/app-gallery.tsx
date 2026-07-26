import { PhoneFrame } from "./phone-frame";
import { SectionHeading } from "./section-heading";
import styles from "./app-gallery.module.css";

const screens = [
  {
    src: "/images/screens/home.png",
    alt: "Màn hình nhật ký khám phá theo ngày của WonderLens",
    caption: "Nhật ký ngày",
  },
  {
    src: "/images/screens/day-detail.png",
    alt: "Màn hình chi tiết những đồ vật đã khám phá trong ngày",
    caption: "Câu chuyện đã xem",
  },
  {
    src: "/images/screens/collection.png",
    alt: "Màn hình bộ sưu tập đồ vật trong WonderLens",
    caption: "Bộ sưu tập",
  },
  {
    src: "/images/screens/profile.png",
    alt: "Màn hình hồ sơ gia đình và huy hiệu trong WonderLens",
    caption: "Huy hiệu và hồ sơ",
  },
];

export function AppGallery() {
  return (
    <section
      className={styles.section}
      id="ung-dung"
      aria-labelledby="app-gallery-title"
    >
      <div className={styles.inner}>
        <SectionHeading
          eyebrow="Sau mỗi lần khám phá"
          title="Tò mò hôm nay trở thành bộ sưu tập ngày mai."
          description="WonderLens giữ nhịp trải nghiệm ngắn và trực quan: xem lại câu chuyện, mở nhật ký theo ngày và nhận ra những vật liệu trẻ đã gặp."
        />

        <div className={styles.gallery}>
          {screens.map((screen) => (
            <figure className={styles.item} key={screen.src}>
              <PhoneFrame src={screen.src} alt={screen.alt} />
              <figcaption>{screen.caption}</figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
