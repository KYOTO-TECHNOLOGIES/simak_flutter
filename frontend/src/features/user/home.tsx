import React from "react";
import Hero from "../../components/userside/heroSection";
import TrustSection from "../../components/userside/trustSection";
import BestsellersSection from "../../components/userside/bestsellersSection";
import HowItWorksSection from "../../components/userside/howitworksSection";
import FreshnessSection from "../../components/userside/freshnessSection";
import OffersSection from "../../components/userside/offersSection";
import ReviewsSection from "../../components/userside/reviewsSection";

const Home: React.FC = () => {
  return (
    <div className="flex flex-col bg-white">
      <Hero />
      <TrustSection />
      <BestsellersSection />
      <HowItWorksSection />
      <FreshnessSection />
      <OffersSection />
      <ReviewsSection />
    </div>
  );
};

export default Home;
