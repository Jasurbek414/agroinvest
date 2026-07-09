import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/farmer_dashboard.dart';
import '../widgets/guest_dashboard.dart';
import '../widgets/investor_dashboard.dart';

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
      return const GuestDashboard();
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
                DashboardGreeting(name: user['fullName']?.toString() ?? '', role: user['role']?.toString() ?? ''),
                const SizedBox(height: AppSpacing.xl),
                if (dashboard.loading && dashboard.data == null)
                  const ShimmerList(count: 4)
                else if (dashboard.error != null && dashboard.data == null)
                  ErrorStateWidget(message: dashboard.error!, onRetry: _load)
                else if (dashboard.data != null)
                  (dashboard.data!['role'] == 'FARMER')
                      ? FarmerDashboard(data: dashboard.data!)
                      : InvestorDashboard(data: dashboard.data!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
