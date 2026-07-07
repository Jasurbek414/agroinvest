import 'package:flutter/material.dart';
import 'app_colors.dart';

class AssetTypeMeta {
  final String label;
  final IconData icon;
  final Color color;
  const AssetTypeMeta({required this.label, required this.icon, required this.color});
}

/// Single source of truth for AssetType label/icon/color across the mobile
/// app - used by the projects list filter chips, project cards, and project
/// detail header. Previously `getAssetLabel()` was duplicated (with slightly
/// different spelling - "Asalachilik" vs "Asalarichilik") in both
/// projects_list_page.dart and project_detail_page.dart, and neither gave
/// each asset type its own icon/color. Mirrors the same scheme used on the
/// web admin dashboard's AssetTypeBarChart so the platform reads as one
/// visual system regardless of client.
const Map<String, AssetTypeMeta> kAssetTypeMeta = {
  'LIVESTOCK': AssetTypeMeta(label: 'Chorvachilik', icon: Icons.cruelty_free_rounded, color: Color(0xFFB45309)),
  'CROP': AssetTypeMeta(label: 'Dehqonchilik', icon: Icons.grass_rounded, color: AppColors.primary),
  'GREENHOUSE': AssetTypeMeta(label: 'Issiqxona', icon: Icons.thermostat_rounded, color: Color(0xFF0EA5E9)),
  'POULTRY': AssetTypeMeta(label: 'Parrandachilik', icon: Icons.egg_rounded, color: AppColors.accent),
  'BEEKEEPING': AssetTypeMeta(label: 'Asalarichilik', icon: Icons.hive_rounded, color: Color(0xFFCA8A04)),
  'OTHER': AssetTypeMeta(label: 'Boshqa', icon: Icons.category_rounded, color: AppColors.textMuted),
};

AssetTypeMeta getAssetTypeMeta(String? assetType) {
  return kAssetTypeMeta[assetType?.toUpperCase()] ?? kAssetTypeMeta['OTHER']!;
}
