import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/app_nav_rail.dart';

void main() {
  testWidgets('AppNavRail renders official brand logo in expanded state', (tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppNavRail(
            currentIndex: selectedIndex,
            onTabSelected: (index) => selectedIndex = index,
            userRole: 'doctor',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify expanded brand logo is rendered
    expect(find.byKey(const ValueKey('expanded_brand_logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('collapsed_brand_mark')), findsNothing);

    // Verify SVG picture for spine_logo.svg is present
    final svgFinder = find.byType(SvgPicture);
    expect(svgFinder, findsWidgets);

    // Verify tabs are rendered
    expect(find.text(AppStrings.navMySchedule), findsOneWidget);
    expect(find.text(AppStrings.navMyPatients), findsOneWidget);
    expect(find.text(AppStrings.collapse), findsOneWidget);
  });

  testWidgets('AppNavRail collapses and displays brand emblem badge', (tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppNavRail(
            currentIndex: selectedIndex,
            onTabSelected: (index) => selectedIndex = index,
            userRole: 'doctor',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap collapse button
    final collapseBtn = find.text(AppStrings.collapse);
    await tester.tap(collapseBtn);
    await tester.pumpAndSettle();

    // In collapsed state, collapsed_brand_mark is rendered and expanded_brand_logo is gone
    expect(find.byKey(const ValueKey('collapsed_brand_mark')), findsOneWidget);
    expect(find.byKey(const ValueKey('expanded_brand_logo')), findsNothing);
    expect(find.text(AppStrings.collapse), findsNothing);

    // Tap expand button to restore
    final expandBtn = find.byIcon(Icons.chevron_right_rounded);
    expect(expandBtn, findsOneWidget);
    await tester.tap(expandBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expanded_brand_logo')), findsOneWidget);
    expect(find.text(AppStrings.collapse), findsOneWidget);
  });
}
