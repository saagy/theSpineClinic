import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_detail_skeleton.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_documents_skeleton.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_payments_skeleton.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

void main() {
  setUp(() {
    Animate.restartOnHotReload = false;
  });

  group('Screen & Tab Skeletons Tests', () {
    testWidgets('AppointmentDetailSkeleton renders layout hierarchy', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppointmentDetailSkeleton(),
          ),
        ),
      );
      await tester.pump(100.ms);

      // Verify presence of skeleton boxes and circles
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(SkeletonCircle), findsWidgets);
      expect(find.byType(SkeletonCard), findsNWidgets(3));

      await tester.pumpAndSettle();
    });

    testWidgets('PatientPaymentsSkeleton renders summary and payment cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PatientPaymentsSkeleton(),
          ),
        ),
      );
      await tester.pump(100.ms);

      expect(find.byType(Card), findsNWidgets(3));
      expect(find.byType(SkeletonBox), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('PatientDocumentsSkeleton renders 2-column grid on mobile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PatientDocumentsSkeleton(itemCount: 4),
          ),
        ),
      );
      await tester.pump(100.ms);

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final GridView grid = tester.widget(gridFinder);
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      expect(find.byType(Card), findsNWidgets(4));

      await tester.pumpAndSettle();
    });
  });
}
