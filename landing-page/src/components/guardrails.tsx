import { SectionHeading } from "./section-heading";
import styles from "./guardrails.module.css";

const guardrails = [
  {
    title: "Người lớn cùng tham gia",
    description:
      "WonderLens được thiết kế để phụ huynh hoặc giáo viên dùng cùng trẻ 6–10 tuổi, không phải công cụ để trẻ tự dùng không giám sát.",
  },
  {
    title: "AI-live luôn có nhãn",
    description:
      "AI-live có thể sai và không thay thế giáo viên, sách giáo khoa hay nội dung đã kiểm chứng.",
  },
  {
    title: "Luồng ảnh được nói thẳng",
    description:
      "Ảnh chụp đi qua proxy tới AI để nhận diện; cutout và bộ sưu tập có thể lưu trên thiết bị.",
  },
  {
    title: "Không tài khoản trẻ, quảng cáo hay tracking",
    description:
      "Landing không có form, cookie hoặc analytics; trải nghiệm được giới thiệu không cần tài khoản trẻ.",
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
            eyebrow="Rào chắn trước khi bắt đầu"
            headingId="guardrails-title"
            title="Giới hạn được nói rõ, không giấu ở cuối trang."
            description="WonderLens là khoảnh khắc cùng học, không phải mạng xã hội hay chương trình khoa học đã kiểm chứng."
          />

          <aside
            className={styles.status}
            aria-label="Trạng thái kiểm định an toàn"
          >
            <p className={styles.statusLabel}>Trạng thái safety</p>
            <p>
              <strong>Chưa hoàn tất.</strong> Runtime kid-safety audit chưa hoàn
              tất trước family beta.
            </p>
            <p className={styles.statusDetail}>
              Prompt và moderation chỉ là một lớp bảo vệ, chưa phải safety pass.
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
