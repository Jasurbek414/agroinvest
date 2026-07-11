import 'package:flutter/material.dart';

class RiskLevelMeta {
  final String label;
  final Color color;
  const RiskLevelMeta({required this.label, required this.color});
}

/// Single source of truth for RiskLevel label/color across the mobile app -
/// used by the project card risk badge and (eventually) the detail page
/// financials section. Previously the list card printed the raw backend enum
/// ("MEDIUM XAVF") with a hardcoded amber regardless of severity.
const Map<String, RiskLevelMeta> kRiskLevelMeta = {
  'LOW': RiskLevelMeta(label: 'Past xavf', color: Color(0xFF16A34A)),
  'MEDIUM': RiskLevelMeta(label: "O'rta xavf", color: Color(0xFFD97706)),
  'HIGH': RiskLevelMeta(label: 'Yuqori xavf', color: Color(0xFFDC2626)),
};

RiskLevelMeta getRiskLevelMeta(String? riskLevel) {
  return kRiskLevelMeta[riskLevel?.toUpperCase()] ?? kRiskLevelMeta['MEDIUM']!;
}
