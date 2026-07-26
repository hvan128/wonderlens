import { SectionHeading } from "./section-heading";
import styles from "./guardrails.module.css";

const guardrails = [
  {
    title: "Bố mẹ cùng con khám phá",
    description:
      "WonderLens được thiết kế cho những phút cùng học: bố mẹ hoặc giáo viên cùng trẻ 6–10 tuổi quan sát, đặt câu hỏi và kiểm tra lại điều thú vị.",
  },
  {
    title: "Nội dung phù hợp lứa tuổi",
    description:
      "Câu chuyện ngắn, gần gũi; WonderLens đặt giới hạn để tránh nội dung nguy hiểm, bạo lực hoặc không phù hợp với trẻ.",
  },
  {
    title: "Biết rõ khi AI tham gia",
    description:
      "Nội dung do AI hỗ trợ luôn có nhãn. AI có thể nhầm và không thay thế giáo viên hay sách đã được kiểm chứng.",
  },
  {
    title: "Riêng tư được nói rõ",
    description:
      "Không cần tài khoản trẻ, không quảng cáo, không theo dõi hành vi. Ảnh chụp được gửi tới dịch vụ AI để nhận diện; ảnh tách nền và bộ sưu tập có thể lưu trên thiết bị.",
  },
];

export function Guardrails() {
  return (
    <section
      className={styles.section}
      id="rao-chan"
      aria-labelledby="guardrails-title"
    >
      <div className={styles.inner}>
        <div className={styles.top}>
          <SectionHeading
            eyebrow="Để bố mẹ an tâm"
            headingId="guardrails-title"
            title="Cùng con khám phá, với những lớp bảo vệ rõ ràng."
            description="WonderLens ưu tiên những câu chuyện ngắn, phù hợp lứa tuổi và giúp bố mẹ biết khi nào AI tham gia."
          />

          <aside className={styles.status} aria-label="Các lớp kiểm tra an toàn">
            <p className={styles.statusLabel}>Các lớp kiểm tra an toàn</p>
            <p>
              <strong>Có các lớp kiểm tra an toàn.</strong> Đồ vật quen thuộc dùng
              câu chuyện đã tuyển chọn; nội dung do AI hỗ trợ được giới hạn theo
              lứa tuổi và luôn có nhãn rõ ràng.
            </p>
            <p className={styles.statusDetail}>
              AI đôi khi có thể nhầm. Bố mẹ hoặc giáo viên hãy cùng trẻ xem, đặt
              câu hỏi và kiểm tra lại khi cần.
            </p>
          </aside>
        </div>

        <ol className={styles.points}>
          {guardrails.map((guardrail, index) => (
            <li key={guardrail.title}>
              <span>{String(index + 1).padStart(2, "0")}</span>
              <div>
                <h3>{guardrail.title}</h3>
                <p>{guardrail.description}</p>
              </div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
