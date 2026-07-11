import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPage();
}

class _NotificationSettingsPage extends State<NotificationSettingsPage> {
  bool _smsNewProjects = true;
  bool _smsNewInvestments = true;
  bool _pushMilestoneReports = true;
  bool _emailSystemNews = false;
  bool _smsBalanceChanges = true;
  bool _saving = false;

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sozlamalar saqlandi!'), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bildirishnoma Sozlamalari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Kanal sozlamalari',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 16),
                      _buildSwitchTile(
                        title: 'Yangi loyihalar (SMS)',
                        subtitle: 'Platformaga yangi investitsiya loyihasi qo\'shilganda SMS xabar olish',
                        value: _smsNewProjects,
                        onChanged: (val) => setState(() => _smsNewProjects = val),
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        title: 'Yangi sarmoyalar (SMS)',
                        subtitle: 'Loyihangizga investor sarmoya kiritganda SMS xabar olish',
                        value: _smsNewInvestments,
                        onChanged: (val) => setState(() => _smsNewInvestments = val),
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        title: 'Bosqichlar hisobotlari (Push)',
                        subtitle: 'Loyiha bosqichlari (milestones) yangilanganda push-bildirishnoma olish',
                        value: _pushMilestoneReports,
                        onChanged: (val) => setState(() => _pushMilestoneReports = val),
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        title: 'Tizim yangiliklari (Email)',
                        subtitle: 'Platforma yangiliklari va oylik hisobotlarni elektron pochtaga olish',
                        value: _emailSystemNews,
                        onChanged: (val) => setState(() => _emailSystemNews = val),
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        title: 'Balans o\'zgarishi (SMS)',
                        subtitle: 'Hamyon hisobi to\'ldirilganda yoki yechilganda tezkor SMS olish',
                        value: _smsBalanceChanges,
                        onChanged: (val) => setState(() => _smsBalanceChanges = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
