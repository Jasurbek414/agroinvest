import 'package:flutter/material.dart';
import 'package:agroinvest_mobile/core/utils/format.dart';
import 'package:url_launcher/url_launcher.dart';

class CoopOfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final bool isExpanded;
  final VoidCallback onTap;

  const CoopOfferCard({
    super.key,
    required this.offer,
    required this.isExpanded,
    required this.onTap,
  });

  String _getOfferTypeLabel(String? type) {
    switch (type) {
      case 'CONTRACT_SALE': return 'Tayyor shartnoma savdosi';
      case 'INVESTOR_OFFER': return 'Investor sarmoya taklifi';
      case 'BUSINESS_PLAN': return 'Biznes reja / Loyiha';
      default: return type ?? 'Boshqa';
    }
  }

  Color _getOfferTypeColor(String? type) {
    switch (type) {
      case 'CONTRACT_SALE': return const Color(0xFF3B82F6);
      case 'INVESTOR_OFFER': return const Color(0xFF10B981);
      case 'BUSINESS_PLAN': return const Color(0xFF8B5CF6);
      default: return Colors.grey;
    }
  }

  IconData _getOfferTypeIcon(String? type) {
    switch (type) {
      case 'CONTRACT_SALE': return Icons.assignment_turned_in_rounded;
      case 'INVESTOR_OFFER': return Icons.monetization_on_rounded;
      case 'BUSINESS_PLAN': return Icons.business_center_rounded;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = offer['type']?.toString();
    final accentColor = _getOfferTypeColor(type);
    
    // Safely parse double or integer amount
    final amountVal = offer['amount'];
    final formattedAmount = formatMoneySum(amountVal);

    // Safely format date
    final dateRaw = offer['createdAt']?.toString();
    final dateText = dateRaw != null && dateRaw.length >= 10
        ? dateRaw.substring(0, 10)
        : dateRaw ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isExpanded ? accentColor.withOpacity(0.3) : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getOfferTypeIcon(type),
                            size: 13,
                            color: accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getOfferTypeLabel(type),
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      dateText,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  offer['title']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  offer['description']?.toString() ?? '',
                  maxLines: isExpanded ? 20 : 3,
                  overflow: isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),

                // Expand/Collapse Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      isExpanded ? 'Yopish' : 'Batafsil o\'qish',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: accentColor,
                    ),
                  ],
                ),

                const Divider(height: 24, color: Color(0xFFF1F5F9), thickness: 1.5),

                // Footer Sum + Phone action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MOLIYAVIY QIYMАТ',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedAmount,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: accentColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF1E293B),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final phone = offer['contactPhone']?.toString();
                        if (phone != null && phone.isNotEmpty) {
                          final launchUri = Uri(
                            scheme: 'tel',
                            path: phone,
                          );
                          await launchUrl(launchUri);
                        }
                      },
                      icon: Icon(Icons.phone_in_talk_rounded, size: 14, color: accentColor),
                      label: Text(
                        offer['contactPhone']?.toString() ?? 'Bog\'lanish',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
