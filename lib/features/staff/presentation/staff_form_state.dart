import 'package:spine_clinic_app/core/errors/app_exception.dart';

class StaffFormState {
  const StaffFormState({this.isLoading = false, this.error});
  final bool isLoading;
  final AppException? error;
  StaffFormState copyWith({
    bool? isLoading,
    AppException? error,
    bool clearError = false,
  }) => StaffFormState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
  );
}
