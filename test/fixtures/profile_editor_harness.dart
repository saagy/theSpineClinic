import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/auth_repository.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/edit_profile_screen.dart';
import 'workspace_data.dart';

class ProfileEditorRepository implements AuthRepository {
  Staff? user = workspaceStaff('doctor');
  bool failLoad = false;
  Completer<Staff?>? pendingLoad;
  Completer<Result<void>>? pendingWrite;
  Result<void> outcome = const Result.success(null);
  int profileWrites = 0;
  int passwordWrites = 0;
  Staff? savedProfile;
  String? savedPassword;

  @override
  bool get isAuthenticated => true;

  @override
  Future<Result<Staff?>> getCurrentUserStaffProfile() async {
    if (failLoad) {
      return const Result.failure(
        NetworkException(code: 'network/offline', message: 'Fixture offline'),
      );
    }
    return Result.success(
      pendingLoad == null ? user : await pendingLoad!.future,
    );
  }

  @override
  Future<Result<void>> updateStaffProfile({required Staff staff}) async {
    profileWrites++;
    savedProfile = staff;
    final Result<void> result =
        await (pendingWrite?.future ?? Future.value(outcome));
    if (result.isSuccess) user = staff;
    return result;
  }

  @override
  Future<Result<void>> changeOwnPassword(String password) async {
    passwordWrites++;
    savedPassword = password;
    return pendingWrite == null ? outcome : await pendingWrite!.future;
  }

  @override
  Future<Result<void>> signOut() async => const Result.success(null);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<GoRouter> pumpProfileEditor(
  WidgetTester tester,
  ProfileEditorRepository repository, {
  GlobalKey? captureKey,
  bool dark = false,
  double scale = 1,
  bool passwordOnly = false,
}) async {
  final GoRouter router = GoRouter(
    initialLocation: '/fixture-profile',
    routes: [
      GoRoute(
        path: '/fixture-profile',
        builder: (_, _) => Scaffold(
          body: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) => Text(
              ref.watch(currentUserProvider).value?.fullName ??
                  AppStrings.profile,
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, _) => const EditProfileScreen(),
        routes: [
          GoRoute(
            path: 'password',
            builder: (_, _) => const EditProfileScreen(passwordOnly: true),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
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
  router.push<void>(
    passwordOnly ? AppRoutes.profilePassword : AppRoutes.editProfile,
  );
  await tester.pumpAndSettle();
  return router;
}
