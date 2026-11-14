import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_report.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_report_data.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_screen.dart';
import 'service_catalog_fixture.dart';
import 'staff_editor_harness.dart';
import 'doctor_sessions_fixture.dart';

const _patients = [
  'Sara Ahmed Mostafa',
  'Omar Khaled',
  'Mona Abdel Rahman El Sayed',
  'Youssef Ali',
];

Map<String, dynamic> _party(int index) => {
  'patient_id': 'patient-${index % 4}',
  'patient_name': _patients[index % 4],
  'file_number': 1040 + index % 4,
  'invoice_id': 'invoice-$index',
  'invoice_number': 40 + index,
  'invoice_branch': index.isEven ? 'tagamoa' : 'masr_elgedida',
};

String _at(int index) =>
    DateTime.utc(2026, 11, 11, 7, index % 60).add(Duration(hours: index ~/ 6)).toIso8601String();

/// `invoice_report('money')` with [count] movements; every fifth is a payback.
Map<String, dynamic> moneyJson({int count = 6, int? rowCount}) => {
  'totals': {
    'cash_in_minor': 735000,
    'visa_in_minor': 420000,
    'cash_out_minor': 180000,
    'visa_out_minor': 0,
    'row_count': rowCount ?? count,
  },
  'staff': [
    {
      'staff_id': 's1',
      'name': 'Nour Mahmoud',
      'cash_in_minor': 435000,
      'visa_in_minor': 420000,
      'cash_out_minor': 180000,
      'visa_out_minor': 0,
    },
    {
      'staff_id': 's2',
      'name': 'Hana Farouk',
      'cash_in_minor': 300000,
      'visa_in_minor': 0,
      'cash_out_minor': 0,
      'visa_out_minor': 0,
    },
  ],
  'rows': [
    for (int index = 0; index < count; index++)
      {
        'kind': index % 5 == 4 ? 'refund' : 'receipt',
        'id': 'move-$index',
        'number': 100 + index,
        'branch': index.isEven ? 'tagamoa' : 'masr_elgedida',
        'moved_at': _at(index),
        'method': index % 3 == 1 ? 'visa' : 'cash',
        'amount_minor': 45000 + index * 5000,
        'recorded_by_name': index.isEven ? 'Nour Mahmoud' : 'Hana Farouk',
        ..._party(index),
      },
  ],
  'voids': [
    {
      'kind': 'receipt',
      'id': 'void-1',
      'number': 97,
      'branch': 'tagamoa',
      'amount_minor': 45000,
      'voided_at': _at(3),
      'voided_by_name': 'Nour Mahmoud',
      'void_reason': 'Entered twice by mistake at the front desk',
      ..._party(2),
    },
  ],
};

Map<String, dynamic> revenueJson({bool doctor = false}) => {
  'totals': {
    doctor ? 'share_minor' : 'collected_minor': doctor ? 210000 : 573333,
    'cash_minor': doctor ? 120000 : 253333,
    'visa_minor': doctor ? 90000 : 320000,
    'moved_minor': 0,
    'row_count': 4,
  },
  'rows': [
    for (final (index, (service, amount, method, kind)) in const [
      ('6 PT sessions', 240000, 'cash', 'receipt'),
      ('Initial assessment', 60000, 'visa', 'receipt'),
      ('6 spinal traction sessions', 135000, 'visa', 'receipt'),
      ('6 PT sessions', -180000, 'cash', 'refund'),
    ].indexed)
      {
        'allocation_id': index,
        'line_id': 'line-$index',
        'moved_at': _at(index),
        'kind': kind,
        'branch': 'tagamoa',
        'document_number': 100 + index,
        'method': method,
        'amount_minor': amount,
        'service_name': service,
        'price_minor': amount.abs(),
        'doctors': index == 2 ? <String>[] : ['Dr. Ahmed Hassan', 'Dr. Salma Ibrahim'],
        if (doctor) ...{'share_minor': amount ~/ 2, 'doctor_count': 2},
        ..._party(index),
      },
  ],
};

final doctorsJson = <String, dynamic>{
  'totals': {'share_minor': 573333, 'cash_minor': 253333, 'visa_minor': 320000, 'moved_minor': 0},
  'rows': [
    {
      'doctor_id': 'd1',
      'doctor_name': 'Dr. Ahmed Hassan',
      'share_minor': 286666,
      'cash_minor': 172380,
      'visa_minor': 114286,
      'moved_minor': 0,
    },
    {
      'doctor_id': 'd2',
      'doctor_name': 'Dr. Salma Ibrahim',
      'share_minor': 166667,
      'cash_minor': 52381,
      'visa_minor': 114286,
      'moved_minor': 0,
    },
    {
      'doctor_id': null,
      'doctor_name': null,
      'share_minor': 120000,
      'cash_minor': 28572,
      'visa_minor': 91428,
      'moved_minor': 0,
    },
  ],
};

final outstandingJson = <String, dynamic>{
  'totals': {'due_minor': 266667, 'open_invoices': 3, 'row_count': 2},
  'rows': [
    {
      'patient_id': 'patient-2',
      'patient_name': _patients[2],
      'file_number': 1042,
      'open_invoices': 2,
      'due_minor': 200000,
      'oldest_date': '2026-10-02',
    },
    {
      'patient_id': 'patient-1',
      'patient_name': _patients[1],
      'file_number': 1041,
      'open_invoices': 1,
      'due_minor': 66667,
      'oldest_date': '2026-11-09',
    },
  ],
};

final servicesJson = <String, dynamic>{
  'totals': {'units': 5, 'billed_minor': 640000, 'collected_minor': 573333, 'row_count': 3},
  'rows': [
    {
      'service_id': 'pt6',
      'service_name': '6 PT sessions',
      'service_type': 'pt_session',
      'units': 2,
      'invoice_count': 2,
      'billed_minor': 420000,
      'collected_minor': 420000,
    },
    {
      'service_id': 'tr6',
      'service_name': '6 spinal traction sessions',
      'service_type': 'traction_session',
      'units': 1,
      'invoice_count': 1,
      'billed_minor': 120000,
      'collected_minor': 120000,
    },
  ],
  'lines': [
    for (final (index, (service, billed)) in const [
      ('pt6', 300000),
      ('pt6', 120000),
      ('tr6', 120000),
    ].indexed)
      {
        'line_id': 'line-$index',
        'service_id': service,
        'service_type': 'pt_session',
        'quantity': 1,
        'billed_minor': billed,
        'collected_minor': billed,
        'invoice_date': '2026-11-0${index + 7}',
        'created_at': _at(index),
        ..._party(index),
      },
  ],
};

BillingReportData parseReport(
  BillingReportKind kind,
  Map<String, dynamic> json, {
  bool oneDoctor = false,
}) => switch (kind) {
  BillingReportKind.money => MoneyReport.fromJson(json),
  BillingReportKind.revenue =>
    oneDoctor
        ? RevenueReport.fromJson(json)
        : RevenueReport.fromJson(json, byDoctor: DoctorTotals.fromJson(doctorsJson)),
  BillingReportKind.sessions => DoctorSessionsReport.fromJson(json, forDoctor: oneDoctor),
  BillingReportKind.outstanding => OutstandingReport.fromJson(json),
  BillingReportKind.services => ServicesReport.fromJson(json),
};

class FakeBillingReportRepository implements BillingReportRepository {
  FakeBillingReportRepository({Map<BillingReportKind, Map<String, dynamic>>? json, this.failure})
    : json = json ?? {};

  /// Overrides per report; the rest use the sample data above.
  final Map<BillingReportKind, Map<String, dynamic>> json;

  /// Returned instead of data until cleared.
  Result<BillingReportData>? failure;
  final List<BillingReportQuery> queries = [];

  @override
  Future<Result<BillingReportData>> report(BillingReportQuery query) async {
    queries.add(query);
    if (failure != null) return failure!;
    final bool oneDoctor = query.doctorId != null;
    return Result.success(
      parseReport(
        query.kind,
        oneDoctor: oneDoctor,
        json[query.kind] ??
            switch (query.kind) {
              BillingReportKind.money => moneyJson(),
              BillingReportKind.revenue => revenueJson(doctor: oneDoctor),
              BillingReportKind.sessions => doctorSessionsJson(oneDoctor: oneDoctor),
              BillingReportKind.outstanding => outstandingJson,
              BillingReportKind.services => servicesJson,
            },
      ),
    );
  }
}

/// Opens a report from the tabs, or from the Report menu on narrow windows.
Future<void> openReport(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  if (tab.evaluate().isEmpty) {
    await tester.tap(find.byTooltip(AppStrings.billingReports.reportMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
  } else {
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
  }
  await tester.pumpAndSettle();
}

/// Pumps the Billing tab with real routing; pushed records are stand-ins.
Future<GlobalKey> pumpBilling(
  WidgetTester tester, {
  required FakeBillingReportRepository repo,
  Staff? user,
  double width = 1280,
  double height = 900,
  bool dark = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey();
  Widget stand(String name) => Scaffold(appBar: AppBar(), body: Text(name));
  final router = GoRouter(
    initialLocation: AppRoutes.billing,
    routes: [
      GoRoute(path: AppRoutes.billing, builder: (_, _) => const BillingScreen()),
      GoRoute(path: AppRoutes.serviceCatalog, builder: (_, _) => stand('services')),
      GoRoute(
        path: AppRoutes.patientDetail,
        builder: (_, state) => stand('patient ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoutes.invoiceDetail,
        builder: (_, state) => stand('invoice ${state.pathParameters['invoiceId']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingReportRepositoryProvider.overrideWithValue(repo),
        currentUserProvider.overrideWith(() => StaffEditorUser(user ?? cashier)),
      ],
      child: RepaintBoundary(
        key: key,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: dark
              ? AppTheme.dark(clinicalBluePaletteDark)
              : AppTheme.light(clinicalBluePaletteLight),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}
