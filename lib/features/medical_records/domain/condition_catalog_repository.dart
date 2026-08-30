library;

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';

/// Contract for accessing the condition and injury reference catalog.
abstract class ConditionCatalogRepository {
  /// Fetches all condition catalog entries ordered by region and display order.
  Future<Result<List<ConditionCatalog>>> getAllConditions();

  /// Fetches catalog entries specific to a given [region].
  Future<Result<List<ConditionCatalog>>> getConditionsByRegion(
    BodyRegion region,
  );
}
