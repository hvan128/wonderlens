import { AppGallery } from "@/components/app-gallery";
import { FinalCta } from "@/components/final-cta";
import { Hero } from "@/components/hero";
import { JourneyGallery } from "@/components/journey-gallery";
import { ProductStory } from "@/components/product-story";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { TrustSection } from "@/components/trust-section";

export default function Home() {
  return (
    <>
      <a className="skip-link" href="#noi-dung-chinh">
        Bỏ qua điều hướng
      </a>
      <SiteHeader />
      <main id="noi-dung-chinh" tabIndex={-1}>
        <Hero />
        <ProductStory />
        <JourneyGallery />
        <AppGallery />
        <TrustSection />
        <FinalCta />
      </main>
      <SiteFooter />
    </>
  );
}
