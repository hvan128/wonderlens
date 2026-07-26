import { SectionHeading } from "./section-heading";
import styles from "./trust-section.module.css";

const trustPoints = [
  {
    title: "Không tài khoản trẻ",
    description:
      "Trẻ không cần tạo hồ sơ công khai hay cung cấp thông tin đăng nhập.",
  },
  {
    title: "Không quảng cáo, không tracking",
    description:
      "Landing page và trải nghiệm được giới thiệu ở đây không gắn analytics hay mạng quảng cáo.",
  },
  {
    title: "Dữ liệu được mô tả thẳng thắn",
    description:
      "Ảnh chụp được gửi qua proxy tới AI để nhận diện; cutout và bộ sưu tập có thể lưu trên thiết bị.",
  },
  {
    title: "Nội dung AI-live có nhãn",
    description:
      "Hành trình do AI hỗ trợ có thể sai và không thay thế giáo viên, sách giáo khoa hay nội dung đã kiểm chứng.",
  },
];

export function TrustSection() {
  return (
    <section className={styles.section} aria-labelledby="trust-title">
      <div className={styles.inner}>
        <SectionHeading
          eyebrow="Dành cho trải nghiệm cùng người lớn"
          headingId="trust-title"
          title="Để gia đình biết điều gì đang xảy ra."
          description="WonderLens được định hướng như một khoảnh khắc bố mẹ và trẻ cùng học, không phải mạng xã hội hay nơi thay thế chương trình khoa học."
        />

        <ul className={styles.points}>
          {trustPoints.map((point) => (
            <li key={point.title}>
              <h3>{point.title}</h3>
              <p>{point.description}</p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
