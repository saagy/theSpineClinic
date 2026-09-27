import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'workspace_data.dart';

class TestUser extends CurrentUser {
  @override
  Future<Staff?> build() async => workspaceStaff('reception');
}

class TestBranch extends ActiveBranch {
  @override
  ClinicLocation build() => ClinicLocation.tagamoa;
  @override
  Future<void> setBranch(ClinicLocation location) async {
    state = location;
  }
}

class ScheduleRepo implements AppointmentRepository {
  final calls = <Invocation>[];
  final pending = <Completer<Result<List<AppointmentWithPatient>>>>[];
  @override
  Future<Result<List<AppointmentWithPatient>>> noSuchMethod(Invocation call) {
    if ((call.namedArguments[#offset] as int? ?? 0) > 0) {
      return Future.value(const Result.success([]));
    }
    calls.add(call);
    final request = Completer<Result<List<AppointmentWithPatient>>>();
    pending.add(request);
    return request.future;
  }
}

Future<void> settle(ProviderContainer container) async {
  await container.pump();
  await Future<void>.delayed(Duration.zero);
  await container.pump();
}
