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

  /// Sort priority: Active (0) > Completed (1) > Archived (2)
  int get priority => switch (this) {
        ProgramStatus.active => 0,
        ProgramStatus.completed => 1,
        ProgramStatus.archived => 2,
      };

  String get displayLabel => switch (this) {
        ProgramStatus.active => AppStrings.programActive,
        ProgramStatus.completed => AppStrings.programCompleted,
        ProgramStatus.archived => AppStrings.programArchived,
      };
}
