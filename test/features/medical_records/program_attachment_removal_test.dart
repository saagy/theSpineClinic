import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_form_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_imaging_picker.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import '../../fixtures/deferred_document_repository.dart';
import '../../fixtures/deferred_program_repository.dart';
import '../../fixtures/workspace_data.dart';
import '../../fixtures/workspace_overrides.dart';
import '../../previews/ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final width in [360.0, 1280.0]) {
    testWidgets('program removals are drafts until Save changes succeeds at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = DeferredDocumentRepository();
      final programs = DeferredProgramRepository(repo);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(() => WorkspaceUser('senior')),
          patientDocumentsRepositoryProvider.overrideWithValue(repo),
          programRepositoryProvider.overrideWithValue(programs),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);
      final documents = patientDocumentsNotifierProvider(workspacePatient.id);
      await container.read(documents.future);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Patient record')),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, _) =>
                ProgramFormScreen(patientId: workspacePatient.id, program: workspacePrograms.first),
          ),
        ],
      );
      addTearDown(router.dispose);
      final capture = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: capture,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(clinicalBluePaletteLight),
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(router.push('/edit'));
      await tester.pumpAndSettle();
      final remove = find.byTooltip(AppStrings.removeAttachment).first;
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      final size = tester.getSize(remove);
      expect(size.width, greaterThanOrEqualTo(AppSizes.tappableMin));
      expect(size.height, greaterThanOrEqualTo(AppSizes.tappableMin));
      await capturePolish(tester, capture, 'program-attachments-$width');
      final remaining = tester.element(find.byKey(const ValueKey('doc-1')));
      await tester.tap(remove);
      await tester.pump();
      await tester.pump();
      expect(repo.deleteCalls, isEmpty);
      expect(programs.removedRequests, isEmpty);
      expect(repo.rows.length, 3);
      expect(container.read(documents).requireValue.length, 3);
      expect(find.byKey(const ValueKey('doc-0')), findsNothing);
      expect(tester.element(find.byKey(const ValueKey('doc-1'))), same(remaining));
      container.invalidate(documents);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('doc-0')), findsNothing);
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();
      expect(find.text('Patient record'), findsOneWidget);
      expect(repo.rows.length, 3);
      unawaited(router.push('/edit'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('doc-0')), findsOneWidget);
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pump();
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pump();
      await tester.pump();
      expect(programs.removedRequests, [
        ['doc-0'],
      ]);
      expect(repo.rows.length, 3);
      programs.gate.complete(
        const Result.failure(NetworkException(code: 'test/offline', message: 'Offline')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('doc-0')), findsNothing);
      expect(container.read(documents).requireValue.length, 3);
      expect(find.text(AppStrings.fromKey('error_network_generic')), findsWidgets);
      programs.gate = Completer<Result<PatientProgram>>();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.retrySave));
      await tester.pump();
      programs.gate.complete(Result.success(workspacePrograms.first));
      await tester.pumpAndSettle();
      expect(programs.removedRequests, [
        ['doc-0'],
        ['doc-0'],
      ]);
      expect(repo.deleteCalls, isEmpty);
      expect(find.text('Patient record'), findsOneWidget);
      expect(repo.rows.map((doc) => doc.id), ['doc-1', 'doc-2']);
      expect((await container.read(documents.future)).length, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('discarding an unsaved attachment preserves the other preview identity', (
    tester,
  ) async {
    final first = PlatformFile(name: 'First.pdf', size: 1);
    final second = PlatformFile(name: 'Second.pdf', size: 1);
    List<PlatformFile> files = [first, second];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ProgramImagingPicker(
              pendingFiles: files,
              existingDocuments: const [],
              onPendingFilesChanged: (updated) => setState(() => files = updated),
            ),
          ),
        ),
      ),
    );
    final retained = tester.element(find.byKey(ObjectKey(second)));
    await tester.tap(find.byTooltip(AppStrings.removeAttachment).first);
    await tester.pump();
    expect(files, [second]);
    expect(find.byKey(ObjectKey(first)), findsNothing);
    expect(tester.element(find.byKey(ObjectKey(second))), same(retained));
    expect(tester.takeException(), isNull);
  });
}
