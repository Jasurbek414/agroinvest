import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_type_meta.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

/// Role-aware home tab: KPI tiles + action feed for INVESTOR and FARMER,
/// a welcome/CTA screen for guests.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const _GuestDashboard();
    }

    final dashboard = Provider.of<DashboardProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _load(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Greeting(name: user['fullName']?.toString() ?? '', role: user['role']?.toString() ?? ''),
                const SizedBox(height: AppSpacing.xl),
                if (dashboard.loading && dashboard.data == null)
                  const ShimmerList(count: 4)
                else if (dashboard.error != null && dashboard.data == null)
                  ErrorStateWidget(message: dashboard.error!, onRetry: _load)
                else if (dashboard.data != null)
                  (dashboard.data!['role'] == 'FARMER')
                      ? _FarmerDashboard(data: dashboard.data!)
                      : _InvestorDashboard(data: dashboard.data!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  final String role;
  const _Greeting({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Salom, $firstName 👋', style: AppTypography.h1),
              const SizedBox(height: 4),
              Text(
                role == 'FARMER' ? 'Fermer paneli' : 'Investor paneli',
                style: AppTypography.bodyMuted,
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// INVESTOR
// ---------------------------------------------------------------------------

class _InvestorDashboard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InvestorDashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    final breakdown = Map<String, dynamic>.from(data['assetTypeBreakdown'] ?? {});
    final reports = List<Map<String, dynamic>>.from(
        (data['recentReports'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.45,
          children: [
            StatTile(
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
              label: 'Portfel qiymati',
              value: formatMoneySum(data['portfolioValue']),
              onTap: () => context.push('/investments'),
            ),
            StatTile(
              icon: Icons.trending_up_rounded,
              color: AppColors.info,
              label: 'Kutilayotgan qaytim',
              value: formatMoneySum(data['expectedPayout']),
              sub: 'kafolatlanmagan',
            ),
            StatTile(
              icon: Icons.savings_rounded,
              color: AppColors.accent,
              label: 'Jami daromad',
              value: formatMoneySum(data['totalEarned']),
            ),
            StatTile(
              icon: Icons.workspaces_rounded,
              color: const Color(0xFF8B5CF6),
              label: 'Faol investitsiyalar',
              value: '${data['activeInvestments'] ?? 0} ta',
              onTap: () => context.push('/investments'),
            ),
          ],
        ),
        if (breakdown.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const Text('Portfel taqsimoti', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          _AssetBreakdownCard(breakdown: breakdown),
        ],
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("So'nggi hisobotlar", style: AppTypography.sectionTitle),
            TextButton(
              onPressed: () => context.go('/projects'),
              child: const Text('Loyihalar', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        if (reports.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Center(
              child: Text('Hozircha hisobotlar yo\'q', style: AppTypography.bodyMuted),
            ),
          )
        else
          ...reports.map((r) => _RecentReportTile(report: r)),
      ],
    );
  }
}

/// Labeled breakdown rows (colored dot + label + count) - identity is carried
/// by label text, the dot echoes the platform-wide asset-type entity colors.
class _AssetBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  const _AssetBreakdownCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold<num>(0, (sum, v) => sum + (v as num));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: breakdown.entries.map((entry) {
          final meta = getAssetTypeMeta(entry.key);
          final count = entry.value as num;
          final fraction = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(meta.icon, size: 16, color: meta.color),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(width: 110, child: Text(meta.label, style: AppTypography.bodyMuted)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction.toDouble(),
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(meta.color),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('$count ta', style: AppTypography.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecentReportTile extends StatelessWidget {
  final Map<String, dynamic> report;
  const _RecentReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final isEmergency = report['reportType'] == 'EMERGENCY';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: ListTile(
        onTap: () => context.push('/projects/${report['projectId']}'),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isEmergency ? AppColors.danger : AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isEmergency ? Icons.warning_amber_rounded : Icons.description_rounded,
            color: isEmergency ? AppColors.danger : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(report['projectTitle']?.toString() ?? '', style: AppTypography.body, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${isEmergency ? 'Favqulodda' : 'Hisobot'} · ${formatDateTime(report['createdAt'])}',
          style: AppTypography.caption,
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FARMER
// ---------------------------------------------------------------------------

class _FarmerDashboard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FarmerDashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    final projects = List<Map<String, dynamic>>.from(
        (data['projects'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
    final reportsDue = (data['reportsDue'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reportsDue > 0) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.notification_important_rounded, color: AppColors.accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '$reportsDue ta loyihada hisobot muddati keldi - bugun topshiring!',
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.45,
          children: [
            StatTile(
              icon: Icons.agriculture_rounded,
              color: AppColors.primary,
              label: 'Faol loyihalar',
              value: '${data['activeProjects'] ?? 0} ta',
              sub: '${data['fundingProjects'] ?? 0} ta yig\'ilmoqda',
              onTap: () => context.push('/projects/my'),
            ),
            StatTile(
              icon: Icons.payments_rounded,
              color: AppColors.info,
              label: "Yig'ilgan mablag'",
              value: formatMoneySum(data['totalRaised']),
            ),
            StatTile(
              icon: Icons.receipt_long_rounded,
              color: AppColors.accent,
              label: 'Kutilayotgan harajatlar',
              value: '${data['pendingExpenses'] ?? 0} ta',
            ),
            StatTile(
              icon: Icons.health_and_safety_rounded,
              color: const Color(0xFF8B5CF6),
              label: 'Oxirgi vet ko\'rik',
              value: data['lastVetInspectionAt'] != null ? formatDate(data['lastVetInspectionAt']) : '—',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Loyihalarim', style: AppTypography.sectionTitle),
            TextButton(
              onPressed: () => context.push('/projects/my'),
              child: const Text('Hammasi', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        if (projects.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              children: [
                const Text('Hozircha faol loyihangiz yo\'q', style: AppTypography.bodyMuted),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => context.push('/projects/create'),
                  child: const Text('Loyiha yaratish'),
                ),
              ],
            ),
          )
        else
          ...projects.map((p) => _FarmerProjectTile(project: p)),
      ],
    );
  }
}

class _FarmerProjectTile extends StatelessWidget {
  final Map<String, dynamic> project;
  const _FarmerProjectTile({required this.project});

  @override
  Widget build(BuildContext context) {
    final target = (project['targetAmount'] as num?)?.toDouble() ?? 0;
    final raised = (project['raisedAmount'] as num?)?.toDouble() ?? 0;
    final progress = target > 0 ? (raised / target).clamp(0.0, 1.0) : 0.0;
    final reportDue = project['reportDue'] == true;
    final id = project['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(
          color: reportDue ? AppColors.accent.withOpacity(0.5) : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/projects/$id'),
            child: Row(
              children: [
                Expanded(
                  child: Text(project['title']?.toString() ?? '',
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatMoney(raised)} / ${formatMoney(target)} so\'m',
            style: AppTypography.caption,
          ),
          if (reportDue) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/projects/$id/daily-log'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: AppColors.accent.withOpacity(0.5), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Bugungi hisobotni topshirish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GUEST
// ---------------------------------------------------------------------------

class _GuestDashboard extends StatelessWidget {
  const _GuestDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.spa_rounded, size: 72, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              const Text('AgroInvest', textAlign: TextAlign.center, style: AppTypography.h1),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                "Qishloq xo'jaligiga sarmoya kiriting yoki loyihangizga investor toping",
                textAlign: TextAlign.center,
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Kirish'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => context.push('/register'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radius)),
                ),
                child: const Text("Ro'yxatdan o'tish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => context.go('/projects'),
                child: const Text("Loyihalarni ko'rish →"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
