import '../../../core/errors/app_exception.dart';
import '../../../core/network/pending_mutation.dart';
import '../../../core/network/supabase_service.dart';

/// IDs returned by a committed invoice command.
typedef InvoiceCommit = ({String? invoiceId, String? documentId});

/// Sends `execute_invoice_command` with a durable request ID.
///
/// A timed-out request keeps its ID on the device, so pressing Save again
/// re-sends the same request and the database returns the stored outcome
/// instead of recording it twice. If the payload changed meanwhile, the old
/// request is resolved first; if it had already committed, the user is asked
/// to review before saving again.
class InvoiceCommands {
  InvoiceCommands(this._service);
  final SupabaseService _service;
  static final Set<String> _inFlight = {};

  Future<InvoiceCommit> execute(
    String kind,
    String subject,
    Map<String, Object?> payload,
  ) async {
    final String? actor = _service.currentUserId;
    if (actor == null) throw unresolvedMutation;
    final String key = '$actor:$kind:$subject';
    if (!_inFlight.add(key)) {
      throw const DatabaseException(
        code: 'invoice/busy',
        message: 'Save in progress',
        userMessageKey: 'invoice_busy',
      );
    }
    try {
      return await _send(actor, kind, subject, payload);
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<InvoiceCommit> _send(
    String actor,
    String kind,
    String subject,
    Map<String, Object?> payload,
  ) async {
    final pending = await PendingMutation.open(
      actor: actor,
      scope: 'invoice:$kind:$subject',
      payload: payload,
      resolveChanged: (id) async {
        final Map<String, dynamic> outcome = await _service
            .rpc<Map<String, dynamic>>(
              'resolve_invoice_command',
              params: {'p_request_id': id, 'p_kind': kind},
            );
        return outcome['ok'] == true;
      },
    );
    final Map<String, dynamic> outcome;
    try {
      outcome = await _service.rpc<Map<String, dynamic>>(
        'execute_invoice_command',
        params: {
          'p_request_id': pending.id,
          'p_kind': kind,
          'p_payload': payload,
        },
      );
    } on NetworkException {
      throw unresolvedMutation; // The transaction may still have committed.
    } on UnknownException {
      throw unresolvedMutation;
    } on AppException {
      await pending.clear(); // Refused before any receipt was written.
      rethrow;
    }
    await pending.clear();
    if (outcome['ok'] != true) {
      final String code = outcome['error'] as String? ?? 'invalid_request';
      throw DatabaseException(
        code: 'invoice/$code',
        message: code,
        userMessageKey: 'invoice_$code',
      );
    }
    return (
      invoiceId: outcome['invoice_id'] as String?,
      documentId: outcome['document_id'] as String?,
    );
  }
}
