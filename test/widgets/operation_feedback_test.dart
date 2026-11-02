import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_body.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';
import 'package:spine_clinic_app/shared/widgets/operation_feedback.dart';

void main() {
  testWidgets(
    'overlay preserves entered form data as activity starts and finishes',
    (tester) async {
      Widget form(bool loading) => MaterialApp(
        home: Scaffold(
          body: LoadingOverlay(isLoading: loading, child: const TextField()),
        ),
      );
      await tester.pumpWidget(form(false));
      await tester.enterText(
        find.byType(TextField),
        'Preserved clinical finding',
      );
      await tester.pumpWidget(form(true));
      await tester.pumpWidget(form(false));
      expect(find.text('Preserved clinical finding'), findsOneWidget);
    },
  );

  testWidgets(
    'busy forms keep the footer visible and permit scrolling, not edits',
    (tester) async {
      int tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormPageBody(
              isSaving: true,
              hasDocumentUploads: true,
              savingLabel: AppStrings.savingProgramAndDocuments,
              onSave: () => tapped++,
              onCancel: () => tapped++,
              child: Column(
                children: [
                  TextButton(
                    onPressed: () => tapped++,
                    child: const Text('Edit finding'),
                  ),
                  const SizedBox(height: 1600),
                  const Text('End of findings'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text(AppStrings.savingProgramAndDocuments), findsOneWidget);
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, allOf(greaterThan(0), lessThan(1)));
      final before = tester.getTopLeft(find.text('End of findings')).dy;
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.getTopLeft(find.text('End of findings')).dy,
        lessThan(before),
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tapped, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'reduced motion advances in steps and failures stop the activity',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: OperationFeedback(
                message: AppStrings.uploadingDocuments,
                showUploadProgress: true,
              ),
            ),
          ),
        ),
      );
      double value() => tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value!;
      final start = value();
      expect(start, greaterThan(0));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(value(), greaterThan(start));
      expect(find.text(AppStrings.uploadingDocuments), findsOneWidget);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OperationFeedback(
              message: AppStrings.programAttachmentsPending,
              isBusy: false,
              isError: true,
            ),
          ),
        ),
      );
      expect(find.text(AppStrings.programAttachmentsPending), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'estimated fill advances without announcing or completing a pending request',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OperationFeedback(
              message: AppStrings.uploadingDocuments,
              showUploadProgress: true,
            ),
          ),
        ),
      );
      double value() => tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value!;
      final start = value();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));
      expect(value(), greaterThan(start));
      await tester.pump(const Duration(minutes: 10));
      await tester.pump(const Duration(milliseconds: 300));
      expect(value(), lessThan(0.95));
      expect(find.bySemanticsLabel(RegExp(r'\d+%')), findsNothing);
      expect(find.text(AppStrings.uploadingDocuments), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('slow overlay explains navigation does not cancel the request', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingOverlay(isLoading: true, child: Text('Payment form')),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 16));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(AppStrings.requestStillPending), findsOneWidget);
    expect(find.text(AppStrings.goBack), findsOneWidget);
    expect(find.text('Cancel & Go Back'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'ordinary saves use only their button, even with upload-style copy',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormPageBody(
              isSaving: true,
              savingLabel: AppStrings.savingProgramAndDocuments,
              onSave: () {},
              onCancel: () {},
              child: const TextField(),
            ),
          ),
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(OperationFeedback), findsNothing);
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.savingClinicalRecord), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    },
  );
}
