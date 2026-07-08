import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import uz from './locales/uz.json';

// Skeleton for now (PLATFORM_ROADMAP.md Phase 0.5) - only uz.json exists, so
// this is the mechanism, not full translation coverage (Phase 3 adds ru/en and
// migrates the rest of the app's hardcoded strings onto these keys). Every
// screen written from this point on should use t(...) instead of a literal.
i18n.use(initReactI18next).init({
  resources: {
    uz: { translation: uz },
  },
  lng: 'uz',
  fallbackLng: 'uz',
  interpolation: { escapeValue: false },
});

export default i18n;
