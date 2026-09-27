import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'pending_mutation.dart';
import 'supabase_service.dart';

/// All writes and receipt creation happen in one database transaction.
class ClinicMutations {
  ClinicMutations(this.service);
  final SupabaseService service;
  static final Map<String, Future<void>> _inFlight = {};

  Future<void> execute(
    String kind,
    String subject,
    Map<String, dynamic> payload,
  ) {
    final String key = '${service.currentUserId}:$kind:$subject';
    // An additional submission must not run alongside this browser's request.
    if (_inFlight.containsKey(key)) return Future.error(unresolvedMutation);
    final Future<void> request = _execute(kind, subject, payload);
    _inFlight[key] = request;
    return request.whenComplete(() => _inFlight.remove(key));
  }

  Future<void> _execute(
    String kind,
    String subject,
    Map<String, dynamic> payload,
  ) async {
    final String? actor = service.currentUserId;
    if (actor == null) throw unresolvedMutation;
    final pending = await PendingMutation.open(
      actor: actor,
      scope: '$kind:$subject',
      payload: payload,
      resolveChanged: (id) => service.rpc<bool>(
        'resolve_clinic_mutation',
        params: {'p_request_id': id},
      ),
    );
    final Map<String, dynamic> outcome;
    try {
      outcome = await service.rpc<Map<String, dynamic>>(
        'execute_clinic_mutation',
        params: {
          'p_request_id': pending.id,
          'p_kind': kind,
          'p_payload': payload,
        },
      );
    } on Exception {
      // A timeout does not cancel a database transaction. Reuse this ID.
      throw unresolvedMutation;
    }
    await pending.clear();
    if (outcome['ok'] != true) {
      if (outcome['message'] == 'Payment changed. Refresh before collecting.') {
        throw const DatabaseException(
          code: 'payment/changed',
          message: 'Payment changed.',
          userMessageKey: 'payment_changed',
        );
      }
      throw AppException.fromSupabaseException(
        PostgrestException(
          code: outcome['code'] as String?,
          message: outcome['message'] as String? ?? 'Mutation rejected',
        ),
      );
    }
  }
}
