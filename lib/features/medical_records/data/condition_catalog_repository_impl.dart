library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog_repository.dart';

/// Supabase implementation of [ConditionCatalogRepository].
class ConditionCatalogRepositoryImpl implements ConditionCatalogRepository {
  ConditionCatalogRepositoryImpl({required SupabaseService supabaseService})
      : _service = supabaseService;

  final SupabaseService _service;
  static const String _tableName = 'condition_catalog';

  @override
  Future<Result<List<ConditionCatalog>>> getAllConditions() async {
    try {
      final data = await _service.guardQuery(
        () => _service
            .from(_tableName)
            .select()
            .order('region', ascending: true)
            .order('display_order', ascending: true),
      );

      final list = (data as List<dynamic>)
          .map((item) => ConditionCatalog.fromJson(item as Map<String, dynamic>))
          .toList();

      return Result.success(list);
    } on Exception catch (error) {
      return Result.failure(
        error is AppException
            ? error
            : AppException.fromSupabaseException(error),
      );
    }
  }

  @override
  Future<Result<List<ConditionCatalog>>> getConditionsByRegion(
    BodyRegion region,
  ) async {
    try {
      final data = await _service.guardQuery(
        () => _service
            .from(_tableName)
            .select()
            .eq('region', region.name)
            .order('display_order', ascending: true),
      );

      final list = (data as List<dynamic>)
          .map((item) => ConditionCatalog.fromJson(item as Map<String, dynamic>))
          .toList();

      return Result.success(list);
    } on Exception catch (error) {
      return Result.failure(
        error is AppException
            ? error
            : AppException.fromSupabaseException(error),
      );
    }
  }
}
