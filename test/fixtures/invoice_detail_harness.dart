import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/network/app_page_transitions.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/correct_invoice_screen.dart';
import 'package:spine_clinic_app/features/payments/presentation/invoice_detail_screen.dart';
import 'package:spine_clinic_app/features/payments/presentation/refund_screen.dart';
import 'package:spine_clinic_app/features/payments/presentation/service_catalog_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'service_catalog_fixture.dart';
import 'staff_editor_harness.dart';
import 'workspace_data.dart';

const invoicePatientPage = 'Patient page';
const invoiceBillingPage = 'Billing page';

/// Opens an invoice from a stand-in patient page (or Billing page when
/// [fromBilling]), with the production page builders so the side panel,
/// refund and correction routes behave as shipped. The patient page shows
/// the workspace tab its link asked for.
Future<GlobalKey> pumpInvoiceDetail(
  WidgetTester tester, {
  required FakeInvoiceRepository repo,
  required Staff user,
  String invoiceId = 'invoice-42',
  double width = 1280,
  bool dark = false,
  double textScale = 1,
  bool fromBilling = false,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final String id = workspacePatient.id;
  String part(GoRouterState state, String name) => state.pathParameters[name]!;
  final router = GoRouter(
    initialLocation: fromBilling ? AppRoutes.billing : '/patient/$id',
    routes: [
      for (final (String path, String label) in [
        (AppRoutes.billing, invoiceBillingPage),
        (AppRoutes.patientDetail, invoicePatientPage),
      ])
        GoRoute(
          path: path,
          builder: (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => context.push(AppRoutes.invoiceDetailLocation(id, invoiceId)),
                    child: Text(label),
                  ),
                  if (state.uri.queryParameters['tab'] case final String tab) Text('tab: $tab'),
                ],
              ),
            ),
          ),
        ),
      GoRoute(
        path: AppRoutes.invoiceDetail,
        pageBuilder: (context, state) => overlayPage(
          key: state.pageKey,
          scrim: ClinicColors.of(context).overlayScrim,
          child: InvoiceDetailScreen(patientId: part(state, 'id'), invoiceId: part(state, 'invoiceId')),
        ),
      ),
      GoRoute(
        path: AppRoutes.invoiceRefund,
        builder: (_, state) => RefundScreen(patientId: part(state, 'id'), invoiceId: part(state, 'invoiceId')),
      ),
      GoRoute(
        path: AppRoutes.invoiceCorrect,
        builder: (_, state) =>
            CorrectInvoiceScreen(patientId: part(state, 'id'), invoiceId: part(state, 'invoiceId')),
      ),
    ],
  );
  addTearDown(router.dispose);
  final key = GlobalKey();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      invoiceRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWith(() => StaffEditorUser(user)),
      patientDetailProvider(id).overrideWith((ref) async => workspacePatient.copyWith(fileNumber: 107)),
      patientIsEmptyProvider(id).overrideWith((ref) async => false),
      allDoctorsForFilterProvider.overrideWith((ref) async => [workspaceStaff('doctor')]),
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
  await tester.tap(find.text(fromBilling ? invoiceBillingPage : invoicePatientPage));
  await tester.pumpAndSettle();
  return key;
}
