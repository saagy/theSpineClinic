import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_action.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_detail.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_draft.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_repository.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_summary.dart';
import 'package:spine_clinic_app/features/payments/domain/service_catalog_item.dart';
import 'package:spine_clinic_app/features/payments/presentation/service_catalog_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/service_catalog_screen.dart';
import 'package:spine_clinic_app/features/payments/presentation/service_form_screen.dart';
import 'invoice_fixture.dart';
import 'staff_editor_harness.dart';
import 'staff_workspace.dart';

final cashier = staffAdmin.copyWith(
  id: 'cashier', fullName: 'Nour Mahmoud', role: UserRole.receptionist, canManagePayments: true,
);
final frontDesk = cashier.copyWith(id: 'desk', canManagePayments: false);

ServiceCatalogItem service(String id, String name, ServiceType type, int price,
        {int sessions = 1, bool credit = true, bool active = true}) =>
    ServiceCatalogItem(id: id, name: name, type: type, sessionsPerUnit: sessions,
        priceMinor: price, creditsDoctors: credit, active: active, version: 1);

final catalogFixture = [
  service('pt1', 'PT session', ServiceType.ptSession, 45000),
  service('pt6', '6 PT sessions', ServiceType.ptSession, 240000, sessions: 6),
  service('pt12', '12 PT sessions', ServiceType.ptSession, 450000, sessions: 12, active: false),
  service('tr6', '6 spinal traction sessions', ServiceType.tractionSession, 135000,
      sessions: 6, credit: false),
  service('ia', 'Initial assessment', ServiceType.initialAssessment, 60000),
  service('sw', 'Shockwave therapy session for chronic plantar fasciitis', ServiceType.other, 70000),
];

class FakeInvoiceRepository implements InvoiceRepository {
  FakeInvoiceRepository({List<ServiceCatalogItem>? items, this.saveResult, this.createResult,
      List<InvoiceSummary>? invoices, this.details = const {}, this.actionResult})
      : items = items ?? catalogFixture,
        invoices = invoices ?? sampleInvoices;
  final List<ServiceCatalogItem> items;
  final List<InvoiceSummary> invoices;
  final Result<String>? saveResult;
  final Result<String>? createResult;
  final List<ServiceDraft> saved = [];
  final List<InvoiceDraft> created = [];

  /// Invoice documents by ID; tests replace entries to simulate a refresh.
  Map<String, InvoiceDetail> details;
  final Result<String>? actionResult;
  final List<InvoiceAction> actions = [];

  @override
  Future<Result<InvoiceDetail>> invoiceDetail(String invoiceId) async {
    final InvoiceDetail? detail = details[invoiceId];
    return detail == null
        ? const Result.failure(NotFoundException(message: 'Invoice not found'))
        : Result.success(detail);
  }

  @override
  Future<Result<String>> runAction(InvoiceAction action) async {
    actions.add(action);
    return actionResult ?? Result.success(action.invoice.id);
  }

  @override
  Future<Result<List<InvoiceSummary>>> patientInvoices(String patientId) async =>
      Result.success(invoices);

  @override
  Future<Result<String>> createInvoice(InvoiceDraft draft) async {
    created.add(draft);
    return createResult ?? const Result.success('invoice-new');
  }

  @override
  Future<Result<List<ServiceCatalogItem>>> services() async => Result.success(items);

  @override
  Future<Result<String>> saveService(ServiceDraft draft) async {
    saved.add(draft);
    return saveResult ?? const Result.success('new-service');
  }
}

/// Pumps the catalog with real routing so push, pop and redirects work.
Future<GlobalKey> pumpCatalog(
  WidgetTester tester, {
  required FakeInvoiceRepository repo,
  Staff? user,
  double width = 1280,
  bool dark = false,
  double textScale = 1,
  String location = AppRoutes.serviceCatalog,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey();
  final router = GoRouter(initialLocation: location, routes: [
    GoRoute(path: AppRoutes.serviceCatalog, builder: (_, _) => const ServiceCatalogScreen()),
    GoRoute(
      path: AppRoutes.serviceForm,
      builder: (_, state) {
        final id = state.pathParameters['id'];
        return ServiceFormScreen(serviceId: id == 'new' ? null : id);
      },
    ),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      invoiceRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWith(() => StaffEditorUser(user ?? cashier)),
    ],
    child: RepaintBoundary(
      key: key,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark(clinicalBluePaletteDark) : AppTheme.light(clinicalBluePaletteLight),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return key;
}
