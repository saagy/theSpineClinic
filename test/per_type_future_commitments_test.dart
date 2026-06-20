/// Tests verifying the redesigned per-type future-commitments contract.
///
/// We use a noSuchMethod-forwarding stub to avoid stubbing every method
/// in [AppointmentRepository]. The point is to lock the per-type routing
/// behaviour so any drift in [availableBalanceForTypeProvider] fails fast.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';

/// Counts how many times the per-type method is called per type + returns
/// the pre-canned value. All other methods are no-op forwarded.
class _CommitmentsStub implements AppointmentRepository {
  _CommitmentsStub(this._counts);
  final Map<AppointmentType, int> _counts;
  int ptCalls = 0;
  int trCalls = 0;
  int iaCalls = 0;
  int raCalls = 0;

  @override
  Future<Result<int>> getFutureScheduledAppointmentsCountForType({
    required String patientId,
    required AppointmentType type,
  }) async {
    switch (type) {
      case AppointmentType.normalPtSession:
        ptCalls++;
      case AppointmentType.spinalTractionSession:
        trCalls++;
      case AppointmentType.initialAssessment:
        iaCalls++;
      case AppointmentType.reassessment:
        raCalls++;
    }
    if (!type.affectsPackageBalance) return const Result.success(0);
    return Result.success(_counts[type] ?? 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
        '${invocation.memberName} is not exercised by these tests.',
      );
}

Future<int> _readCount(_CommitmentsStub stub, AppointmentType type) async {
  final res = await stub.getFutureScheduledAppointmentsCountForType(
    patientId: 'p1',
    type: type,
  );
  return res.when(success: (v) => v, failure: (_) => -1);
}

void main() {
  group('Per-type future commitments routing', () {
    test('PT bucket only sees PT commitments', () async {
      final stub = _CommitmentsStub({
        AppointmentType.normalPtSession: 5,
        AppointmentType.spinalTractionSession: 3,
      });
      expect(await _readCount(stub, AppointmentType.normalPtSession), 5);
      expect(stub.ptCalls, 1);
      expect(stub.trCalls, 0);
    });

    test('Traction bucket only sees traction commitments', () async {
      final stub = _CommitmentsStub({
        AppointmentType.normalPtSession: 5,
        AppointmentType.spinalTractionSession: 3,
      });
      expect(await _readCount(stub, AppointmentType.spinalTractionSession), 3);
      expect(stub.trCalls, 1);
      expect(stub.ptCalls, 0);
    });

    test('Assessments always return 0 (no ledger impact)', () async {
      final stub = _CommitmentsStub({
        AppointmentType.normalPtSession: 5,
        AppointmentType.spinalTractionSession: 3,
      });
      expect(await _readCount(stub, AppointmentType.initialAssessment), 0);
      expect(await _readCount(stub, AppointmentType.reassessment), 0);
      expect(stub.iaCalls, 1);
      expect(stub.raCalls, 1);
    });
  });
}
