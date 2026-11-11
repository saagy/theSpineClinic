import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/supabase_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/invoice_repository_impl.dart';
import '../domain/invoice_access.dart';
import '../domain/invoice_repository.dart';
import '../domain/service_catalog_item.dart';

part 'service_catalog_providers.g.dart';

@Riverpod(keepAlive: true)
InvoiceRepository invoiceRepository(Ref ref) =>
    InvoiceRepositoryImpl(SupabaseService.instance);

/// The full catalog. Small enough to load once and filter on the device.
@riverpod
Future<List<ServiceCatalogItem>> serviceCatalog(Ref ref) async =>
    (await ref.watch(invoiceRepositoryProvider).services()).when(
      success: (services) => services,
      failure: (error) => throw error,
    );

class ServiceSaveState {
  const ServiceSaveState({this.saving = false, this.error});
  final bool saving;
  final AppException? error;

  ServiceSaveState copyWith({bool? saving, AppException? Function()? error}) =>
      ServiceSaveState(
        saving: saving ?? this.saving,
        error: error == null ? this.error : error(),
      );
}

/// Saves catalog changes. Kept alive so a save finishing after the form
/// closes still refreshes the catalog.
@Riverpod(keepAlive: true)
class ServiceCatalogController extends _$ServiceCatalogController {
  @override
  ServiceSaveState build() => const ServiceSaveState();

  void clearError() => state = state.copyWith(error: () => null);

  Future<Result<String>> save(ServiceDraft draft) async {
    if (state.saving) {
      return const Failure(
        DatabaseException(
          code: 'invoice/busy',
          message: 'Save in progress',
          userMessageKey: 'invoice_busy',
        ),
      );
    }
    final user = ref.read(currentUserProvider).value;
    if (!InvoiceAccess.canManage(user)) {
      const denied = AuthException(
        code: 'invoice/denied',
        message: 'Permission denied',
        userMessageKey: 'invoice_denied',
      );
      state = state.copyWith(error: () => denied);
      return const Failure(denied);
    }
    state = state.copyWith(saving: true, error: () => null);
    final result = await ref.read(invoiceRepositoryProvider).saveService(draft);
    if (!ref.mounted) return result;
    state = state.copyWith(saving: false, error: () => result.exceptionOrNull);
    // A conflicting or already-completed save also means the list is stale.
    ref.invalidate(serviceCatalogProvider);
    return result;
  }
}
