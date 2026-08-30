library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/medical_records/data/condition_catalog_repository_impl.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog_repository.dart';

part 'condition_catalog_providers.g.dart';

/// Provides a singleton instance of [ConditionCatalogRepository].
@Riverpod(keepAlive: true)
ConditionCatalogRepository conditionCatalogRepository(Ref ref) {
  return ConditionCatalogRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}

/// Provides all condition catalog entries cached application-wide.
@Riverpod(keepAlive: true)
Future<List<ConditionCatalog>> conditionCatalog(Ref ref) async {
  final ConditionCatalogRepository repo =
      ref.watch(conditionCatalogRepositoryProvider);
  final Result<List<ConditionCatalog>> result = await repo.getAllConditions();
  return result.when(
    success: (List<ConditionCatalog> data) => data,
    failure: (AppException exception) => throw exception,
  );
}

/// Provides condition catalog entries filtered for a specific [region].
@riverpod
Future<List<ConditionCatalog>> conditionsByRegion(
  Ref ref,
  BodyRegion region,
) async {
  final allConditions = await ref.watch(conditionCatalogProvider.future);
  return allConditions.where((c) => c.region == region).toList();
}
