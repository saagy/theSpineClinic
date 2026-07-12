import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/rename_document_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

class _TestCurrentUser extends CurrentUser {
  _TestCurrentUser(this.staff);

  final Staff staff;

  @override
  Future<Staff?> build() async => staff;
}

class _RenameRepository implements PatientDocumentsRepository {
  _RenameRepository(this.document, {this.shouldFail = false});

  PatientDocument document;
  final bool shouldFail;
  String? submittedName;

  @override
  Future<Result<List<PatientDocument>>> fetchDocuments(
    String patientId,
  ) async => Result.success([document]);

  @override
  Future<Result<PatientDocument>> renameDocument({
    required String documentId,
    required String fileName,
  }) async {
    submittedName = fileName;
    if (shouldFail) {
      return const Result.failure(
        DatabaseException(
          code: 'db/denied',
          message: 'Denied',
          userMessageKey: 'error_database_permission_denied',
        ),
      );
    }
    document = document.copyWith(fileName: fileName);
    return Result.success(document);
  }

  @override
  Future<Result<Uint8List>> downloadDocumentBytes({
    required String fileUrl,
    required String fileName,
  }) async => Result.success(Uint8List(0));

  @override
  Future<Result<PatientDocument>> uploadDocument({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> deleteDocument({required String documentId}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deletePatientStorageFolder(String patientId) =>
      throw UnimplementedError();
}

void main() {
  final PatientDocument document = PatientDocument(
    id: 'document-1',
    patientId: 'patient-1',
    fileUrl: 'https://example.test/scan.pdf',
    fileName: 'scan.pdf',
    uploadedAt: DateTime(2026),
  );
  final Staff staff = Staff(
    id: 'staff-1',
    fullName: 'Staff User',
    email: 'staff@example.test',
    role: UserRole.doctor,
    createdAt: DateTime(2026),
  );

  Future<Widget> app(_RenameRepository repository) async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(() => _TestCurrentUser(staff)),
        patientDocumentsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => RenameDocumentDialog(document: document),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  Finder renameButton() => find.byWidgetPredicate(
    (Widget widget) =>
        widget is AppButton && widget.labelText == AppStrings.rename,
  );

  testWidgets('prefills base name and keeps extension fixed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await app(_RenameRepository(document)));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('.pdf'), findsOneWidget);
    expect(find.text('scan'), findsOneWidget);
    expect(tester.widget<AppButton>(renameButton()).onPressed, isNull);
  });

  testWidgets('submits the renamed base with the original extension', (
    WidgetTester tester,
  ) async {
    final _RenameRepository repository = _RenameRepository(document);
    await tester.pumpWidget(await app(repository));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Updated scan');
    await tester.pump();
    await tester.tap(find.text(AppStrings.rename));
    await tester.pumpAndSettle();

    expect(repository.submittedName, 'Updated scan.pdf');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('keeps the dialog open when rename fails', (
    WidgetTester tester,
  ) async {
    final _RenameRepository repository = _RenameRepository(
      document,
      shouldFail: true,
    );
    await tester.pumpWidget(await app(repository));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Blocked rename');
    await tester.pump();
    await tester.tap(find.text(AppStrings.rename));
    await tester.pumpAndSettle();

    expect(repository.submittedName, 'Blocked rename.pdf');
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(AppStrings.errorDatabasePermissionDenied), findsOneWidget);
  });
}
