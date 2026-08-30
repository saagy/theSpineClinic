import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_document_viewer_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_item.dart';
import 'package:spine_clinic_app/shared/widgets/app_file_viewer.dart';

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
  Future<Result<void>> deleteDocument({required String documentId}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> deletePatientStorageFolder(String patientId) {
    throw UnimplementedError();
  }

  @override
  Future<Result<PatientDocument>> renameDocument({
    required String documentId,
    required String fileName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<PatientDocument>> uploadDocument({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
    String? programId,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  final PatientDocument document = PatientDocument(
    id: 'document-1',
    patientId: 'patient-1',
    fileUrl: 'patient-1/document-1.png',
    fileName: 'xray.png',
    uploadedAt: DateTime(2026),
  );

  testWidgets('viewer route closes before the patient route', (
    WidgetTester tester,
  ) async {
    final GoRouter router = _router(document: document);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router: router, document: document));
    await tester.pumpAndSettle();

    expect(find.text('Shell navigation'), findsOneWidget);
    await tester.tap(find.byType(PatientDocumentItem));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/patient/patient-1/document/document-1',
    );
    expect(find.byType(AppFileViewer), findsOneWidget);
    expect(find.text('Shell navigation'), findsNothing);

    await tester.tap(find.byTooltip(AppStrings.close));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/patient/patient-1',
    );
    expect(find.byType(AppFileViewer), findsNothing);
    expect(find.text('Shell navigation'), findsOneWidget);
  });

  testWidgets('missing route document renders the empty state', (
    WidgetTester tester,
  ) async {
    final GoRouter router = _router(
      document: document,
      initialLocation: '/patient/patient-1/document/missing',
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router: router, document: document));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.documentNotFound), findsOneWidget);
  });
}

Widget _app({required GoRouter router, required PatientDocument document}) {
  return ProviderScope(
    overrides: [
      patientDocumentsRepositoryProvider.overrideWithValue(
        _FakeDocumentsRepository([document]),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

GoRouter _router({
  required PatientDocument document,
  String initialLocation = '/patient/patient-1',
}) {
  final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (_, __, Widget child) => Scaffold(
          body: child,
          bottomNavigationBar: const Text('Shell navigation'),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.patientDetail,
            builder: (_, __) => Center(
              child: SizedBox(
                width: 240,
                height: 320,
                child: PatientDocumentItem(document: document),
              ),
            ),
            routes: [
              GoRoute(
                parentNavigatorKey: rootKey,
                path: AppRoutes.patientDocumentViewer,
                builder: (_, GoRouterState state) =>
                    PatientDocumentViewerScreen(
                      patientId: state.pathParameters['id'] ?? '',
                      documentId: state.pathParameters['documentId'] ?? '',
                    ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
