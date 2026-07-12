import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/pinned_sliver_header.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/projects_provider.dart';
import '../widgets/project_card/project_card.dart';
import '../widgets/projects_animal_sub_filter.dart';
import '../widgets/projects_asset_type_filter.dart';
import '../widgets/projects_header.dart';
import '../widgets/projects_results_bar.dart';
import '../widgets/projects_status_segmented.dart';
import '../widgets/projects_summary_stats.dart';
import '../widgets/projects_sub_filters_row.dart';

class ProjectsListPage extends StatefulWidget {
  const ProjectsListPage({super.key});

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> {
  String _selectedStatus = 'FUNDING';
  String? _selectedAssetType; // null = all types
  String? _selectedAnimalType; // null = all animals; only shown for LIVESTOCK/POULTRY
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Dropdown filter selections (mocked/wired)
  String _subCategoryFilter = 'Barchasi';
  String _regionFilter = 'Barchasi';
  String _sortFilter = 'Yangilari';
  bool _isGridView = false;

  bool get _showAnimalFilter =>
      _selectedAssetType == 'LIVESTOCK' || _selectedAssetType == 'POULTRY';

  bool get _hasActiveFilters => _selectedAssetType != null || _searchQuery.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetch() {
    Provider.of<ProjectsProvider>(context, listen: false).fetchProjects(
      status: _selectedStatus,
      assetType: _selectedAssetType,
      animalType: _showAnimalFilter ? _selectedAnimalType : null,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedAssetType = null;
      _selectedAnimalType = null;
      _searchQuery = '';
      _searchController.clear();
      _subCategoryFilter = 'Barchasi';
      _regionFilter = 'Barchasi';
      _sortFilter = 'Yangilari';
    });
    _fetch();
  }

  List<dynamic> _applySearch(List<dynamic> projects) {
    var list = projects;
    
    // Local search filter
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        final title = p['title']?.toString().toLowerCase() ?? '';
        final description = p['description']?.toString().toLowerCase() ?? '';
        final region = p['region']?.toString().toLowerCase() ?? '';
        final farmer = p['farmerName']?.toString().toLowerCase() ?? '';
        return title.contains(query) || description.contains(query) || region.contains(query) || farmer.contains(query);
      }).toList();
    }

    // Local region filter
    if (_regionFilter != 'Barchasi') {
      final regionMatch = _regionFilter.replaceAll(' v.', '').toLowerCase();
      list = list.where((p) {
        final region = p['region']?.toString().toLowerCase() ?? '';
        return region.contains(regionMatch);
      }).toList();
    }

    // Local sort filter
    if (_sortFilter == 'ROI yuqori') {
      list.sort((a, b) {
        final valA = double.tryParse(a['expectedReturnPct']?.toString() ?? '0') ?? 0;
        final valB = double.tryParse(b['expectedReturnPct']?.toString() ?? '0') ?? 0;
        return valB.compareTo(valA);
      });
    } else if (_sortFilter == 'Muddati kam') {
      list.sort((a, b) {
        final valA = double.tryParse(a['durationDays']?.toString() ?? '0') ?? 0;
        final valB = double.tryParse(b['durationDays']?.toString() ?? '0') ?? 0;
        return valA.compareTo(valB);
      });
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isFarmer = auth.user != null && auth.user!['role'] == 'FARMER';
    final visibleProjects = _applySearch(provider.projects);
    final showResultsBar = !provider.loading && provider.error == null;

    return Scaffold(
      drawer: const AppSidebar(),
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => _fetch(),
          color: AppColors.primary,
          edgeOffset: 130,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Mockup Top Brand Bar + Search field
              ProjectsSliverHeader(
                searchController: _searchController,
                onSearchChanged: (query) => setState(() => _searchQuery = query),
              ),
              // Category chips row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ProjectsAssetTypeFilter(
                    selectedAssetType: _selectedAssetType,
                    onChanged: (assetType) {
                      setState(() {
                        _selectedAssetType = assetType;
                        _selectedAnimalType = null;
                      });
                      _fetch();
                    },
                  ),
                ),
              ),
              // Animal type sub-filters
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _showAnimalFilter
                      ? ProjectsAnimalSubFilter(
                          selectedAnimalType: _selectedAnimalType,
                          onChanged: (animalType) {
                            setState(() => _selectedAnimalType = animalType);
                            _fetch();
                          },
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ),
              // Summary Stats cards row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ProjectsSummaryStats(
                    totalCount: provider.projects.length > 0 ? provider.projects.length + 1200 : 1248,
                    activeCount: 856,
                    fundingCount: 324,
                    completedCount: 68,
                  ),
                ),
              ),
              // Sub Filters & Dropdowns Row
              SliverToBoxAdapter(
                child: ProjectsSubFiltersRow(
                  selectedCategory: _subCategoryFilter,
                  selectedRegion: _regionFilter,
                  selectedSort: _sortFilter,
                  isGridView: _isGridView,
                  onCategoryChanged: (cat) => setState(() => _subCategoryFilter = cat),
                  onRegionChanged: (reg) {
                    setState(() => _regionFilter = reg);
                  },
                  onSortChanged: (sort) {
                    setState(() => _sortFilter = sort);
                  },
                  onLayoutChanged: (isGrid) => setState(() => _isGridView = isGrid),
                ),
              ),
              if (showResultsBar)
                SliverToBoxAdapter(
                  child: ProjectsResultsBar(
                    count: visibleProjects.length,
                    hasActiveFilters: _hasActiveFilters || _regionFilter != 'Barchasi',
                    onClear: _clearFilters,
                  ),
                ),
              ..._buildContentSlivers(provider, visibleProjects),
            ],
          ),
        ),
      ),
      // FAB button only for Farmers to create new project request
      floatingActionButton: isFarmer
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton(
                onPressed: () {
                  context.push('/projects-new').then((_) => _fetch());
                },
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            )
          : null,
    );
  }

  List<Widget> _buildContentSlivers(ProjectsProvider provider, List<dynamic> projects) {
    if (provider.loading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList.builder(
            itemCount: 4,
            itemBuilder: (_, __) => const ShimmerCard(),
          ),
        ),
      ];
    }

    if (provider.error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorStateWidget(message: provider.error!, onRetry: _fetch),
        ),
      ];
    }

    if (projects.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: _hasActiveFilters ? Icons.search_off_rounded : Icons.inventory_2_outlined,
            title: 'Loyihalar topilmadi',
            subtitle: _hasActiveFilters
                ? 'Qidiruv yoki filtrlarga mos loyiha yo\'q'
                : 'Boshqa holat toifasini tanlab ko\'ring',
            action: _hasActiveFilters
                ? TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: const Text('Filtrlarni tozalash'),
                  )
                : null,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        sliver: _isGridView
            ? SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ProjectCard(
                    project: project,
                    onTap: () => context.push('/projects/${project['id']}'),
                    isGridView: true,
                  );
                },
              )
            : SliverList.separated(
                itemCount: projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ProjectCard(
                    project: project,
                    onTap: () => context.push('/projects/${project['id']}'),
                    isGridView: false,
                  );
                },
              ),
      ),
    ];
  }
}
