import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ProjectBottomActionsBar extends StatelessWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic> project;
  final bool isFunding;
  final VoidCallback onLogin;
  final VoidCallback onSubmitReport;
  final VoidCallback onInvest;

  const ProjectBottomActionsBar({
    super.key,
    required this.user,
    required this.project,
    required this.isFunding,
    required this.onLogin,
    required this.onSubmitReport,
    required this.onInvest,
  });

  void _showFarmerProposalSheet(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sarmoyachiga Taklif Yuborish',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Investor: ${project['farmerName'] ?? 'Sarmoyador'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ushbu investor uchun o\'z loyiha taklifingizni (hamda kutilayotgan moliyalashtirish shartlarini) yozib yuboring. Investor taklifni rad etishi yoki o\'zgartirish kiritishni taklif qilishi mumkin.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 16),
                // Proposal Title
                TextFormField(
                  controller: titleController,
                  validator: (v) => (v == null || v.isEmpty) ? 'Loyiha nomini kiriting' : null,
                  decoration: InputDecoration(
                    labelText: 'Loyihangiz nomi',
                    hintText: 'Masalan: Naslli qo\'ychilikni kengaytirish loyihasi',
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 14),
                // Proposal Message
                TextFormField(
                  controller: messageController,
                  maxLines: 4,
                  validator: (v) => (v == null || v.isEmpty) ? 'Taklif tafsilotlarini yozing' : null,
                  decoration: InputDecoration(
                    labelText: 'Taklif mazmuni va shartlari',
                    hintText: 'Loyihangiz haqida, kerakli mablag\' va taklif qilayotgan ROI haqida yozing...',
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Taklifingiz investorga muvaffaqiyatli yuborildi! Tez orada siz bilan bog\'lanishadi.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Taklifni Yuborish', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInvestorOffer = project['title']?.toString().startsWith('Sarmoya taklifi:') == true ||
        project['description']?.toString().contains('SARMOYA TAKLIFI') == true;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final paddingVal = EdgeInsets.fromLTRB(16, 12, 16, bottomPadding > 0 ? bottomPadding + 8 : 16);

    if (user == null) {
      return Container(
        padding: paddingVal,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Kirish va taklif yuborish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          ),
        ),
      );
    }

    final role = user!['role'];

    // If this is an Investor capital offer
    if (isInvestorOffer) {
      if (role == 'FARMER') {
        return Container(
          padding: paddingVal,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showFarmerProposalSheet(context),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Taklif yuborish / Bog\'lanish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink(); // other investors or general view has no actions
    }

    // Standard Project actions
    if (role == 'FARMER' && project['farmerId']?.toString() == user!['id']?.toString()) {
      return Container(
        padding: paddingVal,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSubmitReport,
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            label: const Text('Hisobot yuborish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );
    }

    if (role == 'INVESTOR' && isFunding) {
      return Container(
        padding: paddingVal,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onInvest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sarmoya kiritish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
