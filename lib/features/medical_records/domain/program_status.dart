library;

import 'package:json_annotation/json_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// Program lifecycle status mapping to Postgres `program_status` enum.
@JsonEnum(valueField: 'dbValue')
enum ProgramStatus {
  active('active'),
  completed('completed'),
  archived('archived');

  const ProgramStatus(this.dbValue);

  final String dbValue;

  String get displayLabel => switch (this) {
        ProgramStatus.active => AppStrings.programActive,
        ProgramStatus.completed => AppStrings.programCompleted,
        ProgramStatus.archived => AppStrings.programArchived,
      };
}
