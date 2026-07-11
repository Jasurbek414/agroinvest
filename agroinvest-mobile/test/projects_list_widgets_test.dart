import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agroinvest_mobile/core/utils/format.dart';
import 'package:agroinvest_mobile/core/widgets/pinned_sliver_header.dart';
import 'package:agroinvest_mobile/features/projects/presentation/widgets/project_card/project_card.dart';
import 'package:agroinvest_mobile/features/projects/presentation/widgets/projects_header.dart';
import 'package:agroinvest_mobile/features/projects/presentation/widgets/projects_status_segmented.dart';

// Layout smoke tests for the redesigned projects tab. Any RenderFlex overflow
// (the usual failure mode of fixed-height sliver headers) fails the test via
// FlutterError, so these catch what `flutter analyze` can't.

final _fakeProject = <String, dynamic>{
  'id': '1',
  'title': 'Naslli qoramol boqish – Farg\'ona vodiysida sinalgan yo\'nalish',
  'description': 'Bordoqiga qo\'yilgan 20 bosh buqa.',
  'region': 'Farg\'ona viloyati',
  'assetType': 'LIVESTOCK',
  'riskLevel': 'MEDIUM',
  'raisedAmount': '12500000',
  'targetAmount': '20000000',
  'expectedReturnPct': '25',
  'durationDays': 180,
  'minInvestment': 100000.0,
  'mediaUrls': <String>[],
};

void main() {
  testWidgets('projects header + pinned segmented + card lay out without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 690); // small phone, worst case
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    String status = 'FUNDING';
    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              ProjectsSliverHeader(
                searchController: searchController,
                onSearchChanged: (_) {},
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: PinnedSliverHeader(
                  height: 62,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: ProjectsStatusSegmented(
                      selectedStatus: status,
                      onChanged: (s) => status = s,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.separated(
                  itemCount: 2,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, __) => ProjectCard(project: _fakeProject, onTap: () {}),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loyihalar'), findsOneWidget);
    expect(find.text('Mablag\' yig\'ish'), findsOneWidget);
    expect(find.text('Farg\'ona viloyati'), findsWidgets);
    expect(find.text('+25%'), findsWidgets);
    expect(find.text('O\'rta xavf'), findsWidgets);
    expect(find.textContaining('yig\'ildi'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Segmented control switches status on tap.
    await tester.tap(find.text('Yakunlangan'));
    await tester.pumpAndSettle();
    expect(status, 'COMPLETED');
  });

  test('formatMoneyCompact shortens amounts for card rows', () {
    expect(formatMoneyCompact(12500000), '12.5 mln');
    expect(formatMoneyCompact('20000000'), '20 mln');
    expect(formatMoneyCompact(500000), '500 ming');
    expect(formatMoneyCompact(2100000000), '2.1 mlrd');
    expect(formatMoneyCompact(950), '950');
    expect(formatMoneyCompact(null), '0');
  });
}
