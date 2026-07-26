import type { Metadata } from "next";
import localFont from "next/font/local";

import "@/styles/globals.css";

const baloo = localFont({
  src: "../assets/fonts/Baloo2-ExtraBold.ttf",
  display: "swap",
  variable: "--font-baloo",
  weight: "800",
});

const nunito = localFont({
  src: [
    {
      path: "../assets/fonts/Nunito-Regular.ttf",
      weight: "400",
      style: "normal",
    },
    {
      path: "../assets/fonts/Nunito-Bold.ttf",
      weight: "700",
      style: "normal",
    },
    {
      path: "../assets/fonts/Nunito-ExtraBold.ttf",
      weight: "800",
      style: "normal",
    },
    {
      path: "../assets/fonts/Nunito-Black.ttf",
      weight: "900",
      style: "normal",
    },
  ],
  display: "swap",
  variable: "--font-nunito",
});

const productionHost = process.env.VERCEL_PROJECT_PRODUCTION_URL;

export const metadata: Metadata = {
  metadataBase: new URL(
    productionHost ? `https://${productionHost}` : "http://localhost:3000",
  ),
  title: "WonderLens — Cùng trẻ khám phá khoa học từ đồ vật quanh mình",
  description:
    "WonderLens biến đồ vật quanh nhà thành hành trình STEM tiếng Việt để bố mẹ và trẻ 6–10 tuổi cùng khám phá.",
  applicationName: "WonderLens",
  keywords: [
    "WonderLens",
    "STEM cho trẻ",
    "giáo dục khoa học",
    "ứng dụng gia đình",
  ],
  openGraph: {
    title: "WonderLens — Mọi đồ vật đều có một câu chuyện khoa học",
    description:
      "Chụp một đồ vật và cùng trẻ khám phá hành trình vật liệu bằng hình, giọng kể và bộ sưu tập.",
    locale: "vi_VN",
    type: "website",
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi" className={`${baloo.variable} ${nunito.variable}`}>
      <body>{children}</body>
    </html>
  );
}
