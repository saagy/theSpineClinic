import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/utils/money.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/payments/data/billing_report_repository_impl.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_report.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_report_data.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_pdf.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_view.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_views.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_screen.dart';
import '../../fixtures/billing_report_fixture.dart';
import '../../fixtures/service_catalog_fixture.dart';
import '../../fixtures/test_supabase_service.dart';

const t = AppStrings.billingReports;

BillingReportFilterController controller(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(BillingScreen)),
).read(billingReportFilterControllerProvider.notifier);

void main() {
  test('periods resolve to inclusive clinic days', () {
    final now = DateTime(2026, 3, 1, 15, 30);
    ReportRange of(ReportPeriod period) => ReportRange.of(period, now);
    expect(of(ReportPeriod.today), ReportRange(DateTime(2026, 3, 1), DateTime(2026, 3, 1)));
    expect(of(ReportPeriod.yesterday).from, DateTime(2026, 2, 28));
    expect(of(ReportPeriod.last7Days).from, DateTime(2026, 2, 23));
    expect(of(ReportPeriod.thisMonth), ReportRange(DateTime(2026, 3, 1), DateTime(2026, 3, 1)));
    expect(of(ReportPeriod.lastMonth), ReportRange(DateTime(2026, 2, 1), DateTime(2026, 2, 28)));
    expect(ReportRange(DateTime(2025, 1, 1), DateTime(2026, 1, 2)).isValid, isTrue);
    expect(ReportRange(DateTime(2025, 1, 1), DateTime(2026, 1, 3)).isValid, isFalse);
    expect(ReportRange(DateTime(2026, 1, 2), DateTime(2026, 1, 1)).isValid, isFalse);
  });

  test('queries send the doctor only to reports that use one', () {
    final range = ReportRange(DateTime(2026, 11, 1), DateTime(2026, 11, 11));
    final revenue = BillingReportQuery(
      kind: BillingReportKind.revenue,
      range: range,
      branch: ClinicLocation.masrElgedida,
      doctorId: 'd1',
    );
    expect(revenue.toParams(invoiceKind: 'doctor'), {
      'p_kind': 'doctor',
      'p_from': '2026-11-01',
      'p_to': '2026-11-11',
      'p_branch': 'masr_elgedida',
      'p_doctor': 'd1',
    });
    const filter = BillingReportFilter(kind: BillingReportKind.services, doctorId: 'd1');
    expect(
      filter.query(DateTime(2026, 11, 11)).toParams(invoiceKind: 'services')['p_doctor'],
      isNull,
    );
    expect(revenue.isSingleDay, isFalse);
    expect(
      BillingReportQuery(
        kind: BillingReportKind.money,
        range: ReportRange(range.to, range.to),
      ).isSingleDay,
      isTrue,
    );
  });

  test('revenue reads lines and the doctor split together, or one doctor', () async {
    final kinds = <Object?>[];
    final repo = BillingReportRepositoryImpl(
      TestSupabaseService((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        kinds.add(body['p_kind']);
        final json = switch (body['p_kind']) {
          'doctors' => doctorsJson,
          'doctor' => revenueJson(doctor: true),
          _ => revenueJson(),
        };
        return http.Response(jsonEncode(json), 200, headers: {'content-type': 'application/json'});
      }),
    );
    final range = ReportRange(DateTime(2026, 11, 1), DateTime(2026, 11, 11));
    final all = await repo.report(
      BillingReportQuery(kind: BillingReportKind.revenue, range: range),
    );
    final report = all.when(
      success: (data) => data as RevenueReport,
      failure: (error) => throw error,
    );
    expect(kinds, unorderedEquals(['revenue', 'doctors']));
    expect(report.forDoctor, isFalse);
    expect(report.byDoctor!.rows, hasLength(3));
    kinds.clear();
    final one = await repo.report(
      BillingReportQuery(kind: BillingReportKind.revenue, range: range, doctorId: 'd1'),
    );
    expect(kinds, ['doctor']);
    expect(
      one.when(success: (data) => (data as RevenueReport).totalMinor, failure: (_) => 0),
      210000,
    );
  });

  test('money in & out nets cash and Visa and says how', () {
    final report = MoneyReport.fromJson(moneyJson());
    expect(report.netCashMinor, 555000);
    expect(report.netVisaMinor, 420000);
    expect(report.rows[4].signedMinor, -65000);
    final view = buildReportView(report);
    expect(
      [for (final figure in view.figures) (figure.label, figure.value)],
      [(t.cash, '5,550 EGP'), (t.visa, '4,200 EGP'), (t.total, '9,750 EGP')],
    );
    expect(view.figures.first.caption, t.inOut('7,350 EGP', '1,800 EGP'));
    final movements = view.sections.first.sheet;
    expect(movements.rows[4].cells.last.text, '− 650 EGP');
    expect(movements.rows.first.cells[1].sub, AppStrings.patientIdLabel(1040));
    expect(movements.rows.first.cells[2].text, t.receipt);
    expect(movements.rows.first.cells[2].sub, 'TG-00100');
    expect(view.sections.map((section) => section.title), [
      t.sectionMovements,
      t.sectionStaff,
      t.sectionVoids,
    ]);
    expect(view.sections[1].sheet.rows.first.cells[1].text, '2,550 EGP');
    // One day: rows show the time only.
    expect(
      buildReportView(report, singleDay: true).sections.first.sheet.columns.first.label,
      t.colTime,
    );
    expect(movements.columns.first.label, t.colWhen);
    // One receptionist adds nothing to the totals above.
    final json = moneyJson();
    json['staff'] = [(json['staff'] as List).first];
    expect(
      buildReportView(MoneyReport.fromJson(json)).sections.map((section) => section.title),
      isNot(contains(t.sectionStaff)),
    );
  });

  test("revenue shows the split by doctor above every line, or one doctor's share", () {
    final all = buildReportView(parseReport(BillingReportKind.revenue, revenueJson()));
    expect(all.figures.first.label, t.totalRevenue);
    expect(all.sections.map((section) => section.title), [t.sectionByDoctor, t.sectionAllocations]);
    final doctors = all.sections.first.sheet;
    expect(doctors.rows.first.doctor, (id: 'd1', name: 'Dr. Ahmed Hassan'));
    expect(doctors.rows.last.cells.first.text, t.noDoctor);
    expect(doctors.rows.last.doctor, isNull);
    expect(doctors.footer!.last.text, '5,733.33 EGP');
    final lines = all.sections.last.sheet;
    expect(
      [for (final column in lines.columns) column.label],
      [t.colWhen, t.colPatient, t.colService, t.colDoctors, t.colMethod, t.colPrice, t.paid],
    );
    expect(lines.rows.first.cells[3].text, 'Dr. Ahmed Hassan, Dr. Salma Ibrahim');
    expect(lines.rows[2].cells[3].text, t.noDoctor);

    final one = buildReportView(
      parseReport(BillingReportKind.revenue, revenueJson(doctor: true), oneDoctor: true),
    );
    expect(one.figures.first.label, t.doctorShare);
    expect(one.figures.first.value, '2,100 EGP');
    final sheet = one.sections.single.sheet;
    expect(
      [for (final column in sheet.columns) column.label],
      [t.colWhen, t.colPatient, t.colService, t.colMethod, t.colPrice, t.paid, t.colShare],
    );
    expect(sheet.rows.first.cells[2].sub, t.splitBetween(2));
    expect(sheet.rows.last.cells.last.text, '− 900 EGP');
  });

  test('money a refund moved between services reads as a refund adjustment', () {
    final json = revenueJson();
    final rows = json['rows'] as List<Map<String, dynamic>>;
    rows[3] = {...rows[3], 'method': null, 'amount_minor': -30000};
    rows.add({...rows[2], 'kind': 'refund', 'method': null, 'amount_minor': 30000});
    final doctors = Map<String, dynamic>.of(doctorsJson);
    doctors['rows'] = [
      for (final row in doctorsJson['rows'] as List<Map<String, dynamic>>)
        {...row, 'moved_minor': row['doctor_id'] == null ? 30000 : -15000},
    ];
    final view = buildReportView(
      RevenueReport.fromJson(json, byDoctor: DoctorTotals.fromJson(doctors)),
    );
    // Adjustments add up to zero across the clinic: no figure for them.
    expect(view.figures.map((figure) => figure.label), isNot(contains(t.moved)));
    expect(view.sections.first.sheet.columns.map((column) => column.label), contains(t.movedShort));
    final lines = view.sections.last.sheet.rows;
    expect(lines[3].cells[4].text, t.movedShort);
    expect(lines.last.cells[4].text, t.movedShort);
  });

  test('services and unpaid use plain words and keep the patient ID', () {
    final services = buildReportView(parseReport(BillingReportKind.services, servicesJson));
    expect(services.figures.map((figure) => figure.label), [
      t.totalPrice,
      t.paid,
      t.notPaidYet,
      t.unitsSold,
    ]);
    final rows = services.sections.single.sheet.rows;
    expect(rows.first.detail!.rows, hasLength(2));
    expect(rows.first.cells.first.text, '6 PT sessions');
    expect(rows.first.detail!.rows.first.cells[2].sub, AppStrings.patientIdLabel(1040));
    final outstanding = buildReportView(
      parseReport(BillingReportKind.outstanding, outstandingJson),
    );
    expect(outstanding.figures.first.tone, ReportTone.warning);
    final first = outstanding.sections.single.sheet.rows.first;
    expect(first.cells[1].text, 'Oct 2, 2026');
    expect(first.cells[0].sub, AppStrings.patientIdLabel(1042));
    // Unpaid money by age: 0–30, 31–60, 61–90, over 90 days, then the total.
    expect(first.cells.skip(3).take(4).map((cell) => cell.text), [
      Money.format(50000),
      Money.format(150000),
      Money.format(0),
      Money.format(0),
    ]);
    expect(first.cells[4].tone, ReportTone.warning);
    expect(first.cells[5].tone, ReportTone.muted);
    expect(outstanding.sections.single.sheet.footer![4].text, Money.format(150000));
  });

  testWidgets('a report prints as an A4 document', (tester) async {
    final view = buildReportView(MoneyReport.fromJson(moneyJson(count: 120)));
    final bytes = await tester.runAsync(
      () => BillingReportPdf.render(
        title: t.money,
        period: 'Nov 11, 2026',
        scope: t.allBranches,
        view: view,
      ),
    );
    expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
  });

  testWidgets('money in & out shows totals, payments, receptionists and cancellations', (
    tester,
  ) async {
    final repo = FakeBillingReportRepository();
    await pumpBilling(tester, repo: repo);
    expect(repo.queries.single.kind, BillingReportKind.money);
    expect(repo.queries.single.range, ReportRange.of(ReportPeriod.today, DateTime.now()));
    expect(find.widgetWithText(Tab, t.revenue), findsOneWidget);
    // The figure and the receptionists' total row.
    expect(find.text('5,550 EGP'), findsNWidgets(2));
    expect(find.text(reportUnbroken(t.inOut('7,350 EGP', '1,800 EGP'))), findsOneWidget);
    expect(find.text(t.sectionMovements), findsOneWidget);
    expect(find.text('− 650 EGP'), findsOneWidget);
    expect(find.text(t.sectionStaff), findsOneWidget);
    expect(find.text('Entered twice by mistake at the front desk'), findsOneWidget);
    await tester.tap(find.text('TG-00100'));
    await tester.pumpAndSettle();
    expect(find.text('invoice invoice-0'), findsOneWidget);
  });

  testWidgets('period and branch changes request a new report', (tester) async {
    final repo = FakeBillingReportRepository();
    await pumpBilling(tester, repo: repo, width: 390);
    await tester.tap(find.text(t.today));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.lastMonth).last);
    await tester.pumpAndSettle();
    expect(repo.queries.last.range, ReportRange.of(ReportPeriod.lastMonth, DateTime.now()));
    await tester.tap(find.text(t.allBranches));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.clinicTagamoa).last);
    await tester.pumpAndSettle();
    expect(repo.queries.last.branch, ClinicLocation.tagamoa);
    expect(find.text('Sara Ahmed Mostafa'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phones choose the report from one menu instead of tabs', (tester) async {
    final repo = FakeBillingReportRepository();
    await pumpBilling(tester, repo: repo, width: 390);
    expect(find.byType(Tab), findsNothing);
    await openReport(tester, t.outstanding);
    expect(repo.queries.last.kind, BillingReportKind.outstanding);
    expect(find.text(t.outstanding), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a doctor narrows revenue to them; clearing shows everyone', (tester) async {
    final repo = FakeBillingReportRepository();
    await pumpBilling(tester, repo: repo, height: 2000);
    await openReport(tester, t.revenue);
    expect(repo.queries.last.kind, BillingReportKind.revenue);
    expect(repo.queries.last.doctorId, isNull);
    expect(find.text(t.sectionByDoctor), findsOneWidget);
    await tester.tap(find.text('Dr. Ahmed Hassan').first);
    await tester.pumpAndSettle();
    expect(repo.queries.last.doctorId, 'd1');
    expect(find.text('2,100 EGP'), findsOneWidget);
    expect(find.text(t.sectionByDoctor), findsNothing);
    expect(
      find.textContaining(t.doctorHelp('Dr. Ahmed Hassan'), findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip(t.clearDoctor));
    await tester.pumpAndSettle();
    expect(repo.queries.last.doctorId, isNull);
    expect(find.text(t.allDoctors), findsOneWidget);
  });

  testWidgets('unpaid rows open the patient and services expand', (tester) async {
    await pumpBilling(tester, repo: FakeBillingReportRepository(), width: 390);
    await openReport(tester, t.services);
    expect(find.text('Omar Khaled'), findsNothing);
    await tester.tap(find.text('6 PT sessions'));
    await tester.pumpAndSettle();
    expect(find.text('Omar Khaled'), findsOneWidget);
    await openReport(tester, t.outstanding);
    expect(find.textContaining(t.asOfNow, findRichText: true), findsOneWidget);
    expect(find.text(t.today), findsNothing);
    await tester.tap(find.text('Mona Abdel Rahman El Sayed'));
    await tester.pumpAndSettle();
    expect(find.text('patient patient-2'), findsOneWidget);
  });

  testWidgets('long reports page through rows and flag capped data', (tester) async {
    final repo = FakeBillingReportRepository(
      json: {BillingReportKind.money: moneyJson(count: 120, rowCount: 9000)},
    );
    await pumpBilling(tester, repo: repo, height: 6000);
    expect(find.text(t.truncated(120, 9000)), findsOneWidget);
    expect(find.text('TG-00100'), findsOneWidget);
    expect(find.text('TG-00150'), findsNothing);
    await tester.tap(find.text(AppStrings.paginationNext));
    await tester.pumpAndSettle();
    expect(find.text('TG-00150'), findsOneWidget);
    expect(find.text('TG-00100'), findsNothing);
    expect(AppSizes.reportPageSize, 50);
  });

  testWidgets('the chosen report is still there after leaving Billing', (tester) async {
    final repo = FakeBillingReportRepository();
    await pumpBilling(tester, repo: repo);
    await openReport(tester, t.services);
    await tester.tap(find.text(AppStrings.invoices.services));
    await tester.pumpAndSettle();
    expect(find.text('services'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(repo.queries.last.kind, BillingReportKind.services);
    expect(controller(tester).state.kind, BillingReportKind.services);
  });

  testWidgets('an empty period, a failure and a retry are all explicit', (tester) async {
    final repo = FakeBillingReportRepository(
      json: {BillingReportKind.money: moneyJson(count: 0)..['voids'] = <Object>[]},
      failure: const Result.failure(NetworkException(code: 'network', message: 'offline')),
    );
    await pumpBilling(tester, repo: repo);
    expect(find.text(AppStrings.retry), findsOneWidget);
    expect(find.text(t.empty), findsNothing);
    repo.failure = null;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text(t.empty), findsOneWidget);
  });

  testWidgets('front desk receptionists cannot open reports', (tester) async {
    final repo = FakeBillingReportRepository();
    await pumpBilling(tester, repo: repo, user: frontDesk);
    expect(find.text(AppStrings.invoices.errorDenied), findsOneWidget);
    expect(find.text(t.money), findsNothing);
    expect(repo.queries, isEmpty);
  });
}
