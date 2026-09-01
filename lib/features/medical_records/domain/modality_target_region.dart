library;

import 'package:spine_clinic_app/features/medical_records/domain/modality_region_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';

/// Target anatomical region descriptor for a treatment modality.
class ModalityTargetRegion {
  const ModalityTargetRegion({
    required this.name,
    required this.isBilateral,
  });

  final String name;
  final bool isBilateral;

  /// Returns the configured regions for a given modality type.
  static List<ModalityTargetRegion> regionsFor(ModalityType type) =>
      ModalityRegionCatalog.regionsFor(type);

  /// Checks if a given region name supports bilateral (Right/Left/Both) selection.
  static bool isRegionBilateral(ModalityType type, String regionName) =>
      ModalityRegionCatalog.isRegionBilateral(type, regionName);

  /// Checks if a given region requires duration time input (e.g. Balance in Exercise).
  static bool hasDuration(ModalityType type, String regionName) =>
      ModalityRegionCatalog.hasDuration(type, regionName);
}
