import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/new_invoice_screen.dart';
import 'package:spine_clinic_app/features/payments/presentation/service_catalog_providers.dart';
import 'service_catalog_fixture.dart';
import 'staff_editor_harness.dart';
import 'workspace_data.dart';

const patientPage = 'Patient page';

/// The new-invoice route with a stand-in patient page to return to.
Future<GlobalKey> pumpNewInvoice(
  WidgetTester tester, {
  required FakeInvoiceRepository repo,
  required Staff user,
  double width = 1280,
  bool dark = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final String id = workspacePatient.id;
  final router = GoRouter(
    initialLocation: '/patient/$id',
    routes: [
      GoRoute(
        path: AppRoutes.patientDetail,
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push(AppRoutes.newInvoiceLocation(id)),
              child: const Text(patientPage),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.newInvoice,
        builder: (_, state) => NewInvoiceScreen(patientId: state.pathParameters['id']!),
      ),
    ],
  );
  addTearDown(router.dispose);
  final key = GlobalKey();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      invoiceRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWith(() => StaffEditorUser(user)),
      patientDetailProvider(id).overrideWith((ref) async => workspacePatient),
      patientAssignedDoctorsProvider(id).overrideWith((ref) async => [workspaceStaff('doctor')]),
      patientIsEmptyProvider(id).overrideWith((ref) async => false),
    ],
    child: RepaintBoundary(
      key: key,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: dark ? AppTheme.dark(clinicalBluePaletteDark) : AppTheme.light(clinicalBluePaletteLight),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text(patientPage));
  await tester.pumpAndSettle();
  return key;
}
