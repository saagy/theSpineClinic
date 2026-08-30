import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/file_display_helper.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_gallery_viewer_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_media_card.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_media_reel.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';

class _FakeDocumentsRepository implements PatientDocumentsRepository {
  _FakeDocumentsRepository(this.documents);

  final List<PatientDocument> documents;

  @override
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId) async {
    return Result.success(documents);
  }

  @override
  Future<Result<Uint8List>> downloadDocumentBytes({
    required String fileUrl,
    required String fileName,
  }) async {
    return Result.success(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
        'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
  }

  @override
  Future<Result<void>> deleteDocument({required String documentId}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deletePatientStorageFolder(String patientId) =>
      throw UnimplementedError();

  @override
  Future<Result<PatientDocument>> renameDocument({
    required String documentId,
    required String fileName,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<PatientDocument>> uploadDocument({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
    String? programId,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('FileDisplayHelper Tests', () {
    test('sanitizes Unix timestamp prefixes', () {
      const raw = '1780936664913_Screenshot 2026-01-06 070326.png';
      expect(
        FileDisplayHelper.sanitizeFileName(raw),
        'Screenshot 2026-01-06 070326.png',
      );
    });

    test('sanitizes UUID prefixes', () {
      const raw = 'd41d8cd9-8f00-4b11-b0e6-5272a0f8b1c4_report.pdf';
      expect(FileDisplayHelper.sanitizeFileName(raw), 'report.pdf');
    });

    test('identifies PDF and Image extensions accurately', () {
      expect(FileDisplayHelper.isPdf('scan.pdf'), isTrue);
      expect(FileDisplayHelper.isPdf('scan.PNG'), isFalse);
      expect(FileDisplayHelper.isImage('scan.png'), isTrue);
      expect(FileDisplayHelper.isImage('scan.jpg'), isTrue);
      expect(FileDisplayHelper.isImage('scan.pdf'), isFalse);
    });

    test('returns clean uppercase extension badges', () {
      expect(FileDisplayHelper.getExtensionBadge('xray.png'), 'PNG');
      expect(FileDisplayHelper.getExtensionBadge('mri.jpg'), 'JPG');
      expect(FileDisplayHelper.getExtensionBadge('report.pdf'), 'PDF');
    });
  });

  group('ProgramMediaUI Widget Tests', () {
    final testDocs = [
      PatientDocument(
        id: 'doc-1',
        patientId: 'patient-1',
        fileUrl: 'https://example.com/scan1.png',
        fileName: '1780936664913_Cervical_MRI.png',
        uploadedAt: DateTime(2026, 8, 30),
      ),
      PatientDocument(
        id: 'doc-2',
        patientId: 'patient-1',
        fileUrl: 'https://example.com/doc2.pdf',
        fileName: 'Referral_Letter.pdf',
        uploadedAt: DateTime(2026, 8, 30),
      ),
    ];

    testWidgets('ProgramMediaCard displays sanitized name and PDF badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientDocumentsRepositoryProvider.overrideWithValue(
              _FakeDocumentsRepository(testDocs),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProgramMediaCard(
                document: testDocs[0],
              ),
            ),
          ),
        ),
      );

      // Should display sanitized name without '1780936664913_' prefix
      expect(find.text('Cervical_MRI.png'), findsOneWidget);
      expect(find.text('1780936664913_Cervical_MRI.png'), findsNothing);
    });

    testWidgets('ProgramMediaReel renders scan count and triggers onTap', (
      tester,
    ) async {
      int? tappedIndex;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientDocumentsRepositoryProvider.overrideWithValue(
              _FakeDocumentsRepository(testDocs),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProgramMediaReel(
                documents: testDocs,
                onOpenDocument: (index) => tappedIndex = index,
              ),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.imagingAttachments), findsOneWidget);
      expect(find.text('2 Scans'), findsOneWidget);
      expect(find.text('Cervical_MRI.png'), findsOneWidget);
      expect(find.text('Referral_Letter.pdf'), findsOneWidget);

      await tester.tap(find.text('Referral_Letter.pdf'));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(1));
    });

    testWidgets(
      'ProgramGalleryViewerScreen navigates via swipe and keyboard',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              patientDocumentsRepositoryProvider.overrideWithValue(
                _FakeDocumentsRepository(testDocs),
              ),
            ],
            child: MaterialApp(
              home: ProgramGalleryViewerScreen(
                documents: testDocs,
                initialIndex: 0,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1 of 2'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
        expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);

        // Swipe to next document
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(find.text('2 of 2'), findsOneWidget);

        // Navigate back using Left arrow key
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        expect(find.text('1 of 2'), findsOneWidget);
      },
    );

    testWidgets(
      'ProgramGalleryViewerScreen.open pushes gallery and close button returns to previous screen',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/program-detail',
          routes: [
            GoRoute(
              path: '/program-detail',
              builder: (context, _) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => ProgramGalleryViewerScreen.open(
                      context,
                      documents: testDocs,
                      initialIndex: 0,
                    ),
                    child: const Text('Open Gallery'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.galleryViewer,
              builder: (_, state) {
                final args = state.extra as ProgramGalleryViewerArgs?;
                return ProgramGalleryViewerScreen(
                  documents: args?.documents ?? const [],
                  initialIndex: args?.initialIndex ?? 0,
                  title: args?.title ?? AppStrings.imagingAttachments,
                );
              },
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              patientDocumentsRepositoryProvider.overrideWithValue(
                _FakeDocumentsRepository(testDocs),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Open Gallery'), findsOneWidget);
        expect(find.byType(ProgramGalleryViewerScreen), findsNothing);

        // Tap open gallery
        await tester.tap(find.text('Open Gallery'));
        await tester.pumpAndSettle();

        expect(find.byType(ProgramGalleryViewerScreen), findsOneWidget);

        // Tap close button (X)
        await tester.tap(find.byTooltip(AppStrings.close));
        await tester.pumpAndSettle();

        // Should return back to /program-detail cleanly
        expect(find.byType(ProgramGalleryViewerScreen), findsNothing);
        expect(find.text('Open Gallery'), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, '/program-detail');
      },
    );
  });
}
