import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/project_image_gallery.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/projects_provider.dart';
import '../../data/project_repository.dart';
import '../../../investments/data/investment_repository.dart';
import '../widgets/investment_bottom_sheet.dart';
import '../widgets/project_bottom_actions_bar.dart';
import '../widgets/project_financials_section.dart';
import '../widgets/project_header_card.dart';
import '../widgets/project_investors_sheet.dart';
import '../widgets/project_links_section.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final _investmentRepository = InvestmentRepository();
  final _projectRepository = ProjectRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectsProvider>(context, listen: false)
          .fetchProjectById(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark, size: 24),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Loyiha tafsilotlari',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textDark, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.error != null
              ? ErrorStateWidget(
                  message: provider.error!,
                  onRetry: () => Provider.of<ProjectsProvider>(context, listen: false).fetchProjectById(widget.projectId),
                )
              : provider.selectedProject == null
                  ? const Center(child: Text('Loyiha topilmadi'))
                  : _buildDetails(provider.selectedProject!),
    );
  }

  Widget _buildDetails(Map<String, dynamic> p) {
    final raised = double.tryParse(p['raisedAmount'].toString()) ?? 0.0;
    final target = double.tryParse(p['targetAmount'].toString()) ?? 1.0;
    final percent = (raised / target).clamp(0.0, 1.0);

    final isFunding = p['status'] == 'FUNDING' || p['status'] == 'APPROVED';
    final isActiveOrFunding = isFunding || p['status'] == 'ACTIVE';
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final assetType = p['assetType']?.toString() ?? 'OTHER';
    final mediaUrls = (p['mediaUrls'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    
    final isDoc = (String url) {
      final lower = url.toLowerCase();
      return lower.endsWith('.pdf') || lower.endsWith('.docx') || lower.endsWith('.doc') || lower.endsWith('.xls') || lower.endsWith('.xlsx') || lower.endsWith('.txt');
    };
    final images = mediaUrls.where((url) => !isDoc(url)).toList();
    final docs = mediaUrls.where((url) => isDoc(url)).toList();

    final farmerId = p['farmerId']?.toString();
    final expensePolicy = p['expensePolicy']?.toString();
    final projectTitle = p['title']?.toString();
    final isLoggedIn = auth.user != null;
    final isOwnerFarmer = auth.user != null && auth.user!['role'] == 'FARMER' && farmerId == auth.user!['id']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProjectImageCarousel(
                  imageUrls: images,
                  assetType: assetType,
                  height: 220,
                  borderRadius: BorderRadius.zero,
                ),
                Padding(
                  padding: AppSpacing.page,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProjectHeaderCard(
                        project: p,
                        onViewFarmerReviews: farmerId == null
                            ? null
                            : () => context.push(
                                  '/farmers/$farmerId/reviews',
                                  extra: {'farmerName': p['farmerName']},
                                ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      ProjectFinancialsSection(project: p, raised: raised, target: target, percent: percent),
                      const SizedBox(height: AppSpacing.lg),

                      ProjectLinksSection(
                        project: p,
                        isLoggedIn: isLoggedIn,
                        isOwnerFarmer: isOwnerFarmer,
                        isActiveOrFunding: isActiveOrFunding,
                        onViewInvestors: () => showProjectInvestorsSheet(context, _projectRepository, widget.projectId),
                        onViewReports: () => context.push('/projects/${widget.projectId}/reports', extra: {'title': projectTitle}),
                        onViewExpenses: () => context.push('/projects/${widget.projectId}/expenses', extra: {
                          'title': projectTitle,
                          'expensePolicy': expensePolicy,
                          'farmerId': farmerId,
                        }),
                        onViewVetInspections: () => context.push('/projects/${widget.projectId}/vet', extra: {
                          'title': projectTitle,
                          'farmerId': farmerId,
                        }),
                        onViewCoopServices: () => context.push('/projects/${widget.projectId}/services', extra: {'title': projectTitle}),
                        onDailyLog: () => context.push('/projects/${widget.projectId}/daily-log'),
                        onAddExpense: () => context.push('/projects/${widget.projectId}/expenses/add', extra: {'expensePolicy': expensePolicy}),
                      ),
                      if (docs.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          'Loyiha hujjatlari (To\'liq ma\'lumot)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 8),
                        ...docs.map((url) {
                          final filename = url.split('/').last;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.description_rounded, color: AppColors.primary),
                              title: Text(
                                Uri.decodeComponent(filename),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              trailing: const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
                              onTap: () async {
                                try {
                                  final launchUri = Uri.parse(url);
                                  await launchUrl(launchUri, mode: LaunchMode.externalApplication);
                                } catch (_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Xatolik: hujjatni yuklab bo\'lmadi')),
                                  );
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        ProjectBottomActionsBar(
          user: auth.user,
          project: p,
          isFunding: isFunding,
          onLogin: () => context.push('/login'),
          onSubmitReport: () => context.push('/projects/${widget.projectId}/report'),
          onInvest: () => showInvestmentBottomSheet(
            context,
            projectId: widget.projectId,
            project: p,
            investmentRepository: _investmentRepository,
          ),
        ),
      ],
    );
  }
}
