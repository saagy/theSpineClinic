import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_region_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/modality_chip_selector.dart';

void main() {
  group('ModalityRegionCatalog Clinical Sequence Tests', () {
    test('releaseRegions contains all 33 expected regions in clinical order', () {
      final regions = ModalityRegionCatalog.releaseRegions;
      expect(regions.length, 33);
      expect(regions.first.name, 'Trapezius');
      expect(regions.last.name, 'Paraspinal');
    });

    test('exerciseRegions contains all 33 expected regions in clinical order', () {
      final regions = ModalityRegionCatalog.exerciseRegions;
      expect(regions.length, 33);
      expect(regions.first.name, 'Plank');
      expect(regions.last.name, 'Hand/Wrist Muscle Exercise');
    });

    test('tecarRegions contains all 11 expected regions', () {
      final regions = ModalityRegionCatalog.tecarRegions;
      expect(regions.length, 11);
      expect(regions.first.name, 'Shoulder');
    });
  });

  group('ModalityChipSelector Widget Tests', () {
    testWidgets('renders all modality pills on desktop and handles selection toggling', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final selected = <ModalityType>{ModalityType.tecar};
      ModalityType? toggled;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModalityChipSelector(
              selectedModalities: selected,
              onToggle: (type) => toggled = type,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(ModalityType.tecar.displayLabel), findsOneWidget);
      expect(find.text(ModalityType.release.displayLabel), findsOneWidget);
      expect(find.text(ModalityType.exercise.displayLabel), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center_rounded), findsOneWidget);

      await tester.tap(find.text(ModalityType.exercise.displayLabel));
      await tester.pumpAndSettle();

      expect(toggled, equals(ModalityType.exercise));
    });

    testWidgets('renders scrollable horizontal rail on mobile viewport', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final selected = <ModalityType>{ModalityType.musclePain};
      ModalityType? toggled;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModalityChipSelector(
              selectedModalities: selected,
              onToggle: (type) => toggled = type,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(ModalityType.musclePain.displayLabel), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      await tester.tap(find.text(ModalityType.musclePain.displayLabel));
      await tester.pumpAndSettle();

      expect(toggled, equals(ModalityType.musclePain));
    });
  });
}
