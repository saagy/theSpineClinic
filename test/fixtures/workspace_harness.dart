import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart' as cache;
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_detail_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'workspace_data.dart';
import 'workspace_document_repository.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_gallery_viewer_screen.dart';
import 'workspace_overrides.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

class WorkspaceHarness extends StatefulWidget {
  const WorkspaceHarness({
    super.key,
    this.role = 'doctor',
    this.dark = false,
    this.empty = false,
    this.paymentError = false,
    this.longName = false,
    this.scale = 1,
  });
  final String role;
  final bool dark;
  final bool empty;
  final bool paymentError;
  final bool longName;
  final double scale;
  @override
  State<WorkspaceHarness> createState() => _HarnessState();
}

class _HarnessState extends State<WorkspaceHarness> {
  late final router = GoRouter(
    initialLocation: '/patient/${workspacePatient.id}',
    routes: [
      GoRoute(
        path: '/patient/:id/programs/:programId/gallery',
        builder: (_, state) => ProgramGalleryViewerScreen(
          documents: workspaceDocuments
              .where((d) => d.programId == state.pathParameters['programId'])
              .toList(),
        ),
      ),
      GoRoute(
        path: '/patient/:id',
        builder: (_, _) => PatientDetailScreen(patientId: workspacePatient.id),
      ),
      GoRoute(
        path: '/patient/:id/programs/:programId',
        builder: (_, state) => Scaffold(
          appBar: AppBar(title: const Text('Program destination')),
          body: Text(state.pathParameters['programId']!),
        ),
      ),
    ],
  );
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = workspacePatient.id;
    return ProviderScope(
      overrides: [
        allDoctorsForFilterProvider.overrideWith((ref) async => [workspaceStaff('doctor')]),
        patientDocumentsRepositoryProvider.overrideWithValue(WorkspaceDocumentRepository()),
        currentUserProvider.overrideWith(() => WorkspaceUser(widget.role)),
        staffProfileProvider('staff-fixture').overrideWith((ref) async => workspaceStaff('doctor')),
        canAccessPatientProvider(id).overrideWith((ref) async => true),
        patientDetailProvider(id).overrideWith(
          (ref) async => workspacePatient.copyWith(
            fullName: widget.longName
                ? 'Nour Ahmed Mohamed Abdelrahman Hassan Mahmoud'
                : workspacePatient.fullName,
            nextVisitDate: widget.empty ? null : workspacePatient.nextVisitDate,
          ),
        ),
        patientIsEmptyProvider(id).overrideWith((ref) async => false),
        patientAssignedDoctorsProvider(id).overrideWith((ref) async => [workspaceStaff('doctor')]),
        patientPaymentsProvider(id).overrideWith((ref) async {
          if (widget.paymentError) throw StateError('Fixture failure');
          return widget.empty ? [] : workspacePayments;
        }),
        patientProgramsProvider(id).overrideWith(() => WorkspaceProgramData(widget.empty)),
        patientMedicalHistoryProvider(id).overrideWith(() => WorkspaceHistoryData(widget.empty)),
        patientDocumentsNotifierProvider(id).overrideWith(() => WorkspaceDocumentData(widget.empty)),
        patientAppointmentsProvider(id).overrideWith(WorkspaceAppointmentData.new),
        patientNotesListProvider(id).overrideWith(WorkspaceNoteData.new),
        cache
            .patientAppointmentsProvider(id)
            .overrideWith(
              (ref) async => widget.empty
                  ? []
                  : [
                      Appointment(
                        id: 'appointment-fixture',
                        patientId: id,
                        type: AppointmentType.normalPtSession,
                        scheduledAt: DateTime.now().add(const Duration(days: 1)),
                        createdAt: DateTime(2026, 8, 12),
                      ),
                    ],
            ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: AppTheme.light(clinicalBluePaletteLight),
        darkTheme: AppTheme.dark(clinicalBluePaletteDark),
        themeMode: widget.dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(widget.scale)),
          child: child!,
        ),
      ),
    );
  }
}
