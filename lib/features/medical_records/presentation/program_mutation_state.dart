import 'package:spine_clinic_app/core/errors/app_exception.dart';

class ProgramMutationState {
  const ProgramMutationState({this.isLoading = false, this.error, this.scope = ''});
  final bool isLoading;
  final AppException? error;
  final String scope;

  static String saveScope(String patientId, String? programId) =>
      '$patientId:${programId ?? 'new'}';

  ProgramMutationState copyWith({
    bool? isLoading,
    AppException? error,
    bool clearError = false,
    String? scope,
  }) => ProgramMutationState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    scope: scope ?? this.scope,
  );
}
