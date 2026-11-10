import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/condition_catalog_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_edit_section.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_detail_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_edit_screen.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_programs.dart';
import 'workspace_data.dart';
import 'workspace_overrides.dart';

import 'program_ux_repositories.dart';
export 'program_ux_repositories.dart';

Widget programUxApp(
  ProgramUxRepository programs,
  ProgramUxPlanRepository plans, {
  bool dark = false,
  double scale = 1,
  String role = 'senior',
  bool list = false,
  GlobalKey? captureKey,
  List<PatientDocument> documents = const [],
}) {
  final program = workspacePrograms.first;
  final router = GoRouter(
    initialLocation: list ? '/list' : '/patient/${program.patientId}/programs/${program.id}',
    routes: [
      GoRoute(
        path: '/list',
        builder: (_, _) => Scaffold(
          body: SingleChildScrollView(child: WorkspacePrograms(patientId: program.patientId)),
        ),
      ),
      GoRoute(
        path: '/patient/:id/programs/:programId',
        builder: (_, _) => ProgramDetailScreen(patientId: program.patientId, programId: program.id),
      ),
      GoRoute(
        path: '/patient/:id/programs/:programId/edit',
        builder: (_, state) => ProgramEditScreen(
          patientId: program.patientId,
          programId: program.id,
          initialSection: ProgramEditSection.fromQuery(state.uri.queryParameters['section']),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith(() => WorkspaceUser(role)),
      conditionCatalogProvider.overrideWith(
        (ref) async => [
          for (final item in program.conditions)
            if (item.condition != null) item.condition!,
        ],
      ),
      programRepositoryProvider.overrideWithValue(programs),
      treatmentPlanRepositoryProvider.overrideWithValue(plans),
      programDocumentsProvider(
        patientId: program.patientId,
        programId: program.id,
      ).overrideWith((ref) async => documents),
    ],
    child: RepaintBoundary(
      key: captureKey,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: dark ? AppTheme.dark(clinicalBluePaletteDark) : AppTheme.light(clinicalBluePaletteLight),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
}
