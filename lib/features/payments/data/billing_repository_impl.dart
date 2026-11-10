import '../../../core/errors/app_exception.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/pending_mutation.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_money.dart';
import '../domain/billing_repository.dart';
import 'billing_csv.dart';

part 'billing_directory.dart';

class BillingRepositoryImpl with _BillingDirectory {
  BillingRepositoryImpl(this._service);
  @override
  final SupabaseService _service;

  String _registerQuery(String query) => query.trim().replaceFirst(
    RegExp(r'^id\s+(?=[0-9]+$)', caseSensitive: false),
    '',
  );

  @override
  Future<Result<List<BillingInvoice>>> invoices(
    BillingFilter filter,
    int offset,
    int limit,
  ) => _guard(
    () async => (await _rows(
      filter,
      offset,
      limit,
      false,
    )).map(BillingInvoice.fromJson).toList(),
  );

  Future<List<BillingRow>> _rows(
    BillingFilter filter,
    int offset,
    int limit,
    bool collections,
  ) async => billingRows(
    await _service.rpc<List<Object?>>(
      'billing_list',
      params: {
        'p_query': _registerQuery(filter.query),
        'p_branch': filter.branch?.dbValue,
        'p_state': filter.status?.name,
        'p_from': filter.from == null ? null : billingDate(filter.from!),
        'p_to': filter.to == null ? null : billingDate(filter.to!),
        'p_offset': offset,
        'p_limit': limit,
        'p_collections': collections,
      },
    ),
  );

  @override
  Future<Result<BillingInvoice>> invoice(String id) => _guard(() async {
    final row = await _service.rpc<BillingRow?>(
      'billing_invoice_detail',
      params: {'p_id': id},
    );
    if (row == null) {
      throw const NotFoundException(message: 'Invoice unavailable');
    }
    return BillingInvoice.fromJson(row);
  });

  @override
  Future<Result<BillingCommit>> execute(BillingCommand command) =>
      _guard(() async {
        final actor = _actor;
        final scope = _scope(command.action, command.subject);
        final existing = await PendingMutation.find(actor, scope);
        if (existing != null) return _resolve(existing, command.action);
        final pending = await PendingMutation.open(
          actor: actor,
          scope: scope,
          payload: command.payload,
        );
        final BillingRow outcome;
        try {
          outcome = await _service.rpc<BillingRow>(
            'execute_billing_mutation',
            params: {
              'p_request_id': pending.id,
              'p_kind': command.action.wire,
              'p_payload': command.payload,
            },
          );
        } on NetworkException {
          throw unresolvedMutation;
        } on UnknownException {
          throw unresolvedMutation;
        } on AppException {
          await pending.clear();
          rethrow;
        }
        await pending.clear();
        return _commit(outcome);
      });

  @override
  Future<Result<BillingCommit?>> recover(
    BillingAction action,
    String subject,
  ) => _guard(() async {
    final pending = await PendingMutation.find(_actor, _scope(action, subject));
    if (pending == null) return null;
    return _resolve(pending, action);
  });

  Future<BillingCommit> _resolve(
    PendingMutation pending,
    BillingAction action,
  ) async {
    final BillingRow outcome;
    try {
      outcome = await _service.rpc<BillingRow>(
        'resolve_billing_mutation',
        params: {'p_request_id': pending.id, 'p_kind': action.wire},
      );
    } on Exception {
      throw unresolvedMutation;
    }
    await pending.clear();
    return _commit(outcome);
  }

  String get _actor => _service.currentUserId ?? (throw unresolvedMutation);
  String _scope(BillingAction action, String subject) =>
      'billing:${action.wire}:$subject';

  BillingCommit _commit(BillingRow outcome) {
    if (outcome['ok'] != true) {
      final code = outcome['error'] as String? ?? 'invalid_invoice';
      throw DatabaseException(
        code: 'billing/$code',
        message: code,
        userMessageKey: 'billing_$code',
      );
    }
    return (
      invoiceId: outcome['invoice_id'] as String?,
      documentId: outcome['document_id'] as String?,
    );
  }

  @override
  Future<Result<String>> export(
    BillingFilter filter, {
    required bool collections,
  }) => _guard(() async {
    final rows = await _service.rpc<List<Object?>>(
      'billing_export',
      params: {
        'p_query': _registerQuery(filter.query),
        'p_branch': filter.branch?.dbValue,
        'p_state': filter.status?.name,
        'p_from': filter.from == null ? null : billingDate(filter.from!),
        'p_to': filter.to == null ? null : billingDate(filter.to!),
        'p_collections': collections,
      },
    );
    if (rows.length > 10000) {
      throw const DatabaseException(
        code: 'billing/export_limit',
        message: 'Export filter too broad',
        userMessageKey: 'billing_export_limit',
      );
    }
    return billingCsv(billingRows(rows), collections: collections);
  });

  @override
  Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}
