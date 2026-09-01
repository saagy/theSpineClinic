library;

import 'package:flutter/material.dart';
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
  neurodynamicWb('neurodynamic_wb'),
  release('release'),
  met('met'),
  mobilization('mobilization'),
  mulligan('mulligan'),
  exercise('exercise');

  const ModalityType(this.dbValue);

  final String dbValue;

  String get displayLabel => switch (this) {
        ModalityType.musclePain => AppStrings.modalityMusclePain,
        ModalityType.massBuilt => AppStrings.modalityMassBuilt,
        ModalityType.tecar => AppStrings.modalityTecar,
        ModalityType.tecarFocal => AppStrings.modalityTecarFocal,
        ModalityType.neurodynamicNonWb => AppStrings.modalityNeurodynamicNonWb,
        ModalityType.neurodynamicWb => AppStrings.modalityNeurodynamicWb,
        ModalityType.release => AppStrings.modalityRelease,
        ModalityType.met => AppStrings.modalityMet,
        ModalityType.mobilization => AppStrings.modalityMobilization,
        ModalityType.mulligan => AppStrings.modalityMulligan,
        ModalityType.exercise => AppStrings.modalityExercise,
      };

  IconData get icon => switch (this) {
        ModalityType.musclePain => Icons.healing_outlined,
        ModalityType.massBuilt => Icons.trending_up_rounded,
        ModalityType.tecar => Icons.bolt_rounded,
        ModalityType.tecarFocal => Icons.center_focus_strong_rounded,
        ModalityType.neurodynamicNonWb => Icons.airline_seat_recline_normal_rounded,
        ModalityType.neurodynamicWb => Icons.directions_walk_rounded,
        ModalityType.release => Icons.spa_rounded,
        ModalityType.met => Icons.compare_arrows_rounded,
        ModalityType.mobilization => Icons.accessibility_new_rounded,
        ModalityType.mulligan => Icons.touch_app_rounded,
        ModalityType.exercise => Icons.fitness_center_rounded,
      };

  /// Whether this modality requires target region and duration sub-selections.
  bool get hasRegionSubSelections => switch (this) {
        ModalityType.musclePain => true,
        ModalityType.massBuilt => true,
        ModalityType.tecar => true,
        ModalityType.tecarFocal => false,
        ModalityType.neurodynamicNonWb => false,
        ModalityType.neurodynamicWb => false,
        ModalityType.release => true,
        ModalityType.met => true,
        ModalityType.mobilization => true,
        ModalityType.mulligan => false,
        ModalityType.exercise => true,
      };
}

