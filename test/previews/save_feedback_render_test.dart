import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/presentation/document_upload_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/document_upload_state.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/document_upload_feedback.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_body.dart';
import 'package:spine_clinic_app/shared/widgets/form_section.dart';
import 'ui_polish_capture.dart';

class _FailedUpload extends DocumentUploadController {
  @override
  DocumentUploadState build(String patientId) => DocumentUploadState(
    files: [
      DocumentUploadItem(
        fileName: 'Lumbar spine MRI and radiology report.pdf',
        bytes: Uint8List.fromList([1]),
        status: DocumentUploadStatus.failed,
        error: const NetworkException(
          code: 'mutation/unconfirmed',
          message: 'Lost response',
          userMessageKey: 'mutation_unconfirmed',
        ),
      ),
    ],
  );
}

void main() {
  setUpAll(loadPolishFonts);
  for (final width in [360.0, 1280.0]) {
    for (final dark in [false, true]) {
      testWidgets('save feedback at $width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark
                  ? AppTheme.dark(clinicalBluePaletteDark)
                  : AppTheme.light(clinicalBluePaletteLight),
              home: Scaffold(
                appBar: AppBar(title: const Text(AppStrings.newProgram)),
                body: FormPageBody(
                  isSaving: true,
                  hasDocumentUploads: true,
                  onSave: () {},
                  onCancel: () {},
                  saveLabel: AppStrings.saveAndPrescribePlan,
                  savingLabel: AppStrings.savingProgramAndDocuments,
                  savingDetail: AppStrings.keepPageOpen,
                  child: const FormSection(
                    title: AppStrings.clinicalFindingsSection,
                    child: TextField(
                      maxLines: 8,
                      decoration: InputDecoration(labelText: AppStrings.examination),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(tester.getBottomRight(find.byType(FilledButton)).dy, lessThanOrEqualTo(800));
        await capturePolish(tester, key, 'save-$width-${dark ? 'dark' : 'light'}');
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 300));
        await capturePolish(tester, key, 'save-progress-$width-${dark ? 'dark' : 'light'}');
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('unfinished upload stays readable with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [documentUploadControllerProvider('patient').overrideWith(_FailedUpload.new)],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(clinicalBluePaletteLight),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(AppSizes.p16),
                  child: DocumentUploadFeedback(patientId: 'patient'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.retryUploads), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    await capturePolish(tester, key, 'upload-recovery-360-enlarged');
  });
}
