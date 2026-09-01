library;

import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';

/// Centralized anatomical and technique catalog for all treatment plan modalities.
class ModalityRegionCatalog {
  const ModalityRegionCatalog._();

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

  static const List<ModalityTargetRegion> releaseRegions = [
    ModalityTargetRegion(name: 'Trapezius', isBilateral: true),
    ModalityTargetRegion(name: 'Scalenii', isBilateral: true),
    ModalityTargetRegion(name: 'SCM', isBilateral: true),
    ModalityTargetRegion(name: 'Suboccipital', isBilateral: true),
    ModalityTargetRegion(name: 'Occipitalis', isBilateral: true),
    ModalityTargetRegion(name: 'Deltoid', isBilateral: true),
    ModalityTargetRegion(name: 'Pec Minor', isBilateral: true),
    ModalityTargetRegion(name: 'Rhomboidus', isBilateral: true),
    ModalityTargetRegion(name: 'Triceps', isBilateral: true),
    ModalityTargetRegion(name: 'Biceps', isBilateral: true),
    ModalityTargetRegion(name: 'Masseter', isBilateral: true),
    ModalityTargetRegion(name: 'Temporalis', isBilateral: true),
    ModalityTargetRegion(name: 'Lateral Pterygoid', isBilateral: true),
    ModalityTargetRegion(name: 'Latissimus', isBilateral: true),
    ModalityTargetRegion(name: 'Common Extensor', isBilateral: true),
    ModalityTargetRegion(name: 'Common Flexors', isBilateral: true),
    ModalityTargetRegion(name: 'Gluteus Medius', isBilateral: true),
    ModalityTargetRegion(name: 'Gluteus Maximus', isBilateral: true),
    ModalityTargetRegion(name: 'Piriformis', isBilateral: true),
    ModalityTargetRegion(name: 'Iliotibial Band Upper', isBilateral: true),
    ModalityTargetRegion(name: 'Iliotibial Band Lower', isBilateral: true),
    ModalityTargetRegion(name: 'Iliotibial Band All Band', isBilateral: true),
    ModalityTargetRegion(name: 'Hamstring', isBilateral: true),
    ModalityTargetRegion(name: 'Calf', isBilateral: true),
    ModalityTargetRegion(name: 'Tarsal Tunnel', isBilateral: true),
    ModalityTargetRegion(name: 'Tarsal Tunnel from Up-Down', isBilateral: true),
    ModalityTargetRegion(name: 'Dorsiflexors', isBilateral: true),
    ModalityTargetRegion(name: 'Plantar Fascia', isBilateral: true),
    ModalityTargetRegion(name: 'VMO', isBilateral: true),
    ModalityTargetRegion(name: 'Quadriceps', isBilateral: true),
    ModalityTargetRegion(name: 'Iliopsoas', isBilateral: true),
    ModalityTargetRegion(name: 'Adductors', isBilateral: true),
    ModalityTargetRegion(name: 'Paraspinal', isBilateral: true),
  ];

  static const List<ModalityTargetRegion> metRegions = [
    ModalityTargetRegion(name: 'Iliopsoas', isBilateral: false),
    ModalityTargetRegion(name: 'Sleeper', isBilateral: false),
    ModalityTargetRegion(name: 'Biceps', isBilateral: false),
  ];

  static const List<ModalityTargetRegion> mobilizationRegions = [
    ModalityTargetRegion(name: 't-MAP', isBilateral: false),
    ModalityTargetRegion(name: 'Routine Thoracic', isBilateral: false),
    ModalityTargetRegion(name: 'Cervical', isBilateral: false),
    ModalityTargetRegion(name: 'Upper Cervical', isBilateral: false),
    ModalityTargetRegion(name: 'Shoulder', isBilateral: false),
    ModalityTargetRegion(name: 'Elbow', isBilateral: false),
    ModalityTargetRegion(name: 'Hand', isBilateral: false),
    ModalityTargetRegion(name: 'Hip', isBilateral: false),
    ModalityTargetRegion(name: 'Knee', isBilateral: false),
    ModalityTargetRegion(name: 'Ankle', isBilateral: false),
  ];

  static const List<ModalityTargetRegion> exerciseRegions = [
    ModalityTargetRegion(name: 'Plank', isBilateral: false),
    ModalityTargetRegion(name: 'Side Plank', isBilateral: false),
    ModalityTargetRegion(name: 'Bridge', isBilateral: false),
    ModalityTargetRegion(name: '1/2 Bridge', isBilateral: false),
    ModalityTargetRegion(name: 'Curl-up', isBilateral: false),
    ModalityTargetRegion(name: 'Full Abdominal Exercise', isBilateral: false),
    ModalityTargetRegion(name: 'Complete Core', isBilateral: false),
    ModalityTargetRegion(name: 'SLR Core', isBilateral: false),
    ModalityTargetRegion(name: 'Clamshell', isBilateral: false),
    ModalityTargetRegion(name: 'Theraband Lumbar', isBilateral: false),
    ModalityTargetRegion(name: 'Balance', isBilateral: false),
    ModalityTargetRegion(name: 'Device Quadriceps', isBilateral: false),
    ModalityTargetRegion(name: 'Device Hamstring', isBilateral: false),
    ModalityTargetRegion(name: 'Device Adductor/Abductor', isBilateral: false),
    ModalityTargetRegion(name: 'Device Calf', isBilateral: false),
    ModalityTargetRegion(name: 'Leg Press', isBilateral: false),
    ModalityTargetRegion(name: 'Tip-toe Unilateral', isBilateral: false),
    ModalityTargetRegion(name: 'Tip-toe Bilateral', isBilateral: false),
    ModalityTargetRegion(name: 'VMO', isBilateral: false),
    ModalityTargetRegion(name: 'Mini-squat', isBilateral: false),
    ModalityTargetRegion(name: 'Mini-squat on Balance', isBilateral: false),
    ModalityTargetRegion(name: 'Small Muscle of Foot', isBilateral: false),
    ModalityTargetRegion(name: 'Ankle Muscle Exercise', isBilateral: false),
    ModalityTargetRegion(name: 'V 11', isBilateral: false),
    ModalityTargetRegion(name: 'Theraband Supine', isBilateral: false),
    ModalityTargetRegion(name: 'Theraband Standing', isBilateral: false),
    ModalityTargetRegion(name: 'Maximum Protection Phase', isBilateral: false),
    ModalityTargetRegion(name: 'Push Up Plus', isBilateral: false),
    ModalityTargetRegion(name: 'Hip Thrust', isBilateral: false),
    ModalityTargetRegion(name: '5 Scapular Exercise', isBilateral: false),
    ModalityTargetRegion(name: 'Fine Rotator of Hip', isBilateral: false),
    ModalityTargetRegion(name: 'Hip Adduction Exercise', isBilateral: false),
    ModalityTargetRegion(name: 'Hand/Wrist Muscle Exercise', isBilateral: false),
  ];

  static const List<String> paraspinalSubOptions = [
    'Cervical',
    'Thoracic',
    'Lumbar',
    'SI',
  ];

  static List<ModalityTargetRegion> regionsFor(ModalityType type) {
    switch (type) {
      case ModalityType.musclePain:
      case ModalityType.massBuilt:
        return musclePainAndMassBuiltRegions;
      case ModalityType.tecar:
        return tecarRegions;
      case ModalityType.release:
        return releaseRegions;
      case ModalityType.met:
        return metRegions;
      case ModalityType.mobilization:
        return mobilizationRegions;
      case ModalityType.exercise:
        return exerciseRegions;
      case ModalityType.tecarFocal:
      case ModalityType.neurodynamicNonWb:
      case ModalityType.neurodynamicWb:
      case ModalityType.mulligan:
        return const [];
    }
  }

  static bool isRegionBilateral(ModalityType type, String regionName) {
    if (type == ModalityType.release) return true;
    final list = regionsFor(type);
    final clean = regionName.toLowerCase();
    for (final r in list) {
      if (r.name.toLowerCase() == clean || clean.startsWith(r.name.toLowerCase())) {
        return r.isBilateral;
      }
    }
    return false;
  }

  static bool hasDuration(ModalityType type, String regionName) => switch (type) {
        ModalityType.musclePain || ModalityType.massBuilt || ModalityType.tecar => true,
        ModalityType.exercise => regionName.trim().toLowerCase() == 'balance',
        _ => false,
      };
}
