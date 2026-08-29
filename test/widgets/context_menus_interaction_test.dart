import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_item.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_note_item.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/payment_row.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

class _StaticCurrentUser extends CurrentUser {
  _StaticCurrentUser(this._user);
  final Staff? _user;

  @override
  Future<Staff?> build() async => _user;
}

void main() {
  final testStaff = Staff(
    id: 'staff-1',
    userId: 'user-1',
    fullName: 'Dr. Test Staff',
    email: 'staff@clinic.com',
    role: UserRole.superAdmin,
    canManagePayments: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final testPayment = PaymentRecord(
    id: 'payment-1',
    patientId: 'patient-1',
    amount: 500,
    sessionBalanceAdded: 5,
    tractionBalanceAdded: 0,
    reason: '5 Session Package',
    recordedAt: DateTime(2026, 1, 1, 10, 0),
    recordedBy: 'staff-1',
  );

  final testNote = PatientNote(
    id: 'note-1',
    patientId: 'patient-1',
    noteText: 'Patient is recovering well.',
    createdAt: DateTime(2026, 1, 1, 10, 0),
    updatedAt: DateTime(2026, 1, 1, 10, 0),
    createdBy: 'staff-1',
  );

  final testDocument = PatientDocument(
    id: 'doc-1',
    patientId: 'patient-1',
    fileName: 'mri_scan.pdf',
    fileUrl: 'https://example.com/mri_scan.pdf',
    uploadedAt: DateTime(2026, 1, 1, 10, 0),
  );

  Widget createHost({required Widget child}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(
          () => _StaticCurrentUser(testStaff),
        ),
        staffProfileProvider('staff-1').overrideWith(
          (ref) async => testStaff,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  group('PaymentRow Context Menu Interactions', () {
    testWidgets('Long press opens context menu with Edit and Delete without direct delete dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHost(
          child: PaymentRow(
            payment: testPayment,
            isAdmin: true,
            patientId: 'patient-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Long press on the payment card
      await tester.longPress(find.text('5 Session Package'));
      await tester.pumpAndSettle();

      // Ensure direct delete confirmation dialog is NOT shown
      expect(find.byType(ConfirmationDialog), findsNothing);

      // Ensure the touch-anchored context menu is visible with options
      expect(find.text(AppStrings.edit), findsWidgets);
      expect(find.text(AppStrings.delete), findsWidgets);
    });
  });

  group('PatientNoteItem Context Menu Interactions', () {
    testWidgets('Shows 3-dot menu and long press opens menu with Edit and Delete', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHost(
          child: PatientNoteItem(note: testNote),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the 3-dot action button is rendered (replacing bare delete button)
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

      // Long press on the note card text
      await tester.longPress(find.text('Patient is recovering well.'));
      await tester.pumpAndSettle();

      // Ensure direct delete confirmation dialog is NOT shown
      expect(find.byType(ConfirmationDialog), findsNothing);

      // Ensure context menu with Edit and Delete options opened
      expect(find.text(AppStrings.edit), findsWidgets);
      expect(find.text(AppStrings.delete), findsWidgets);
    });
  });

  group('PatientDocumentItem Context Menu Interactions', () {
    testWidgets('Long press on document card opens context menu with Rename and Delete', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHost(
          child: SizedBox(
            width: 200,
            height: 250,
            child: PatientDocumentItem(document: testDocument),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Long press on the document card
      await tester.longPress(find.text('mri_scan.pdf'));
      await tester.pumpAndSettle();

      // Ensure context menu with Rename and Delete options opened
      expect(find.text(AppStrings.rename), findsWidgets);
      expect(find.text(AppStrings.delete), findsWidgets);
    });
  });
}
