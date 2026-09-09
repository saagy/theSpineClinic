import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_condition.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';

final workspacePatient = Patient(
  id: 'patient-fixture',
  fullName: 'Nour Ahmed Hassan',
  phoneNumber: '01000000000',
  clinic: ClinicLocation.tagamoa,
  sessionBalance: 4,
  tractionBalance: 2,
  createdAt: DateTime(2026, 8, 12),
  nextVisitDate: DateTime.now().add(const Duration(days: 1)),
);
Staff workspaceStaff(String role) => Staff(
  id: 'staff-fixture',
  fullName: role.contains('reception') ? 'Salma Mostafa' : 'Dr. Mariam Khaled',
  email: 'fixture@example.invalid',
  role: role.contains('reception') ? UserRole.receptionist : UserRole.doctor,
  isSenior: role == 'senior',
  canManagePayments: role == 'reception-payments',
  createdAt: DateTime(2026, 1, 1),
);
final workspaceHistory = PatientMedicalHistory(
  id: 'history-fixture',
  patientId: workspacePatient.id,
  hasDiabetes: true,
  hba1cValue: '6.5%',
  hasHypertension: true,
  additionalNotes: 'Previous knee surgery, 2021. No other surgical history reported.',
  createdAt: DateTime(2026, 8, 12),
  updatedAt: DateTime(2026, 9, 6),
);
final workspacePrograms = [
  for (int i = 0; i < 2; i++)
    PatientProgram(
      id: 'program-$i',
      patientId: workspacePatient.id,
      createdBy: 'staff-fixture',
      createdAt: DateTime(2026, 8, 12 + i),
      updatedAt: DateTime(2026, 9, 6),
      conditions: [
        ProgramCondition(
          id: 'link-$i',
          programId: 'program-$i',
          conditionId: 'condition-$i',
          condition: ConditionCatalog(
            id: 'condition-$i',
            region: i == 0 ? BodyRegion.lumbarSpine : BodyRegion.cervicalSpine,
            conditionName: i == 0 ? 'Lumbar disc prolapse' : 'Cervical spondylosis',
          ),
        ),
      ],
      treatmentPlans: [
        TreatmentPlan(
          id: 'plan-$i',
          programId: 'program-$i',
          createdBy: 'staff-fixture',
          planName: i == 0 ? 'Lumbar stabilization · Plan 2' : 'Cervical mobility · Plan 1',
          createdAt: DateTime(2026, 8, 12),
          updatedAt: DateTime(2026, 9, 6),
        ),
      ],
    ),
];
final workspacePayments = [
  PaymentRecord(
    id: 'payment-1',
    patientId: workspacePatient.id,
    amount: 1200,
    totalPrice: 1800,
    reason: 'Normal PT package',
    sessionBalanceAdded: 6,
    recordedAt: DateTime(2026, 9, 1),
  ),
  PaymentRecord(
    id: 'payment-2',
    patientId: workspacePatient.id,
    amount: 600,
    reason: 'Spinal traction',
    tractionBalanceAdded: 3,
    recordedAt: DateTime(2026, 8, 25),
  ),
];
final workspaceDocuments = [
  PatientDocument(
    id: 'doc-1',
    patientId: workspacePatient.id,
    programId: 'program-0',
    fileName: 'Lumbar MRI report.pdf',
    fileUrl: 'https://example.invalid/report.pdf',
    uploadedAt: DateTime(2026, 8, 12),
  ),
  PatientDocument(
    id: 'doc-2',
    patientId: workspacePatient.id,
    programId: 'program-1',
    fileName: 'Sample image.jpg',
    fileUrl: 'patient-fixture/private-image.png',
    thumbnailUrl: 'patient-fixture/private-image.png',
    uploadedAt: DateTime(2026, 8, 25),
  ),
];
