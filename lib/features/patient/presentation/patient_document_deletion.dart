part of 'patient_documents_providers.dart';

/// Optimistic list updates; the repository still deletes the DB row before storage.
mixin _PatientDocumentDeletion on _$PatientDocumentsNotifierNotifier {
  final _deletions = <String, ({String userId, Completer<Result<void>> completion})>{};

  List<PatientDocument> _visibleDocuments(List<PatientDocument> docs, String? userId) => docs
      .where((doc) => _deletions[doc.id] == null || _deletions[doc.id]!.userId != userId)
      .toList();

  /// Any active staff member with patient access may delete; RLS checks that access.
  Future<Result<void>> deleteDocument(PatientDocument doc) async {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null || !user.isActive) {
      return const Result.failure(
        AuthException(
          code: 'auth/unauthorized',
          message: 'An active staff session is required to delete documents.',
        ),
      );
    }
    final pending = _deletions[doc.id];
    if (pending?.userId == user.id) return pending!.completion.future;

    final completion = Completer<Result<void>>();
    final deletion = (userId: user.id, completion: completion);
    _deletions[doc.id] = deletion;
    final current = state.value;
    final index = current?.indexWhere((item) => item.id == doc.id) ?? -1;
    if (current != null) state = AsyncData(_visibleDocuments(current, user.id));

    Result<void> result;
    try {
      result = await ref
          .read(patientDocumentsRepositoryProvider)
          .deleteDocument(documentId: doc.id);
    } catch (error, stack) {
      result = Result.failure(AppException.fromSupabaseException(error, stackTrace: stack));
    }
    if (_deletions[doc.id] == deletion) _deletions.remove(doc.id);
    if (ref.mounted && ref.read(currentUserProvider).value?.id == user.id) {
      if (result.isFailure && index >= 0) {
        final latest = state.value;
        if (latest != null && !latest.any((item) => item.id == doc.id)) {
          final restored = [...latest]..insert(index.clamp(0, latest.length), doc);
          state = AsyncData(restored);
        }
      }
      // Discard refreshes started before deletion finished, then reconcile with the DB.
      ref.invalidateSelf();
    }
    completion.complete(result);
    return result;
  }
}
