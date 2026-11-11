import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/result.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../patient/presentation/patient_providers.dart';
import '../domain/invoice_access.dart';
import '../domain/invoice_action.dart';
import '../domain/invoice_detail.dart';
import 'invoice_providers.dart';
import 'service_catalog_providers.dart';

part 'invoice_detail_providers.g.dart';

@riverpod
Future<InvoiceDetail> invoiceDetail(Ref ref, String invoiceId) async =>
    (await ref.watch(invoiceRepositoryProvider).invoiceDetail(invoiceId)).when(
      success: (invoice) => invoice,
      failure: (error) => throw error,
    );

class InvoiceActionState {
  const InvoiceActionState({this.busy = false});
  final bool busy;

  InvoiceActionState copyWith({bool? busy}) => InvoiceActionState(busy: busy ?? this.busy);
}

/// Runs payments, refunds, voids and corrections on an invoice. Kept alive so
/// a request finishing after its dialog or form closes still refreshes the
/// invoice, the patient's list and the session balances.
@Riverpod(keepAlive: true)
class InvoiceActionController extends _$InvoiceActionController {
  @override
  InvoiceActionState build() => const InvoiceActionState();

  Future<Result<String>> run(InvoiceAction action) async {
    if (state.busy) {
      return const Failure(DatabaseException(
        code: 'invoice/busy', message: 'Save in progress', userMessageKey: 'invoice_busy',
      ));
    }
    final user = ref.read(currentUserProvider).value;
    final bool allowed = action.kind.needsManage
        ? InvoiceAccess.canManage(user)
        : InvoiceAccess.canIssue(user);
    if (!allowed) {
      return const Failure(AuthException(
        code: 'invoice/denied', message: 'Permission denied', userMessageKey: 'invoice_denied',
      ));
    }
    state = state.copyWith(busy: true);
    final result = await ref.read(invoiceRepositoryProvider).runAction(action);
    if (!ref.mounted) return result;
    state = state.copyWith(busy: false);
    // Refresh even after a rejection: it usually means the invoice moved on.
    final String patientId = action.invoice.patientId;
    ref.invalidate(invoiceDetailProvider(action.invoice.id));
    ref.invalidate(patientInvoicesProvider(patientId));
    ref.invalidate(patientDetailProvider(patientId));
    if (action.kind == InvoiceActionKind.invoiceCorrect) ref.invalidate(serviceCatalogProvider);
    if (result.isSuccess) ref.invalidate(patientIsEmptyProvider(patientId));
    return result;
  }
}
