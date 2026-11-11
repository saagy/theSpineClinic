import '../../../core/errors/result.dart';
import 'invoice_action.dart';
import 'invoice_detail.dart';
import 'invoice_draft.dart';
import 'invoice_summary.dart';
import 'service_catalog_item.dart';

/// Data access for the redesigned invoice workflow. Every write goes through
/// the database's `execute_invoice_command`.
abstract interface class InvoiceRepository {
  /// The whole catalog, active and archived, ordered by type and name.
  Future<Result<List<ServiceCatalogItem>>> services();

  /// Creates or updates a service and returns its ID.
  Future<Result<String>> saveService(ServiceDraft draft);

  /// A patient's invoices, newest first, including voided ones.
  Future<Result<List<InvoiceSummary>>> patientInvoices(String patientId);

  /// Issues an invoice (and any immediate receipts) and returns its ID.
  Future<Result<String>> createInvoice(InvoiceDraft draft);

  /// The complete invoice with its lines, receipts and refunds.
  Future<Result<InvoiceDetail>> invoiceDetail(String invoiceId);

  /// Runs a payment, refund, void or correction and returns the ID of the
  /// invoice to show afterwards (the replacement after a correction).
  Future<Result<String>> runAction(InvoiceAction action);
}
