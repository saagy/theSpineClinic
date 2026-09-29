import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_form_screen.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Restores the program from the URL, including after a browser reload.
class ProgramEditScreen extends ConsumerWidget {
  const ProgramEditScreen({
    super.key,
    required this.patientId,
    required this.programId,
  });
  final String patientId;
  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(programDetailProvider(programId));
    final program = result.value;
    if (program != null && program.patientId == patientId) {
      return ProgramFormScreen(
        key: ValueKey(program.id),
        patientId: patientId,
        program: program,
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.editProgram),
      ),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          exception: error is AppException
              ? error
              : AppException.fromSupabaseException(error),
          onRetry: () => ref.invalidate(programDetailProvider(programId)),
        ),
        data: (_) => const EmptyState(message: AppStrings.programNotFound),
      ),
    );
  }
}
