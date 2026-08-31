library;

import 'package:spine_clinic_app/features/medical_records/domain/laterality.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';

/// Single target body region configuration input for a modality.
class RegionInput {
  const RegionInput({
    required this.targetRegion,
    this.laterality,
    this.timeMinutes = 15,
  });

  final String targetRegion;
  final Laterality? laterality;
  final int timeMinutes;

  RegionInput copyWith({
    String? targetRegion,
    Laterality? laterality,
    int? timeMinutes,
  }) {
    return RegionInput(
      targetRegion: targetRegion ?? this.targetRegion,
      laterality: laterality ?? this.laterality,
      timeMinutes: timeMinutes ?? this.timeMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'target_region': targetRegion,
      if (laterality != null) 'laterality': laterality!.dbValue,
      'time_minutes': timeMinutes,
    };
  }
}

/// Modality configuration input for creating or updating a treatment plan.
class ModalityInput {
  const ModalityInput({
    required this.modalityType,
    this.notes,
    this.regions = const [],
  });

  final ModalityType modalityType;
  final String? notes;
  final List<RegionInput> regions;

  ModalityInput copyWith({
    ModalityType? modalityType,
    String? notes,
    List<RegionInput>? regions,
  }) {
    return ModalityInput(
      modalityType: modalityType ?? this.modalityType,
      notes: notes ?? this.notes,
      regions: regions ?? this.regions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modality_type': modalityType.dbValue,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'regions': regions.map((r) => r.toJson()).toList(),
    };
  }
}
