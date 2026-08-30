import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_condition.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';

class _FakeProgramRepository implements ProgramRepository {
  final List<PatientProgram> programs = [];

  @override
  Future<Result<List<PatientProgram>>> getProgramsForPatient(
    String patientId,
  ) async {
    return Result.success(
      programs.where((p) => p.patientId == patientId).toList(),
    );
  }

  @override
  Future<Result<PatientProgram?>> getProgramById(String programId) async {
    final match = programs.where((p) => p.id == programId).firstOrNull;
    return Result.success(match);
  }

  @override
  Future<Result<PatientProgram>> createProgram({
    required String patientId,
    required List<String> conditionIds,
    String? examination,
    String? imagingNotes,
    String? exaggeratingPositions,
    String? relievingPositions,
    String? notes,
    List<ProgramAttachment>? pendingAttachments,
  }) async {
    final newProg = PatientProgram(
      id: 'program-${programs.length + 1}',
      patientId: patientId,
      createdBy: 'senior-doc-1',
      status: ProgramStatus.active,
      examination: examination,
      imagingNotes: imagingNotes,
      exaggeratingPositions: exaggeratingPositions,
      relievingPositions: relievingPositions,
      notes: notes,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      conditions: conditionIds
          .map(
            (cId) => ProgramCondition(
              id: 'pc-$cId',
              programId: 'program-${programs.length + 1}',
              conditionId: cId,
              condition: ConditionCatalog(
                id: cId,
                region: BodyRegion.shoulder,
                conditionName: 'Rotator cuff tendinopathy',
              ),
            ),
          )
          .toList(),
    );
    programs.add(newProg);
    return Result.success(newProg);
  }

  @override
  Future<Result<PatientProgram>> updateProgram({
    required String programId,
    required List<String> conditionIds,
    String? examination,
    String? imagingNotes,
    String? exaggeratingPositions,
    String? relievingPositions,
    String? notes,
    ProgramStatus? status,
    List<ProgramAttachment>? pendingAttachments,
  }) async {
    final index = programs.indexWhere((p) => p.id == programId);
    if (index < 0) {
      return const Result.failure(
        NotFoundException(message: 'Program not found'),
      );
    }
    final updated = programs[index].copyWith(
      examination: examination ?? programs[index].examination,
      imagingNotes: imagingNotes ?? programs[index].imagingNotes,
      exaggeratingPositions:
          exaggeratingPositions ?? programs[index].exaggeratingPositions,
      relievingPositions:
          relievingPositions ?? programs[index].relievingPositions,
      notes: notes ?? programs[index].notes,
      status: status ?? programs[index].status,
    );
    programs[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<void>> updateProgramStatus({
    required String programId,
    required ProgramStatus status,
  }) async {
    final index = programs.indexWhere((p) => p.id == programId);
    if (index >= 0) {
      programs[index] = programs[index].copyWith(status: status);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deleteProgram(String programId) async {
    programs.removeWhere((p) => p.id == programId);
    return const Result.success(null);
  }
}

class _StaticCurrentUser extends CurrentUser {
  _StaticCurrentUser(this._user);
  final Staff? _user;

  @override
  Future<Staff?> build() async => _user;
}

void main() {
  final seniorDoctor = Staff(
    id: 'staff-senior-1',
    fullName: 'Dr. Senior',
    email: 'senior@spineclinic.com',
    role: UserRole.doctor,
    isSenior: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final juniorDoctor = Staff(
    id: 'staff-junior-1',
    fullName: 'Dr. Junior',
    email: 'junior@spineclinic.com',
    role: UserRole.doctor,
    isSenior: false,
    createdAt: DateTime(2026, 1, 1),
  );

  test('PatientProgram derives affectedRegions correctly from conditions', () {
    final program = PatientProgram(
      id: 'p1',
      patientId: 'pat1',
      createdBy: 'doc1',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      conditions: [
        ProgramCondition(
          id: 'pc1',
          programId: 'p1',
          conditionId: 'c1',
          condition: const ConditionCatalog(
            id: 'c1',
            region: BodyRegion.shoulder,
            conditionName: 'Rotator cuff',
          ),
        ),
        ProgramCondition(
          id: 'pc2',
          programId: 'p1',
          conditionId: 'c2',
          condition: const ConditionCatalog(
            id: 'c2',
            region: BodyRegion.lumbarSpine,
            conditionName: 'Disc Herniation L4-L5',
          ),
        ),
        ProgramCondition(
          id: 'pc3',
          programId: 'p1',
          conditionId: 'c3',
          condition: const ConditionCatalog(
            id: 'c3',
            region: BodyRegion.shoulder,
            conditionName: 'Impingement',
          ),
        ),
      ],
    );

    expect(
      program.affectedRegions,
      containsAll([BodyRegion.shoulder, BodyRegion.lumbarSpine]),
    );
    expect(program.affectedRegions.length, equals(2));
  });

  test('ProgramController blocks non-senior doctors from creating programs', () async {
    final fakeRepo = _FakeProgramRepository();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          () => _StaticCurrentUser(juniorDoctor),
        ),
        programRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    await container.read(currentUserProvider.future);

    final result = await container
        .read(programControllerProvider.notifier)
        .createProgram(
          patientId: 'patient-1',
          conditionIds: ['cond-1'],
        );

    expect(result.isFailure, isTrue);
  });

  test('ProgramController allows senior doctors to create and update programs in place', () async {
    final fakeRepo = _FakeProgramRepository();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          () => _StaticCurrentUser(seniorDoctor),
        ),
        programRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    await container.read(currentUserProvider.future);

    final result = await container
        .read(programControllerProvider.notifier)
        .createProgram(
          patientId: 'patient-1',
          conditionIds: ['cond-1'],
          examination: 'Normal range of motion',
        );

    expect(result.isSuccess, isTrue);

    final programs =
        container.read(patientProgramsProvider('patient-1')).value;
    expect(programs, isNotNull);
    expect(programs!.length, equals(1));
    expect(programs.first.examination, equals('Normal range of motion'));
  });
}
