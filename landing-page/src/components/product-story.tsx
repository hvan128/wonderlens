import Image from "next/image";

import { PhoneFrame } from "./phone-frame";
import { SectionHeading } from "./section-heading";
import styles from "./product-story.module.css";

const steps = [
  {
    number: "01",
    title: "Chụp một đồ vật thật",
    description:
      "Bố mẹ cùng trẻ chọn một món đồ quen thuộc quanh nhà và đưa camera tới gần.",
  },
  {
    number: "02",
    title: "Nhận diện và tách vật khỏi nền",
    description:
      "WonderLens làm nổi bật món đồ rồi xác định vật liệu để bắt đầu câu chuyện.",
  },
  {
    number: "03",
    title: "Theo hành trình STEM bằng tiếng Việt",
    description:
      "Mỗi chặng dùng hình minh hoạ, câu chữ ngắn và giọng kể để hai thế hệ cùng trao đổi.",
  },
  {
    number: "04",
    title: "Lưu khám phá trên thiết bị",
    description:
      "Đồ vật đã xem trở thành một phần của nhật ký và bộ sưu tập gia đình.",
  },
];

export function ProductStory() {
  return (
    <section
      className={styles.section}
      id="cach-hoat-dong"
      aria-labelledby="product-story-title"
    >
      <div className={styles.inner}>
        <SectionHeading
          eyebrow="Một câu hỏi. Bốn nhịp khám phá."
          headingId="product-story-title"
          title="Từ chiếc camera đến câu chuyện vật liệu."
          description="WonderLens biến khoảnh khắc “món đồ này từ đâu ra?” thành một hoạt động ngắn để bố mẹ và trẻ làm cùng nhau."
        />

        <div className={styles.storyGrid}>
          <div className={styles.scene}>
            <Image
              className={styles.sceneImage}
              src="/images/journey/onboarding-scene.jpg"
              alt="Cốc giấy nhiều màu trên bàn, vật mẫu để bắt đầu khám phá"
              width={1024}
              height={1536}
              sizes="(max-width: 767px) 90vw, 42vw"
            />
            <Image
              aria-hidden="true"
              className={styles.cutout}
              src="/images/objects/paper-cup-cutout.png"
              alt=""
              width={634}
              height={634}
              sizes="22vw"
            />
            <p className={styles.sceneCaption}>
              Chọn một món đồ quen thuộc. Câu chuyện bắt đầu ngay từ đó.
            </p>
          </div>

          <ol className={styles.steps}>
            {steps.map((step) => (
              <li key={step.number}>
                <span>{step.number}</span>
                <div>
                  <h3>{step.title}</h3>
                  <p>{step.description}</p>
                </div>
              </li>
            ))}
          </ol>
        </div>

        <div className={styles.deviceStory}>
          <PhoneFrame
            className={styles.result}
            src="/images/screens/result.png"
            alt="Màn hình kết quả nhận diện cốc giấy trong WonderLens"
          />
          <div className={styles.deviceCopy}>
            <p className={styles.deviceEyebrow}>Thấy vật thật trước</p>
            <h3>Không bắt trẻ nhập từ khoá hay đọc một bài dài.</h3>
            <p>
              Món đồ vừa chụp trở thành nhân vật chính. Từ đó, trẻ đi tiếp qua
              những chặng cụ thể về nguyên liệu và cách sản xuất.
            </p>
          </div>
          <PhoneFrame
            className={styles.timeline}
            src="/images/screens/timeline.png"
            alt="Màn hình hành trình cốc giấy có hình và lời kể tiếng Việt"
          />
        </div>
      </div>
    </section>
  );
}
