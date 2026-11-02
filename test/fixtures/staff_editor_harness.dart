import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/data/staff_repository.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_form_screen.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'staff_workspace.dart';

class StaffEditorRepository implements StaffRepository {
  Result<void> outcome = const Result.success(null);
  Result<int> upcoming = const Result.success(3);
  Completer<Result<void>>? pending;
  int writes = 0;
  int countCalls = 0;
  Staff? submitted;
  String? password;
  @override
  Future<Result<void>> updateStaff({
    required Staff staff,
    String? newPassword,
  }) async {
    writes++;
    submitted = staff;
    password = newPassword;
    return pending == null ? outcome : await pending!.future;
  }

  @override
  Future<Result<void>> createStaff({
    required String fullName,
    required String email,
    required UserRole role,
    required String password,
    required bool canManagePayments,
    bool isSenior = false,
    String? phone,
    ClinicLocation? branch,
  }) async {
    writes++;
    this.password = password;
    submitted = staffAdmin.copyWith(
      id: 'new',
      fullName: fullName,
      email: email,
      role: role,
      canManagePayments: canManagePayments,
      isSenior: isSenior,
      phone: phone,
      branch: branch,
    );
    return pending == null ? outcome : await pending!.future;
  }

  @override
  Future<Result<int>> countUpcomingAppointments(String staffId) async {
    countCalls++;
    return upcoming;
  }

  @override
  Future<Result<List<Staff>>> getAllStaff() async =>
      Result.success(staffRoster);
  @override
  Future<Result<List<Staff>>> getActiveDoctors() async =>
      Result.success([staffRoster[1]]);
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StaffEditorUser extends CurrentUser {
  StaffEditorUser(this.actor);
  final Staff? actor;
  @override
  Future<Staff?> build() async => actor;
}

Future<GoRouter> pumpStaffEditor(
  WidgetTester tester,
  StaffEditorRepository repository, {
  Staff? staff,
  Staff? actor,
  bool create = false,
  GlobalKey? captureKey,
  bool dark = false,
  double scale = 1,
}) async {
  final Staff admin = actor ?? staffAdmin;
  final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: Text(AppStrings.staffManagement)),
      ),
      GoRoute(
        path: '/edit',
        builder: (_, _) =>
            StaffFormScreen(staff: create ? null : staff ?? staffRoster[1]),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: ProviderScope(
        overrides: [
          staffRepositoryProvider.overrideWithValue(repository),
          currentUserProvider.overrideWith(() => StaffEditorUser(admin)),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: AppTheme.light(clinicalBluePaletteLight),
          darkTheme: AppTheme.dark(clinicalBluePaletteDark),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  router.push<void>('/edit');
  await tester.pumpAndSettle();
  return router;
}
