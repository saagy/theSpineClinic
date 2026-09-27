import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';

/// Stores only a random ID and a digest, never clinical details or file bytes.
class PendingMutation {
  PendingMutation(this.preferences, this.key, this.id, this.fingerprint);
  final SharedPreferences preferences;
  final String key;
  final String id;
  final String fingerprint;

  static String digest(Object payload) =>
      sha256.convert(utf8.encode(jsonEncode(payload))).toString();

  static Future<bool> exists(String actor, String scope) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    return preferences.containsKey(
      'pending-mutation:${digest([actor, scope])}',
    );
  }

  static Future<PendingMutation> open({
    required String actor,
    required String scope,
    required Object payload,
    Future<bool> Function(String id)? resolveChanged,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final String key = 'pending-mutation:${digest([actor, scope])}';
    final String fingerprint = digest(payload);
    final String? stored = preferences.getString(key);
    if (stored != null) {
      final Map<String, dynamic> data =
          jsonDecode(stored) as Map<String, dynamic>;
      final pending = PendingMutation(
        preferences,
        key,
        data['id'] as String,
        data['fingerprint'] as String,
      );
      if (pending.fingerprint == fingerprint) return pending;
      if (resolveChanged == null) throw unresolvedMutation;
      final bool completed = await resolveChanged(pending.id);
      await pending.clear();
      if (completed) {
        throw const DatabaseException(
          code: 'mutation/previous-completed',
          message:
              'The previous request completed. Review before another write.',
          userMessageKey: 'mutation_previous_completed',
        );
      }
    }
    final pending = PendingMutation(
      preferences,
      key,
      const Uuid().v4(),
      fingerprint,
    );
    if (!await preferences.setString(
      key,
      jsonEncode({'id': pending.id, 'fingerprint': fingerprint}),
    )) {
      throw unresolvedMutation;
    }
    return pending;
  }

  Future<void> clear() async {
    if (!await preferences.remove(key)) throw unresolvedMutation;
  }
}

const unresolvedMutation = NetworkException(
  code: 'mutation/unconfirmed',
  message: 'The outcome is not yet confirmed; retain the request identity.',
  userMessageKey: 'mutation_unconfirmed',
);
