library;

import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';

/// Input data model for creating or updating a treatment plan atomically.
class TreatmentPlanInput {
  const TreatmentPlanInput({
    this.id,
    this.planName = 'Plan 1',
    this.isActive = true,
    this.notes,
    this.modalities = const [],
  });

  final String? id;
  final String planName;
  final bool isActive;
  final String? notes;
  final List<ModalityInput> modalities;

  bool get isEmpty =>
      modalities.isEmpty && (notes == null || notes!.trim().isEmpty);

  bool get isNotEmpty => !isEmpty;

  TreatmentPlanInput copyWith({
    String? id,
    String? planName,
    bool? isActive,
    String? notes,
    List<ModalityInput>? modalities,
  }) {
    return TreatmentPlanInput(
      id: id ?? this.id,
      planName: planName ?? this.planName,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      modalities: modalities ?? this.modalities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'plan_name': planName.trim().isEmpty ? 'Plan 1' : planName.trim(),
      'is_active': isActive,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'modalities': modalities.map((m) => m.toJson()).toList(),
    };
  }
}
