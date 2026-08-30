library;

import 'package:json_annotation/json_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// Body region enum mapping to Supabase `body_region` enum.
@JsonEnum(valueField: 'dbValue')
enum BodyRegion {
  shoulder('shoulder'),
  elbow('elbow'),
  hand('hand'),
  lumbarSpine('lumbar_spine'),
  thoracicSpine('thoracic_spine'),
  cervicalSpine('cervical_spine'),
  hipJoint('hip_joint'),
  kneeJoint('knee_joint'),
  ankleJoint('ankle_joint'),
  foot('foot');

  const BodyRegion(this.dbValue);

  final String dbValue;

  String get displayName => displayLabel;

  String get displayLabel => switch (this) {
        BodyRegion.shoulder => AppStrings.regionShoulder,
        BodyRegion.elbow => AppStrings.regionElbow,
        BodyRegion.hand => AppStrings.regionHand,
        BodyRegion.lumbarSpine => AppStrings.regionLumbarSpine,
        BodyRegion.thoracicSpine => AppStrings.regionThoracicSpine,
        BodyRegion.cervicalSpine => AppStrings.regionCervicalSpine,
        BodyRegion.hipJoint => AppStrings.regionHipJoint,
        BodyRegion.kneeJoint => AppStrings.regionKneeJoint,
        BodyRegion.ankleJoint => AppStrings.regionAnkleJoint,
        BodyRegion.foot => AppStrings.regionFoot,
      };
}
