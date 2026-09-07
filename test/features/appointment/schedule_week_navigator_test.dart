import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/presentation/schedule_week.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_week_strip.dart';

void main() {
  test('groups only the previous, selected, and next Saturday weeks', () {
    final DateTime selected = DateTime(2026, 7, 16);
    final Map<DateTime, List<DateTime>> grouped =
        ScheduleWeek.groupWindow<DateTime>(
          <DateTime>[
            DateTime(2026, 7, 6),
            DateTime(2026, 7, 16),
            DateTime(2026, 7, 20),
            DateTime(2026, 7, 26),
          ],
          around: selected,
          dateOf: (DateTime date) => date,
        );

    expect(ScheduleWeek.start(selected), DateTime(2026, 7, 11));
    expect(grouped[DateTime(2026, 7, 4)], <DateTime>[DateTime(2026, 7, 6)]);
    expect(grouped[DateTime(2026, 7, 11)], <DateTime>[DateTime(2026, 7, 16)]);
    expect(grouped[DateTime(2026, 7, 18)], <DateTime>[DateTime(2026, 7, 20)]);
    expect(
      grouped.values.expand((List<DateTime> dates) => dates),
      isNot(contains(DateTime(2026, 7, 26))),
    );
  });

  testWidgets('swipes by one week and stays compact on a wide window', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    DateTime selected = DateTime(2026, 7, 16);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                DoctorWeekStrip(
                  dayCounts: <DateTime, int>{selected: 4},
                  selectedDate: selected,
                  onToggleCancelled: () {},
                  onDateSelected: (DateTime date) {
                    setState(() => selected = ScheduleWeek.day(date));
                  },
                ),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('schedule-week-navigator')),
          )
          .width,
      AppSizes.scheduleNavigatorMaxWidth,
    );
    expect(find.text('4'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(selected, DateTime(2026, 7, 23));
    await tester.tap(find.byTooltip(AppStrings.nextWeek));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 7, 30));
    await tester.tap(find.byTooltip(AppStrings.nextWeek));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 8, 6));
    await tester.tap(find.byTooltip(AppStrings.previousWeek));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 7, 30));
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 8, 6));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(600, 800);
    await tester.pumpAndSettle();
    expect(find.byTooltip(AppStrings.nextWeek), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpAndSettle();
    expect(find.byTooltip(AppStrings.previousWeek), findsNothing);
    expect(find.byTooltip(AppStrings.nextWeek), findsNothing);
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 7, 30));
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('schedule-week-navigator')),
          )
          .width,
      320,
    );
    expect(tester.takeException(), isNull);
  });
}
