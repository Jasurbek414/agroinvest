import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../services/data/repositories/services_repository.dart';
import '../widgets/about_platform/video_tutorial_card.dart';
import '../widgets/about_platform/legal_document_tile.dart';

class AboutPlatformPage extends StatefulWidget {
  const AboutPlatformPage({super.key});

  @override
  State<AboutPlatformPage> createState() => _AboutPlatformPageState();
}

class _AboutPlatformPageState extends State<AboutPlatformPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = ServicesRepository();
  List<Map<String, dynamic>> _dynamicVideos = [];
  bool _loading = true;

  final List<Map<String, dynamic>> _defaultVideos = [
    {
      'title': 'AgroInvest platformasida sarmoya kiritish yo\'riqnomasi',
      'duration': '5:24',
      'description': 'Investorlar uchun platformada ro\'yxatdan o\'tish, hamyonni to\'ldirish va loyihalarni tanlash bo\'yicha batafsil video-darslik.',
      'views': '1.2K ko\'rishlar',
      'url': 'https://youtube.com',
    },
    {
      'title': 'Fermerlar uchun ariza yuborish va kyc tekshiruvi',
      'duration': '4:12',
      'description': 'Fermer xo\'jaliklari rahbarlari uchun o\'z loyihalarini joylash va pasport ma\'lumotlarini tasdiqlash bo\'yicha qo\'llanma.',
      'views': '850 ko\'rishlar',
      'url': 'https://youtube.com',
    },
    {
      'title': 'Sherikchilik shartnomalari va huquqiy kafolatlar',
      'duration': '6:45',
      'description': 'Platformadagi shartnomalar, kafolatlar va yuridik jihatlar bo\'yicha huquqshunos maslahati.',
      'views': '2.1K ko\'rishlar',
      'url': 'https://youtube.com',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVideos());
  }

  Future<void> _loadVideos() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final role = Provider.of<AuthProvider>(context, listen: false).user?['role']?.toString();
      final audience = (role == 'INVESTOR' || role == 'FARMER') ? role! : 'ALL';
      final banners = await _repository.getBanners(audience);

      final List<Map<String, dynamic>> videoBanners = [];
      for (final b in banners) {
        final url = b.linkUrl?.toLowerCase() ?? '';
        final title = b.title.toLowerCase();
        // Identify videos via link pattern or keywords in title
        if (url.contains('youtube') ||
            url.contains('youtu.be') ||
            url.contains('vimeo') ||
            url.contains('video') ||
            url.endsWith('.mp4') ||
            title.contains('video') ||
            title.contains('darslik') ||
            title.contains('yo\'riqnoma') ||
            title.contains('qo\'llanma')) {
          videoBanners.add({
            'title': b.title,
            'duration': 'Darslik',
            'description': 'Superadmin panelidan yuklangan rasmiy video-qo\'llanma.',
            'views': 'Tafsiya etilgan',
            'url': b.linkUrl ?? 'https://youtube.com',
          });
        }
      }

      if (mounted) {
        setState(() {
          _dynamicVideos = videoBanners.isNotEmpty ? videoBanners : _defaultVideos;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _dynamicVideos = _defaultVideos);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Platforma haqida',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        shape: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Video darsliklar', icon: Icon(Icons.play_circle_fill_rounded, size: 20)),
            Tab(text: 'Huquqiy & Rasmiy', icon: Icon(Icons.gavel_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _buildVideosTab(),
          _buildLegalTab(),
        ],
      ),
    );
  }

  Widget _buildVideosTab() {
    return RefreshIndicator(
      onRefresh: _loadVideos,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: _dynamicVideos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final video = _dynamicVideos[index];
          return VideoTutorialCard(
            video: video,
            onPlay: () => _simulateVideoPlayer(video['title'].toString()),
          );
        },
      ),
    );
  }

  Widget _buildLegalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: const [
        LegalDocumentTile(
          title: 'Platformaning huquqiy asosi',
          icon: Icons.gavel_rounded,
          content: 'AgroInvest platformasining faoliyati O\'zbekiston Respublikasi Fuqarolik Kodeksi, '
              '"Investitsiyalar va investitsiya faoliyati to\'g\'risida"gi hamda "Sherikchilik shartnomalari va hamkorlik to\'g\'risida"gi '
              'amaldagi qonun hujjatlariga to\'liq muvofiq ravishda tashkil etilgan. Barcha investitsion bitimlar elektron shartnomalar orqali yuridik kuchga ega bo\'ladi.',
        ),
        SizedBox(height: 14),
        LegalDocumentTile(
          title: 'Mas\'uliyat cheklanishi',
          icon: Icons.shield_rounded,
          content: 'Platforma faqatgina fermer xo\'jaliklari va sarmoyadorlar o\'rtasida vositachilik vazifasini bajaradi. '
              'Har bir investitsiya shartnomasi loyiha muallifi bo\'lgan fermer hamda investor o\'rtasida tuziladi. Tizim barcha '
              'loyiha egalarining shaxsi va kyc hujjatlarini tekshirsa-da, qishloq xo\'jaligi va ob-havo sharoitlari bilan bog\'liq '
              'kutilmagan fors-major holatlari bo\'yicha yuzaga keladigan tijorat xavflariga sarmoyadorlarning o\'zlari mas\'uldir.',
        ),
        SizedBox(height: 14),
        LegalDocumentTile(
          title: 'Shaxsiy ma\'lumotlar maxfiyligi',
          icon: Icons.lock_outline_rounded,
          content: 'Foydalanuvchilarning shaxsiy ma\'lumotlari, pasport ma\'lumotlari va pul mablag\'lari harakatlar tarixi amaldagi '
              '"Shaxsiy ma\'lumotlar to\'g\'risida"gi Qonunga muvofiq qat\'iy himoyalanadi. Ma\'lumotlar faqatgina KYC (shaxsni tasdiqlash) '
              'va shartnomalarni rasmiylashtirish maqsadlarida yuridik cheklangan miqyosda ishlatiladi, uchinchi shaxslarga berilmaydi.',
        ),
        SizedBox(height: 14),
        LegalDocumentTile(
          title: 'Sherikchilik shartnomasi shartlari',
          icon: Icons.description_outlined,
          content: 'Loyiha tasdiqlanib, pul to\'liq yig\'ilgandan so\'ng, platforma tomonidan avtomatik tarzda fermer va investor '
              'o\'rtasida elektron Sherikchilik shartnomasi tuziladi. Shartnomada foyda ulushini taqsimlash (masalan 70% investorga, '
              '30% fermerga), loyiha davomiyligi, kiritilgan asosiy kapitalning qaytarilishi va hisobotlar chastotasi kabi bandlar '
              'qat\'iy belgilab qo\'yiladi.',
        ),
      ],
    );
  }

  void _simulateVideoPlayer(String videoTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Video ijro etilmoqda', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Simulated Player Screen
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                videoTitle,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Player progress bar
              Slider(
                value: 0.3,
                onChanged: (v) {},
                activeColor: AppColors.primary,
                inactiveColor: Colors.white24,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('01:45', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  Text('05:24', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
