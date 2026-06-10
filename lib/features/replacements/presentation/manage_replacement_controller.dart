/// Riverpod providers and controller for the ManageReplacementScreen.
///
/// Exposes:
/// - [replacementRepositoryProvider] — singleton repository access.
/// - [ManageReplacementController] — multi-step async notifier.
///
/// Rule 3 — all state via Riverpod.
/// Rule 4 — repository calls return [Result<T>].
/// Rule 6 — role-check before any write action.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/replacements/data/replacement_repository_impl.dart';
import 'package:spine_clinic_app/features/replacements/domain/replacement_repository.dart';

part 'manage_replacement_controller.g.dart';

/// Provides the singleton [ReplacementRepository] backed by Supabase.
@Riverpod(keepAlive: true)
ReplacementRepository replacementRepository(Ref ref) {
  return ReplacementRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}

/// Tracks which step the replacement wizard is on.
enum ReplacementStep { form, checklist }

/// View model for the ManageReplacementScreen multi-step flow.
class ManageReplacementState {
  /// Current step in the wizard.
  final ReplacementStep step;

  /// Selected absent doctor ID (Step 1).
  final String? absentDoctorId;

  /// Selected covering doctor ID (Step 1).
  final String? coveringDoctorId;

  /// Target replacement date (Step 1).
  final DateTime selectedDate;

  /// List of affected appointments (Step 2).
  final List<AffectedAppointmentItem> affectedAppointments;

  /// Set of appointment IDs toggled for swapping (Step 2).
  final Set<String> checkedAppointmentIds;

  /// Whether a mutation is in progress.
  final bool isSaving;

  /// Error message from the last failed operation.
  final String? errorMessage;

  /// Creates a [ManageReplacementState].
  const ManageReplacementState({
    this.step = ReplacementStep.form,
    this.absentDoctorId,
    this.coveringDoctorId,
    required this.selectedDate,
    this.affectedAppointments = const [],
    this.checkedAppointmentIds = const {},
    this.isSaving = false,
    this.errorMessage,
  });

  /// Creates a copy with optional field overrides.
  ManageReplacementState copyWith({
    ReplacementStep? step,
    String? absentDoctorId,
    String? coveringDoctorId,
    DateTime? selectedDate,
    List<AffectedAppointmentItem>? affectedAppointments,
    Set<String>? checkedAppointmentIds,
    bool? isSaving,
    String? errorMessage,
  }) {
    return ManageReplacementState(
      step: step ?? this.step,
      absentDoctorId: absentDoctorId ?? this.absentDoctorId,
      coveringDoctorId: coveringDoctorId ?? this.coveringDoctorId,
      selectedDate: selectedDate ?? this.selectedDate,
      affectedAppointments:
          affectedAppointments ?? this.affectedAppointments,
      checkedAppointmentIds:
          checkedAppointmentIds ?? this.checkedAppointmentIds,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

/// Multi-step async notifier driving the replacement wizard.
@riverpod
class ManageReplacementController extends _$ManageReplacementController {
  @override
  Future<ManageReplacementState> build() async {
    return ManageReplacementState(selectedDate: DateTime.now());
  }

  /// Updates the selected absent doctor.
  void setAbsentDoctor(String doctorId) {
    final ManageReplacementState current = state.requireValue;
    state = AsyncValue.data(
      current.copyWith(absentDoctorId: doctorId),
    );
  }

  /// Updates the selected covering doctor.
  void setCoveringDoctor(String doctorId) {
    final ManageReplacementState current = state.requireValue;
    state = AsyncValue.data(
      current.copyWith(coveringDoctorId: doctorId),
    );
  }

  /// Updates the target date.
  void setDate(DateTime date) {
    final ManageReplacementState current = state.requireValue;
    state = AsyncValue.data(current.copyWith(selectedDate: date));
  }

  /// Confirms the replacement (Step 1 → Step 2).
  ///
  /// Creates the `doctor_replacements` row, then loads affected
  /// appointments for the checklist.
  Future<void> confirmReplacement() async {
    final ManageReplacementState current = state.requireValue;
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;

    // Rule 6: role guard
    if (user.role == UserRole.doctor) {
      state = AsyncValue.data(
        current.copyWith(
          errorMessage: 'Doctors cannot manage replacements.',
        ),
      );
      return;
    }

    if (current.absentDoctorId == null ||
        current.coveringDoctorId == null) {
      state = AsyncValue.data(
        current.copyWith(
          errorMessage: 'Please select both doctors.',
        ),
      );
      return;
    }

    if (current.absentDoctorId == current.coveringDoctorId) {
      state = AsyncValue.data(
        current.copyWith(
          errorMessage: 'Absent and covering doctors must differ.',
        ),
      );
      return;
    }

    state = AsyncValue.data(current.copyWith(isSaving: true));

    final ReplacementRepository repo =
        ref.read(replacementRepositoryProvider);

    // Check for existing replacement
    final Result<bool> existsResult = await repo.replacementExists(
      absentDoctorId: current.absentDoctorId!,
      date: current.selectedDate,
    );

    if (existsResult.isSuccess && existsResult.dataOrNull == true) {
      await repo.deleteExistingReplacement(
        absentDoctorId: current.absentDoctorId!,
        date: current.selectedDate,
      );
    }

    // Create the replacement record
    final Result<String> createResult = await repo.createReplacement(
      absentDoctorId: current.absentDoctorId!,
      coveringDoctorId: current.coveringDoctorId!,
      date: current.selectedDate,
      initiatedBy: user.id,
    );
    if (!ref.mounted) return;

    switch (createResult) {
      case Failure<String>(:final exception):
        state = AsyncValue.data(
          current.copyWith(
            isSaving: false,
            errorMessage: exception.message,
          ),
        );
        return;
      case Success<String>():
        break;
    }

    // Load affected appointments
    final Result<List<AffectedAppointmentItem>> apptResult =
        await repo.getAffectedAppointments(
      absentDoctorId: current.absentDoctorId!,
      date: current.selectedDate,
    );
    if (!ref.mounted) return;

    switch (apptResult) {
      case Success<List<AffectedAppointmentItem>>(:final data):
        state = AsyncValue.data(
          current.copyWith(
            step: ReplacementStep.checklist,
            affectedAppointments: data,
            checkedAppointmentIds: const {},
            isSaving: false,
          ),
        );
      case Failure<List<AffectedAppointmentItem>>(:final exception):
        state = AsyncValue.data(
          current.copyWith(
            isSaving: false,
            errorMessage: exception.message,
          ),
        );
    }
  }

  /// Toggles a single appointment's checked state.
  void toggleAppointment(String appointmentId) {
    final ManageReplacementState current = state.requireValue;
    final Set<String> updated = Set<String>.from(
      current.checkedAppointmentIds,
    );
    if (updated.contains(appointmentId)) {
      updated.remove(appointmentId);
    } else {
      updated.add(appointmentId);
    }
    state = AsyncValue.data(
      current.copyWith(checkedAppointmentIds: updated),
    );
  }

  /// Toggles all appointments on or off.
  void toggleAll(bool selectAll) {
    final ManageReplacementState current = state.requireValue;
    final Set<String> updated = selectAll
        ? current.affectedAppointments
            .map((AffectedAppointmentItem i) => i.appointment.id)
            .toSet()
        : <String>{};
    state = AsyncValue.data(
      current.copyWith(checkedAppointmentIds: updated),
    );
  }

  /// Applies the bulk swap for all checked appointments.
  Future<bool> applyBulkSwap() async {
    final ManageReplacementState current = state.requireValue;
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return false;

    // Rule 6: role guard
    if (user.role == UserRole.doctor) return false;

    if (current.checkedAppointmentIds.isEmpty) return false;

    state = AsyncValue.data(current.copyWith(isSaving: true));

    final ReplacementRepository repo =
        ref.read(replacementRepositoryProvider);
    final Result<int> result = await repo.applyBulkSwap(
      appointmentIds: current.checkedAppointmentIds.toList(),
      absentDoctorId: current.absentDoctorId!,
      coveringDoctorId: current.coveringDoctorId!,
      addedBy: user.id,
    );
    if (!ref.mounted) return false;

    switch (result) {
      case Success<int>():
        // Invalidate today's appointments cache
        ref.invalidate(todayAppointmentsProvider);
        state = AsyncValue.data(
          current.copyWith(isSaving: false),
        );
        return true;
      case Failure<int>(:final exception):
        state = AsyncValue.data(
          current.copyWith(
            isSaving: false,
            errorMessage: exception.message,
          ),
        );
        return false;
    }
  }
}
