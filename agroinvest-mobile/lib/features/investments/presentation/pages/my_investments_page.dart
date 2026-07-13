import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../reviews/data/review_repository.dart';
import '../providers/investment_provider.dart';
import '../widgets/portfolio_summary_card.dart';
import '../widgets/investment_filter_tabs.dart';
import '../widgets/investment_card.dart';
import '../../../../core/network/dio_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../projects/presentation/pages/my_projects_page.dart';

class MyInvestmentsPage extends StatefulWidget {
  const MyInvestmentsPage({super.key});

  @override
  State<MyInvestmentsPage> createState() => _MyInvestmentsPageState();
}

class _MyInvestmentsPageState extends State<MyInvestmentsPage> {
  final _reviewRepository = ReviewRepository();
  final _dio = DioClient().dio;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvestmentProvider>(context, listen: false).fetchMyInvestments();
    });
  }

  List<dynamic> _filterInvestments(List<dynamic> list) {
    if (_selectedFilter == 'ALL') return list;
    if (_selectedFilter == 'ACTIVE') {
      return list.where((inv) => inv['status'] == 'ACTIVE').toList();
    }
    if (_selectedFilter == 'PENDING') {
      return list.where((inv) => inv['status'] == 'CONFIRMED' || inv['status'] == 'RESERVED').toList();
    }
    if (_selectedFilter == 'COMPLETED') {
      return list.where((inv) => inv['status'] == 'PAID_OUT' || inv['status'] == 'REFUNDED').toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    if (user != null && user['role'] == 'FARMER') {
      return const MyProjectsPage();
    }

    final provider = Provider.of<InvestmentProvider>(context);
    final visibleInvestments = _filterInvestments(provider.investments);

    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatAmount(double val) {
      return val.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]} ') + ' so\'m';
    }

    return Scaffold(
      drawer: const AppSidebar(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textDark, size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Investitsiyalarim',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textDark, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 24),
            onPressed: () => context.push('/services'),
            tooltip: 'Market',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.loading
          ? const ShimmerList()
          : provider.error != null
              ? ErrorStateWidget(message: provider.error!, onRetry: () => provider.fetchMyInvestments())
              : RefreshIndicator(
                  onRefresh: () => provider.fetchMyInvestments(),
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      // Portfolio Premium Gradient Summary Card (Modular Component)
                      SliverToBoxAdapter(
                        child: PortfolioSummaryCard(
                          investments: provider.investments,
                          formatAmount: formatAmount,
                        ),
                      ),
                      // Horizontal Filter Tabs Segment (Modular Component)
                      SliverToBoxAdapter(
                        child: InvestmentFilterTabs(
                          selectedFilter: _selectedFilter,
                          onFilterChanged: (filterType) => setState(() => _selectedFilter = filterType),
                        ),
                      ),
                      // Investment Cards List (Modular Component)
                      visibleInvestments.isEmpty
                          ? const SliverFillRemaining(
                              hasScrollBody: false,
                              child: EmptyState(
                                icon: Icons.trending_up_rounded,
                                title: 'Sarmoyalar topilmadi',
                                subtitle: 'Tanlangan filtr bo\'yicha sarmoyalar mavjud emas',
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              sliver: SliverList.separated(
                                itemCount: visibleInvestments.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final inv = visibleInvestments[index];
                                  return InvestmentCard(
                                    investment: inv,
                                    formatAmount: formatAmount,
                                    onCancel: () => _confirmCancel(context, provider, inv),
                                    onAddReview: () => _showReviewSheet(inv['id'], inv['projectTitle']?.toString() ?? 'Agro loyiha'),
                                    onViewContract: () => _viewAgreementDetails(inv),
                                    onWithdraw: () => _withdrawResellOffer(context, provider, inv['pendingCoopOfferId']),
                                  );
                                },
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 90)),
                    ],
                  ),
                ),
    );
  }

  void _viewAgreementDetails(Map<String, dynamic> inv) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatAmountLocal(double val) {
      return val.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]} ') + ' UZS';
    }

    showModalBottomSheet(
      context: context,
      // Shell-branch tab: without the root navigator the sheet renders under
      // the floating bottom nav bar.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final amountVal = double.tryParse(inv['amount']?.toString() ?? '0') ?? 0.0;
        final share = double.tryParse(inv['sharePct']?.toString() ?? '0') ?? 0.0;
        final formattedAmount = formatAmountLocal(amountVal);

        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sarmoya Shartnomasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'INVESTITSIYA KELISHUVI',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 12),
                Text(
                  'Shartnoma ID: ${inv['id']}\nLoyiha: ${inv['projectTitle']}\nSana: ${inv['createdAt']?.toString().split('T').first ?? ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 20),
                const Text(
                  '1. SHARTNOMA MAVZUSI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ushbu shartnomaga muvofiq, Investor loyihani rivojlantirish uchun jami $formattedAmount miqdorida sarmoya kiritadi. Loyiha muvaffaqiyatli yakunlangandan so‘ng, investor loyihaning jami ulushidan ${share.toStringAsFixed(4)}% daromad olish huquqiga ega bo‘ladi.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. TOMONLARNING HUQUQ VA MAJBURIYATLARI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fermer olingan mablag‘larni faqatgina belgilangan harajatlar smetasi bo‘yicha ishlatishga, hisobotlarni va veterinar nazorati hujjatlarini o‘z vaqtida taqdim etishga majburdir. Investor loyiha holatini masofaviy kuzatish huquqiga ega.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  '3. FORS-MAJOR VA NIZOLAR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tabiiy ofatlar va kutilmagan hayvon kasalliklari fors-major hisoblanadi. Kelib chiqqan har qanday nizo birinchi navbatda platforma administratorlari yordamida muzokaralar yo‘li bilan, aks holda qonun hujjatlariga muvofiq sudda ko‘rib chiqiladi.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 32),
                if (inv['contractSignedAt'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tasdiqlangan imzo',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Imzolangan sana: ${inv['contractSignedAt'].toString().replaceAll('T', ' ').split('.').first}',
                                style: const TextStyle(fontSize: 11, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _signContract(inv['id']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tasdiqlash va imzolash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadContract(inv['id'], 'word'),
                        icon: const Icon(Icons.description, size: 14),
                        label: const Text('Word (DOC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          side: const BorderSide(color: Colors.blueGrey, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadContract(inv['id'], 'pdf'),
                        icon: const Icon(Icons.picture_as_pdf, size: 14),
                        label: const Text('PDF Yuklash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _downloadContract(String investmentId, String format) async {
    try {
      final token = await SecureStorage.getAccessToken();
      final baseUrl = _dio.options.baseUrl;
      final path = format == 'pdf' 
          ? '/investments/$investmentId/agreement' 
          : '/investments/$investmentId/agreement/word';
      final url = '$baseUrl$path?token=$token';
      
      final launchUri = Uri.parse(url);
      final success = await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shartnomani ochib bo\'lmadi'), backgroundColor: AppColors.danger),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yuklashda xatolik: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _signContract(String investmentId) async {
    final otpController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Shartnomani imzolash', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ushbu shartnomani imzolash uchun telefoningizga yuborilgan tasdiqlash kodini kiriting (Sinov kodi: 1234):',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'SMS kod',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sms_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Kodni kiriting';
                    if (val.trim() != '1234') return 'Kod noto\'g\'ri';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Orqaga'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tasdiqlash'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _dio.post('/investments/$investmentId/sign');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shartnoma muvaffaqiyatli imzolandi!'), backgroundColor: AppColors.primary),
      );
      Provider.of<InvestmentProvider>(context, listen: false).fetchMyInvestments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imzolashda xatolik: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showReviewSheet(String investmentId, String projectTitle) {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Fermerga sharh qoldirish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(projectTitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return WidgetTargetStar(
                        isSelected: starIndex <= selectedRating,
                        onTap: () => setSheetState(() => selectedRating = starIndex),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: commentController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Izoh (ixtiyoriy)',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await _reviewRepository.submitReview(
                          investmentId: investmentId,
                          rating: selectedRating,
                          comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sharhingiz uchun rahmat!'), backgroundColor: AppColors.primary),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Yuborish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmCancel(BuildContext context, InvestmentProvider provider, Map<String, dynamic> inv) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sarmoyani qayta sotish'),
          content: const Text('Loyihaga sarmoya kiritilgandan so\'ng uni bekor qilib pulni to\'g\'ridan-to\'g\'ri qaytarib bo\'lmaydi. Sarmoyangizni qaytarish uchun uni Investitsiya bozorida (P2P bozorda) boshqa investorlarga sotishingiz mumkin.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tushunarli'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final amount = double.tryParse(inv['amount']?.toString() ?? '0') ?? 0.0;
                final share = double.tryParse(inv['sharePct']?.toString() ?? '0') ?? 0.0;
                context.push('/coop-market', extra: {
                  'preFilledType': 'CONTRACT_SALE',
                  'preFilledTitle': '${inv['projectTitle'] ?? 'Loyiha'} shartnomasini qayta sotish',
                  'preFilledAmount': amount.toStringAsFixed(0),
                  'preFilledDescription': 'Ushbu loyihaga kiritilgan sarmoyamni (${share.toStringAsFixed(4)}% loyiha ulushi) qayta sotaman.',
                  'preFilledInvestmentId': inv['id'],
                });
              },
              child: const Text('Bozorga o\'tish', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _withdrawResellOffer(BuildContext context, InvestmentProvider provider, String? offerId) async {
    if (offerId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arizani qaytarib olish'),
        content: const Text('Qayta sotish arizasini bekor qilmoqchimisiz? E\'lon bozordan olib tashlanadi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yo\'q'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ha, bekor qilish', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await _dio.delete('/coop-offers/$offerId');
      if (res.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Qayta sotish arizasi bekor qilindi (qaytarib olindi)')),
          );
        }
        provider.fetchMyInvestments();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xatolik: arizani bekor qilib bo\'lmadi')),
        );
      }
    }
  }
}

class WidgetTargetStar extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const WidgetTargetStar({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
        color: Colors.amber,
        size: 32,
      ),
    );
  }
}
