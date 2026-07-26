import Image from "next/image";

import { SectionHeading } from "./section-heading";
import styles from "./journey-gallery.module.css";

const stages = [
  {
    src: "/images/journey/paper-cup-stage-0.png",
    title: "Từ rừng trồng xanh",
    description: "Sợi gỗ là điểm khởi đầu của câu chuyện chiếc cốc.",
    alt: "Minh hoạ rừng trồng, nơi lấy sợi gỗ làm giấy",
  },
  {
    src: "/images/journey/paper-cup-stage-1.png",
    title: "Khuấy thành bột giấy",
    description: "Gỗ được băm nhỏ, trộn với nước rồi xử lý cho mềm.",
    alt: "Minh hoạ gỗ được khuấy với nước để tạo bột giấy",
  },
  {
    src: "/images/journey/paper-cup-stage-2.png",
    title: "Cán thành cuộn giấy",
    description: "Bột giấy được trải mỏng, ép bớt nước và sấy khô.",
    alt: "Minh hoạ máy cán bột giấy thành cuộn giấy lớn",
  },
  {
    src: "/images/journey/paper-cup-stage-3.png",
    title: "Gập thành chiếc cốc",
    description: "Giấy được cắt, cuộn và thêm lớp màng mỏng bên trong.",
    alt: "Minh hoạ giấy được tạo hình thành chiếc cốc",
  },
];

export function JourneyGallery() {
  return (
    <section
      className={styles.section}
      id="hanh-trinh"
      aria-labelledby="journey-title"
    >
      <div className={styles.inner}>
        <SectionHeading
          align="center"
          eyebrow="Một hành trình thật trong WonderLens"
          headingId="journey-title"
          title="Chiếc cốc giấy bắt đầu từ đâu?"
          description="Bốn khung hình ngắn giúp trẻ nối món đồ trong tay với nguyên liệu, máy móc và những lựa chọn sau khi dùng."
        />

        <div className={styles.gallery}>
          {stages.map((stage, index) => (
            <figure className={styles.stage} key={stage.src}>
              <div className={styles.media}>
                <Image
                  src={stage.src}
                  alt={stage.alt}
                  width={1024}
                  height={1024}
                  sizes={
                    index === 0
                      ? "(max-width: 767px) 90vw, 52vw"
                      : "(max-width: 767px) 90vw, 34vw"
                  }
                />
              </div>
              <figcaption>
                <span>{String(index + 1).padStart(2, "0")}</span>
                <div>
                  <h3>{stage.title}</h3>
                  <p>{stage.description}</p>
                </div>
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
