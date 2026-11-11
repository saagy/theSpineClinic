import '../../../core/errors/app_exception.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/invoice_draft.dart';
import '../domain/invoice_repository.dart';
import '../domain/invoice_summary.dart';
import '../domain/service_catalog_item.dart';
import 'invoice_commands.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl(this._service) : _commands = InvoiceCommands(_service);
  final SupabaseService _service;
  final InvoiceCommands _commands;

  static const String _serviceColumns =
      'id, name, service_type, sessions_per_unit, price_minor, '
      'attributes_doctors, active, version';

  @override
  Future<Result<List<ServiceCatalogItem>>> services() => _guard(() async {
    final List<Map<String, dynamic>> rows = await _service.guardQuery(
      () => _service
          .from('service_catalog')
          .select(_serviceColumns)
          .order('name'),
    );
    return rows.map(ServiceCatalogItem.fromJson).toList();
  });

  @override
  Future<Result<String>> saveService(ServiceDraft draft) => _guard(() async {
    final InvoiceCommit commit = await _commands.execute(
      'service_save',
      draft.id ?? 'new',
      draft.toPayload(),
    );
    return commit.documentId ??
        (throw const UnknownException(message: 'Service ID missing'));
  });

  static const String _registerColumns =
      'id, branch, number, patient_id, invoice_date, total_minor, discount_minor, '
      'value_minor, net_collected_minor, due_minor, refunded_minor, status, services, '
      'doctors, created_at, created_by_name, version';

  @override
  Future<Result<List<InvoiceSummary>>> patientInvoices(String patientId) => _guard(() async {
    final List<Map<String, dynamic>> rows = await _service.guardQuery(
      () => _service
          .from('invoice_register')
          .select(_registerColumns)
          .eq('patient_id', patientId)
          .order('invoice_date', ascending: false)
          .order('created_at', ascending: false)
          .limit(500),
    );
    return rows.map(InvoiceSummary.fromJson).toList();
  });

  @override
  Future<Result<String>> createInvoice(InvoiceDraft draft) => _guard(() async {
    // A new invoice has no ID yet; the patient scopes its pending request.
    final InvoiceCommit commit = await _commands.execute(
      'invoice_create',
      'patient:${draft.patientId}',
      draft.toPayload(),
    );
    return commit.invoiceId ??
        (throw const UnknownException(message: 'Invoice ID missing'));
  });

  Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}
