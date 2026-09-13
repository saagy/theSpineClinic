import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_indicator.dart';

void main() {
  for (final reducedMotion in [false, true]) {
    testWidgets('check-in transition keeps geometry, reduced motion=$reducedMotion', (
      tester,
    ) async {
      Widget view(AppointmentStatus status, {bool pending = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reducedMotion),
          child: Scaffold(
            body: Center(
              child: AppointmentStatusIndicator(status: status, pending: pending, showLabel: true),
            ),
          ),
        ),
      );
      await tester.pumpWidget(view(AppointmentStatus.scheduled));
      final bounds = tester.getRect(find.byType(AnimatedSwitcher));
      await tester.pumpWidget(view(AppointmentStatus.scheduled, pending: true));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getRect(find.byType(AnimatedSwitcher)).size, bounds.size);
      await tester.pumpWidget(view(AppointmentStatus.checkedIn));
      await tester.pump();
      final switcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
      expect(switcher.duration, reducedMotion ? Duration.zero : const Duration(milliseconds: 180));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.getRect(find.byType(AnimatedSwitcher)).size, bounds.size);
      expect(tester.takeException(), isNull);
    });
  }

  for (final status in AppointmentStatus.values) {
    for (final pending in [true, false]) {
      testWidgets('status is passive and isolates row taps: $status pending=$pending', (
        tester,
      ) async {
        int rowTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => rowTaps++,
                child: Center(
                  child: AppointmentStatusIndicator(status: status, pending: pending),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.byType(AppointmentStatusIndicator));
        await tester.pump();
        expect(rowTaps, 0);
        expect(find.byType(TextButton), findsNothing);
        expect(find.byTooltip(status.displayLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
