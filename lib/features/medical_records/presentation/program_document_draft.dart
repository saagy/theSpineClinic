import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

part 'program_document_draft.g.dart';

class ProgramDocumentDraftState {
  const ProgramDocumentDraftState({this.removedIds = const {}});
  final Set<String> removedIds;

  ProgramDocumentDraftState copyWith({Set<String>? removedIds}) =>
      ProgramDocumentDraftState(removedIds: removedIds ?? this.removedIds);
}

/// One draft per mounted form; removal never changes the shared document list.
@Riverpod(keepAlive: true)
class ProgramDocumentDraft extends _$ProgramDocumentDraft {
  @override
  ProgramDocumentDraftState build(Object formIdentity) {
    ref.watch(
      currentUserProvider.select(
        (session) => (session.value?.id, session.value?.isActive, session.value?.isSeniorDoctor),
      ),
    );
    return const ProgramDocumentDraftState();
  }

  bool remove(String documentId) {
    final user = ref.read(currentUserProvider).value;
    if (user == null || !user.isActive || !user.isSeniorDoctor) return false;
    state = state.copyWith(removedIds: Set.unmodifiable({...state.removedIds, documentId}));
    return true;
  }
}
