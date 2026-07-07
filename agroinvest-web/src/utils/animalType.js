import { Bird, Fish, PawPrint, Mountain, Package } from 'lucide-react';

// Structured animal sub-type within LIVESTOCK/POULTRY projects - mirrors the
// mobile app's animal_type_meta.dart. Light/dark hex pairs chosen distinct
// from ASSET_TYPE_META's palette so the two badges never collide visually.
export const ANIMAL_TYPE_META = {
  CHICKEN: { label: 'Tovuq', icon: Bird, color: '#a16207', colorDark: '#ca8a04' },
  SHEEP: { label: "Qo'y", icon: PawPrint, color: '#7c3aed', colorDark: '#8b6cf1' },
  CATTLE: { label: 'Qoramol', icon: PawPrint, color: '#b45309', colorDark: '#c2650a' },
  GOAT: { label: 'Echki', icon: Mountain, color: '#475569', colorDark: '#64748b' },
  HORSE: { label: 'Ot', icon: PawPrint, color: '#6d28d9', colorDark: '#7c3aed' },
  FISH: { label: 'Baliq', icon: Fish, color: '#0369a1', colorDark: '#0284c7' },
  OTHER: { label: 'Boshqa', icon: Package, color: '#64748b', colorDark: '#94a3b8' },
};

export const getAnimalTypeMeta = (animalType) => ANIMAL_TYPE_META[animalType] || ANIMAL_TYPE_META.OTHER;
