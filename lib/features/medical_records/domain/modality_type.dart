library;

import 'package:json_annotation/json_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// Treatment modality devices and techniques.
@JsonEnum(valueField: 'dbValue')
enum ModalityType {
  musclePain('muscle_pain'),
  massBuilt('mass_built'),
  tecar('tecar'),
  tecarFocal('tecar_focal'),
  neurodynamicNonWb('neurodynamic_non_wb'),
  neurodynamicWb('neurodynamic_wb');

  const ModalityType(this.dbValue);

  final String dbValue;

  String get displayLabel => switch (this) {
        ModalityType.musclePain => AppStrings.modalityMusclePain,
        ModalityType.massBuilt => AppStrings.modalityMassBuilt,
        ModalityType.tecar => AppStrings.modalityTecar,
        ModalityType.tecarFocal => AppStrings.modalityTecarFocal,
        ModalityType.neurodynamicNonWb => AppStrings.modalityNeurodynamicNonWb,
        ModalityType.neurodynamicWb => AppStrings.modalityNeurodynamicWb,
      };

  /// Whether this modality requires target region and duration sub-selections.
  bool get hasRegionSubSelections => switch (this) {
        ModalityType.musclePain => true,
        ModalityType.massBuilt => true,
        ModalityType.tecar => true,
        ModalityType.tecarFocal => false,
        ModalityType.neurodynamicNonWb => false,
        ModalityType.neurodynamicWb => false,
      };
}
