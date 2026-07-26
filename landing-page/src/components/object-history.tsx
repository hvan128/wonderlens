import Image from "next/image";

import { PhoneFrame } from "./phone-frame";
import { SectionHeading } from "./section-heading";
import styles from "./object-history.module.css";

const historyBeats = [
  {
    time: "Hơn một trăm năm trước",
    title: "Một nhu cầu sạch sẽ hơn",
    description:
      "Ở một số nơi công cộng, nhiều người từng dùng chung cốc uống nước.",
  },
  {
    time: "Dần xuất hiện",
    title: "Chiếc cốc dùng một lần",
    description:
      "Để sạch sẽ và tiện hơn, cốc giấy dùng một lần dần xuất hiện.",
  },
  {
    time: "Ngày nay",
    title: "Một câu hỏi mới sau khi dùng",
    description:
      "Gia đình tiếp tục tìm hiểu cách thu gom và tái chế phù hợp tại nơi mình sống.",
  },
];

export function ObjectHistory() {
  return (
    <section
      className={styles.section}
      id="lich-su"
      aria-labelledby="history-title"
    >
      <div className={styles.inner}>
        <SectionHeading
          eyebrow="Hộ chiếu của một đồ vật"
          headingId="history-title"
          title="Hơn một trăm năm trong một chiếc cốc giấy."
          description="WonderLens kể vì sao một đồ vật xuất hiện trước khi đi vào nguyên liệu và dây chuyền tạo ra nó."
        />

        <div className={styles.story}>
          <div className={styles.visual}>
            <div className={styles.passport}>
              <p className={styles.passportLabel}>Hộ chiếu đồ vật · Cốc giấy</p>
              <Image
                className={styles.cup}
                src="/images/objects/paper-cup-cutout.png"
                alt="Chiếc cốc giấy nhiều màu, vật mẫu của câu chuyện lịch sử"
                width={634}
                height={634}
                sizes="(max-width: 767px) 52vw, 26vw"
              />
              <dl className={styles.material}>
                <div>
                  <dt>Vật liệu chính</dt>
                  <dd>Giấy</dd>
                </div>
                <div>
                  <dt>Chi tiết đáng hỏi</dt>
                  <dd>Lớp màng mỏng bên trong</dd>
                </div>
              </dl>
            </div>

            <PhoneFrame
              className={styles.phone}
              src="/images/screens/timeline.png"
              alt="Màn hình WonderLens kể lịch sử và hành trình của cốc giấy"
            />
          </div>

          <ol className={styles.timeline}>
            {historyBeats.map((beat, index) => (
              <li key={beat.time}>
                <span className={styles.number}>
                  {String(index + 1).padStart(2, "0")}
                </span>
                <div>
                  <p className={styles.time}>{beat.time}</p>
                  <h3>{beat.title}</h3>
                  <p className={styles.description}>{beat.description}</p>
                </div>
              </li>
            ))}
          </ol>
        </div>
      </div>
    </section>
  );
}
