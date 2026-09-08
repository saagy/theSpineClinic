import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/app_table_pagination.dart';

/// Desktop footer pagination bar for the patients data table.
///
/// Delegates to [AppTablePagination] with patient-specific entity labeling.
///
/// Rule 1 — under 200 lines.
class PatientTablePagination extends StatelessWidget {
  const PatientTablePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final int? totalCount;
  final int pageSize;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return AppTablePagination(
      currentPage: currentPage,
      totalPages: totalPages,
      totalCount: totalCount,
      pageSize: pageSize,
      hasPrevious: hasPrevious,
      hasNext: hasNext,
      onPrevious: onPrevious,
      onNext: onNext,
      entityLabel: AppStrings.paginationPatients,
    );
  }
}
