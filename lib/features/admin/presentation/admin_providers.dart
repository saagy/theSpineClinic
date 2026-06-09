import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/admin/data/admin_repository.dart';

part 'admin_providers.g.dart';

/// Provides the singleton [AdminRepository] instance.
@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) {
  return AdminRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}
