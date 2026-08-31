library;

import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';

/// Target anatomical region descriptor for a treatment modality.
class ModalityTargetRegion {
  const ModalityTargetRegion({
    required this.name,
    required this.isBilateral,
  });

  final String name;
  final bool isBilateral;

  /// Target regions for Muscle Pain and Mass Built modalities.
  static const List<ModalityTargetRegion> musclePainAndMassBuiltRegions = [
    ModalityTargetRegion(name: 'Deltoid', isBilateral: true),
    ModalityTargetRegion(name: 'Common Flexor', isBilateral: false),
    ModalityTargetRegion(name: 'Common Extensors', isBilateral: false),
    ModalityTargetRegion(name: 'Thoracic', isBilateral: false),
    ModalityTargetRegion(name: 'Thoracolumbar', isBilateral: false),
    ModalityTargetRegion(name: 'Lumbar', isBilateral: false),
    ModalityTargetRegion(name: 'Quadriceps', isBilateral: true),
    ModalityTargetRegion(name: 'Calf', isBilateral: true),
    ModalityTargetRegion(name: 'Dorsiflexors', isBilateral: true),
  ];

  /// Target regions for TECAR modality.
  static const List<ModalityTargetRegion> tecarRegions = [
    ModalityTargetRegion(name: 'Shoulder', isBilateral: false),
    ModalityTargetRegion(name: 'Elbow', isBilateral: false),
    ModalityTargetRegion(name: 'Hand (Carpal Tunnel)', isBilateral: false),
    ModalityTargetRegion(name: 'Cervical', isBilateral: false),
    ModalityTargetRegion(name: 'Thoracic', isBilateral: false),
    ModalityTargetRegion(name: 'Lumbar', isBilateral: false),
    ModalityTargetRegion(name: 'Gluteus', isBilateral: true),
    ModalityTargetRegion(name: 'Knee', isBilateral: true),
    ModalityTargetRegion(name: 'Ankle', isBilateral: true),
    ModalityTargetRegion(name: 'Plantar Fascia', isBilateral: true),
    ModalityTargetRegion(name: 'Tarsal Tunnel', isBilateral: true),
  ];

  /// Returns the configured regions for a given modality type.
  static List<ModalityTargetRegion> regionsFor(ModalityType type) {
    switch (type) {
      case ModalityType.musclePain:
      case ModalityType.massBuilt:
        return musclePainAndMassBuiltRegions;
      case ModalityType.tecar:
        return tecarRegions;
      case ModalityType.tecarFocal:
      case ModalityType.neurodynamicNonWb:
      case ModalityType.neurodynamicWb:
        return const [];
    }
  }

  /// Checks if a given region name supports bilateral (Right/Left/Both) selection.
  static bool isRegionBilateral(ModalityType type, String regionName) {
    final list = regionsFor(type);
    for (final r in list) {
      if (r.name.toLowerCase() == regionName.toLowerCase()) {
        return r.isBilateral;
      }
    }
    return false;
  }
}
