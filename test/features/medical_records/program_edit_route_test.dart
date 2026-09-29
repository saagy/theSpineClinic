import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/router.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/condition_catalog_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_form_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import '../../fixtures/workspace_data.dart';

class _Senior extends CurrentUser {
  @override
  Future<Staff?> build() async => workspaceStaff('senior');
}

void main() {
  for (final missing in [false, true]) {
    testWidgets('edit URL without extras handles missing=$missing', (
      tester,
    ) async {
      final program = workspacePrograms.first;
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(_Senior.new),
          conditionCatalogProvider.overrideWith((ref) async => []),
          programDetailProvider(
            program.id,
          ).overrideWith((ref) async => missing ? null : program),
          programDocumentsProvider(
            patientId: program.patientId,
            programId: program.id,
          ).overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      await tester.runAsync(() => container.read(currentUserProvider.future));
      final router = container.read(routerProvider);
      router.go('/patient/${program.patientId}/programs/${program.id}/edit');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.newProgram), findsNothing);
      expect(find.text(AppStrings.editProgram), findsOneWidget);
      if (missing) {
        expect(find.text(AppStrings.programNotFound), findsOneWidget);
        expect(find.byType(ProgramFormScreen), findsNothing);
      } else {
        expect(
          tester
              .widget<ProgramFormScreen>(find.byType(ProgramFormScreen))
              .program!
              .id,
          program.id,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
