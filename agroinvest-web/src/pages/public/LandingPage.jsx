import React from 'react';
import HeroSection from '../../components/landing/HeroSection';
import PublicStatsBar from '../../components/landing/PublicStatsBar';
import HowItWorksSection from '../../components/landing/HowItWorksSection';
import FeaturedProjectsSection from '../../components/landing/FeaturedProjectsSection';
import TrustSection from '../../components/landing/TrustSection';
import LandingFooter from '../../components/landing/LandingFooter';

const LandingPage = () => {
  return (
    <div className="min-h-screen bg-white dark:bg-slate-950">
      <HeroSection />
      <PublicStatsBar />
      <HowItWorksSection />
      <FeaturedProjectsSection />
      <TrustSection />
      <LandingFooter />
    </div>
  );
};

export default LandingPage;
