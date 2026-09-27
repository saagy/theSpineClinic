import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/network/pending_mutation.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

part 'pending_booking_provider.g.dart';

/// An unknown outcome must reach the server receipt before balance validation.
@riverpod
Future<bool> pendingBooking(Ref ref, String patientId) async {
  final String? actor = ref.watch(currentUserProvider).value?.userId;
  return actor != null &&
      await PendingMutation.exists(actor, 'booking:$patientId');
}
