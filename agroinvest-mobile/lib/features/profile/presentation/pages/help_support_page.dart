import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPage();
}

class _HelpSupportPage extends State<HelpSupportPage> {
  final _feedbackController = TextEditingController();
  String _ticketCategory = 'Moliyaviy muammo';
  bool _sending = false;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'Sarmoyalarning xavfsizligi qanday kafolatlanadi?',
      'a': 'Platformada ro\'yxatdan o\'tgan har bir fermer to\'liq KYC tekshiruvidan o\'tadi. Hayvonlar sug\'urta qilinadi va barcha investitsiya jarayoni elektron shartnomalar yordamida qonuniy rasmiylashtiriladi.'
    },
    {
      'q': 'Hamyon hisobini qanday to\'ldirish mumkin?',
      'a': 'Profil menyusidagi "Mening hamyonim" bo\'limiga o\'tib, "To\'ldirish" tugmasini bosing. Sizga ko\'rsatilgan bank hisob raqamlariga to\'lovni amalga oshirib, kvitansiya rasmini yuklasangiz, tez orada hisobingiz to\'ldiriladi.'
    },
    {
      'q': 'Sof daromad qachon va qayerga qaytariladi?',
      'a': 'Loyiha yakunlangach, sotilgan chorva yoki hosildan olingan daromad sizning platformadagi hamyoningizga kelib tushadi. Uni istalgan vaqtda plastik kartangizga yechib olishingiz mumkin.'
    },
    {
      'q': 'Fermerlar qanchalik tez-tez hisobot yuboradi?',
      'a': 'Loyiha rejasida belgilangan har bir bosqich (milestone) yakunlanganda, fermer majburiy ravishda bajarilgan ishlar va veterinar tekshiruvlari haqida foto/video hisobotlarni taqdim etishi shart.'
    },
  ];

  Future<void> _submitTicket() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xabar matnini yozing'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _sending = false;
      _feedbackController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Murojaatingiz muvaffaqiyatli yuborildi! Tez orada javob beramiz.'), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Qo\'llab-quvvatlash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: _sending
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Quick contact buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildContactCard(
                        icon: Icons.telegram_rounded,
                        title: 'Telegram-bot',
                        subtitle: '@agroinvest_bot',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Telegram bot havolasi ochilmoqda...')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildContactCard(
                        icon: Icons.phone_in_talk_rounded,
                        title: 'Call-Center',
                        subtitle: '+998 71 123 45 67',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Telefon raqam terilmoqda...')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // FAQ section
                const Row(
                  children: [
                    Icon(Icons.question_answer_outlined, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Tez-tez beriladigan savollar',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _faqs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final faq = _faqs[index];
                      return ExpansionTile(
                        title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            faq['a']!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Message ticket section
                const Row(
                  children: [
                    Icon(Icons.mail_outline_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Murojaat yuborish',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _ticketCategory,
                        decoration: const InputDecoration(labelText: 'Mavzu', border: OutlineInputBorder()),
                        items: ['Moliyaviy muammo', 'Texnik nosozlik', 'Hamkorlik taklifi', 'Boshqa']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) => setState(() => _ticketCategory = val ?? _ticketCategory),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _feedbackController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Murojaatingiz tafsilotlari...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Yuborish', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
