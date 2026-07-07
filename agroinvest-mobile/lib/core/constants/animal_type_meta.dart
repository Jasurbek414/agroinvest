import 'package:flutter/material.dart';
import 'app_colors.dart';

class AnimalTypeMeta {
  final String label;
  final String emoji;
  final IconData icon;
  final Color color;
  const AnimalTypeMeta({required this.label, required this.emoji, required this.icon, required this.color});
}

/// Single source of truth for AnimalType (backend enum) label/emoji/icon/color -
/// mirrors the kAssetTypeMeta pattern. Used by the create-project animal grid,
/// list filter chips, and project cards/detail.
const Map<String, AnimalTypeMeta> kAnimalTypeMeta = {
  'CHICKEN': AnimalTypeMeta(label: 'Tovuq', emoji: '🐔', icon: Icons.egg_alt_rounded, color: AppColors.accent),
  'SHEEP': AnimalTypeMeta(label: "Qo'y", emoji: '🐑', icon: Icons.cruelty_free_rounded, color: Color(0xFF8B5CF6)),
  'CATTLE': AnimalTypeMeta(label: 'Qoramol', emoji: '🐄', icon: Icons.pets_rounded, color: Color(0xFFB45309)),
  'GOAT': AnimalTypeMeta(label: 'Echki', emoji: '🐐', icon: Icons.landscape_rounded, color: Color(0xFF64748B)),
  'HORSE': AnimalTypeMeta(label: 'Ot', emoji: '🐎', icon: Icons.directions_run_rounded, color: Color(0xFF7C3AED)),
  'FISH': AnimalTypeMeta(label: 'Baliq', emoji: '🐟', icon: Icons.water_rounded, color: AppColors.info),
  'OTHER': AnimalTypeMeta(label: 'Boshqa', emoji: '🐾', icon: Icons.category_rounded, color: AppColors.textMuted),
};

AnimalTypeMeta getAnimalTypeMeta(String? animalType) {
  return kAnimalTypeMeta[animalType?.toUpperCase()] ?? kAnimalTypeMeta['OTHER']!;
}
