import { Beef, Wheat, Warehouse, Egg, Hexagon, Package } from 'lucide-react';

// Single source of truth for AssetType label/icon/color across the web app -
// mirrors the same scheme used in the mobile app's asset_type_meta.dart so the
// platform reads as one visual system regardless of which client you're on.
// Light/dark hex pairs are both validated with the dataviz skill's palette
// checker (CVD separation, lightness band, chroma floor) for their respective
// chart surfaces - see AssetTypeBarChart.
export const ASSET_TYPE_META = {
  LIVESTOCK: { label: 'Chorvachilik', icon: Beef, color: '#b45309', colorDark: '#c2650a' },
  CROP: { label: 'Dehqonchilik', icon: Wheat, color: '#15803d', colorDark: '#16a34a' },
  GREENHOUSE: { label: 'Issiqxona', icon: Warehouse, color: '#0369a1', colorDark: '#0284c7' },
  POULTRY: { label: 'Parrandachilik', icon: Egg, color: '#ca8a04', colorDark: '#a16207' },
  BEEKEEPING: { label: 'Asalarichilik', icon: Hexagon, color: '#7c3aed', colorDark: '#8b6cf1' },
  OTHER: { label: 'Boshqa', icon: Package, color: '#be185d', colorDark: '#db2777' },
};

export const getAssetTypeMeta = (assetType) => ASSET_TYPE_META[assetType] || ASSET_TYPE_META.OTHER;
