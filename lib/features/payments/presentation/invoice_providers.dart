import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/result.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../patient/presentation/patient_providers.dart';
import '../domain/invoice_access.dart';
import '../domain/invoice_draft.dart';
import '../domain/invoice_summary.dart';
import 'billing_report_providers.dart';
import 'service_catalog_providers.dart';

part 'invoice_providers.g.dart';

@riverpod
Future<List<InvoiceSummary>> patientInvoices(Ref ref, String patientId) async =>
    (await ref.watch(invoiceRepositoryProvider).patientInvoices(patientId)).when(
      success: (invoices) => invoices,
      failure: (error) => throw error,
    );

class InvoiceCreateState {
  const InvoiceCreateState({this.saving = false, this.error});
  final bool saving;
  final AppException? error;

  InvoiceCreateState copyWith({bool? saving, AppException? Function()? error}) =>
      InvoiceCreateState(
        saving: saving ?? this.saving,
        error: error == null ? this.error : error(),
      );
}

/// Issues new invoices. Kept alive so a request finishing after the form
/// closes still refreshes the patient's invoices, session balances and the
/// Billing reports.
@Riverpod(keepAlive: true)
class InvoiceCreateController extends _$InvoiceCreateController {
  @override
  InvoiceCreateState build() => const InvoiceCreateState();

  void clearError() => state = state.copyWith(error: () => null);

  Future<Result<String>> create(InvoiceDraft draft) async {
    if (state.saving) {
      return const Failure(DatabaseException(
        code: 'invoice/busy', message: 'Save in progress', userMessageKey: 'invoice_busy',
      ));
    }
    final user = ref.read(currentUserProvider).value;
    final bool allowed = draft.hasDiscount ? InvoiceAccess.canManage(user) : InvoiceAccess.canIssue(user);
    if (!allowed) {
      const denied = AuthException(
        code: 'invoice/denied', message: 'Permission denied', userMessageKey: 'invoice_denied',
      );
      state = state.copyWith(error: () => denied);
      return const Failure(denied);
    }
    state = state.copyWith(saving: true, error: () => null);
    final result = await ref.read(invoiceRepositoryProvider).createInvoice(draft);
    if (!ref.mounted) return result;
    state = state.copyWith(saving: false, error: () => result.exceptionOrNull);
    // Refresh even after a rejection: prices or balances may have moved.
    ref.invalidate(patientInvoicesProvider(draft.patientId));
    ref.invalidate(serviceCatalogProvider);
    // Every Billing report: one may be open under this form.
    ref.invalidate(billingReportProvider);
    if (result.isSuccess) {
      ref.invalidate(patientDetailProvider(draft.patientId));
      ref.invalidate(patientIsEmptyProvider(draft.patientId));
    }
    return result;
  }
}
