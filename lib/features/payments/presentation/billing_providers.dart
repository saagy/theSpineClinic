import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/supabase_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/billing_repository_impl.dart';
import '../domain/billing_access.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_repository.dart';

part 'billing_providers.g.dart';

@Riverpod(keepAlive: true)
BillingRepository billingRepository(Ref ref) =>
    BillingRepositoryImpl(SupabaseService.instance);

T _value<T>(Result<T> result) =>
    result.when(success: (value) => value, failure: (error) => throw error);

@riverpod
Future<List<BillingInvoice>> billingRegister(
  Ref ref,
  BillingFilter filter,
  int offset,
  int limit,
) async => _value(
  await ref.watch(billingRepositoryProvider).invoices(filter, offset, limit),
);

@riverpod
Future<BillingInvoice> billingInvoice(Ref ref, String id) async =>
    _value(await ref.watch(billingRepositoryProvider).invoice(id));

@riverpod
Future<List<BillingItem>> billingCatalog(
  Ref ref,
  String query,
  bool activeOnly, {
  int offset = 0,
  int limit = 100,
  String excluded = '',
}) async => _value(
  await ref
      .watch(billingRepositoryProvider)
      .catalog(
        query,
        activeOnly: activeOnly,
        offset: offset,
        limit: limit,
        excluded: excluded.isEmpty ? const [] : excluded.split(','),
      ),
);

@riverpod
Future<List<BillingParty>> billingLookup(
  Ref ref,
  BillingLookup kind,
  String query,
  int offset,
  int limit,
) async => _value(
  await ref.watch(billingRepositoryProvider).lookup(kind, query, offset, limit),
);

class BillingWriteState {
  const BillingWriteState({this.busy = false});
  final bool busy;
  BillingWriteState copyWith({bool? busy}) =>
      BillingWriteState(busy: busy ?? this.busy);
}

@Riverpod(keepAlive: true)
class BillingWriter extends _$BillingWriter {
  @override
  BillingWriteState build() => const BillingWriteState();

  Future<Result<BillingCommit>> submit(BillingCommand command) =>
      _run(command.action, (repo) => repo.execute(command));

  Future<Result<BillingCommit?>> recover(
    BillingAction action,
    String subject,
  ) => _run(action, (repo) => repo.recover(action, subject));

  Future<Result<T>> _run<T>(
    BillingAction action,
    Future<Result<T>> Function(BillingRepository) operation,
  ) async {
    final user = ref.read(currentUserProvider).value;
    final allowed = action == BillingAction.item
        ? BillingAccess.canManageCatalog(user)
        : BillingAccess.canTransact(user);
    if (!allowed) {
      return const Failure(
        AuthException(
          code: 'billing/denied',
          message: 'Permission denied',
          userMessageKey: 'error_database_permission_denied',
        ),
      );
    }
    if (state.busy) {
      return const Failure(
        DatabaseException(
          code: 'billing/busy',
          message: 'Save in progress',
          userMessageKey: 'billing_busy',
        ),
      );
    }
    state = state.copyWith(busy: true);
    try {
      final result = await operation(ref.read(billingRepositoryProvider));
      if (ref.mounted && result.isSuccess) {
        if (action == BillingAction.item) {
          ref.invalidate(billingCatalogProvider);
        } else {
          ref.invalidate(billingRegisterProvider);
          ref.invalidate(billingInvoiceProvider);
        }
      }
      return result;
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }
}
