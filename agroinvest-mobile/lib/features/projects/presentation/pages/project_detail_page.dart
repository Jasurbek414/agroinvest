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
      appBar: AppBar(title: const Text('Loyiha tafsilotlari')),
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
    final farmerId = p['farmerId']?.toString();
    final expensePolicy = p['expensePolicy']?.toString();
    final projectTitle = p['title']?.toString();
    final isLoggedIn = auth.user != null;
    final isOwnerFarmer = auth.user != null && auth.user!['role'] == 'FARMER' && farmerId == auth.user!['id']?.toString();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProjectImageCarousel(
                  imageUrls: mediaUrls,
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
                        onDailyLog: () => context.push('/projects/${widget.projectId}/daily-log'),
                        onAddExpense: () => context.push('/projects/${widget.projectId}/expenses/add', extra: {'expensePolicy': expensePolicy}),
                      ),
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
