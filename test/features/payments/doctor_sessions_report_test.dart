import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_report.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_report_data.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_pdf.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_view.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_views.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_screen.dart';
import '../../fixtures/billing_report_fixture.dart';
import '../../fixtures/doctor_sessions_fixture.dart';

const t = AppStrings.billingReports;

DoctorSessionsReport parse({bool oneDoctor = false}) =>
    DoctorSessionsReport.fromJson(doctorSessionsJson(oneDoctor: oneDoctor), forDoctor: oneDoctor);

Future<void> openSessions(WidgetTester tester) => openReport(tester, t.sessions);

void main() {
  test('the sessions report asks doctor_session_report for dates, branch and doctor', () {
    final query = BillingReportQuery(
      kind: BillingReportKind.sessions,
      range: ReportRange(DateTime(2026, 10, 1), DateTime(2026, 10, 31)),
      doctorId: 'd1',
    );
    expect(query.toParams(), {
      'p_from': '2026-10-01',
      'p_to': '2026-10-31',
      'p_branch': null,
      'p_doctor': 'd1',
    });
    expect(BillingReportKind.sessions.usesDoctor, isTrue);
  });

  test('all doctors: counts per type, shared sessions and the print pack', () {
    final report = parse();
    expect(report.credits, 4);
    expect(report.sessions, 3);
    expect(report.linesOf('d1'), hasLength(3));
    final view = buildReportView(report);
    expect(
      [for (final figure in view.figures) (figure.label, figure.value)],
      [
        (t.checkedInSessions, '3'),
        (t.doctorsWorked, '2'),
        (t.sharedSessions, '1'),
        (t.notCheckedIn, '1'),
      ],
    );
    expect(view.figures.last.tone, ReportTone.warning);

    final summary = view.sections.first;
    expect(summary.note, t.sectionSharedNote);
    expect(
      [for (final column in summary.sheet.columns) column.label],
      [t.colDoctor, t.colPtSessions, t.colAssessments, t.colReassessments, t.notCheckedIn, t.total],
    );
    final ahmed = summary.sheet.rows.first;
    expect(
      [for (final cell in ahmed.cells) cell.text],
      ['Dr. Ahmed Hassan', '2', '1', '0', '0', '3'],
    );
    expect(ahmed.detail!.rows, hasLength(3));
    expect(ahmed.detail!.columns.last.label, t.colSharedWith);
    expect(ahmed.detail!.rows.first.cells.last.text, 'Dr. Mona Saeed');
    expect(ahmed.detail!.rows.first.location, '/patient/patient-12');
    final karim = summary.sheet.rows[1];
    expect(karim.detail, isNull);
    expect(karim.cells[4].tone, ReportTone.warning);
    expect(
      [for (final cell in summary.sheet.footer!) cell.text],
      [t.totalRow, '3', '1', '0', '', '4'],
    );

    final pending = view.sections[1];
    expect(pending.title, t.sectionPending);
    expect(pending.sheet.rows.single.cells.last.text, 'Dr. Karim Adel');

    final statements = view.sections.where((section) => section.printOnly).toList();
    expect(
      [for (final section in statements) section.title],
      [t.doctorStatement('Dr. Ahmed Hassan'), t.doctorStatement('Dr. Mona Saeed')],
    );
    expect(statements.every((section) => section.newPage), isTrue);
    expect(statements.first.note, t.statementNote(3, 2, 1, 0));
  });

  test('one doctor: their figures and session list, no shared note', () {
    final view = buildReportView(parse(oneDoctor: true));
    expect([for (final figure in view.figures) figure.value], ['3', '2', '1', '0', '0']);
    expect(view.figures.last.tone, ReportTone.normal);
    expect(view.sections.first.title, t.sectionSessions);
    expect(view.sections.first.sheet.rows, hasLength(3));
    expect(view.sections.any((section) => section.printOnly), isFalse);
    expect(view.sections[1].sheet.rows, isEmpty);
  });

  test('a doctor with no checked-in sessions still says so', () {
    final json = doctorSessionsJson(oneDoctor: true)
      ..['sessions'] = <Object>[]
      ..['rows'] = [
        {'doctor_id': 'd1', 'doctor_name': 'Dr. Ahmed Hassan', 'pending': 2, 'total': 0},
      ];
    final view = buildReportView(DoctorSessionsReport.fromJson(json, forDoctor: true));
    expect(view.sections.first.sheet.rows, isEmpty);
    expect(view.sections.first.emptyMessage, t.noDoctorSessions);
  });

  testWidgets('the payroll pack prints every doctor on their own pages', (tester) async {
    final view = buildReportView(parse());
    final bytes = await tester.runAsync(
      () => BillingReportPdf.render(
        title: t.sessions,
        period: 'Nov 1, 2026 – Nov 30, 2026',
        scope: t.allBranches,
        view: view,
      ),
    );
    expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
  });

  testWidgets('doctor sessions: summary, expandable sessions, warnings and one doctor', (
    tester,
  ) async {
    final repo = FakeBillingReportRepository();
    await pumpBilling(tester, repo: repo, width: 1280, height: 2000);
    await openSessions(tester);
    expect(repo.queries.last.kind, BillingReportKind.sessions);
    expect(repo.queries.last.doctorId, isNull);
    expect(find.text(t.sectionSessionDoctors), findsOneWidget);
    expect(find.text(t.sectionPending), findsOneWidget);
    expect(find.text('Nour Ibrahim'), findsOneWidget);
    // Statements are for print only.
    expect(find.text(t.doctorStatement('Dr. Ahmed Hassan')), findsNothing);
    expect(find.text('Laila Fawzy'), findsNothing);
    await tester.tap(find.text('Dr. Ahmed Hassan'));
    await tester.pumpAndSettle();
    expect(find.text('Laila Fawzy'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.hint == t.hideSessions,
      ),
      findsOneWidget,
    );

    ProviderScope.containerOf(
      tester.element(find.byType(BillingScreen)),
    ).read(billingReportFilterControllerProvider.notifier).setDoctor('d1', 'Dr. Ahmed Hassan');
    await tester.pumpAndSettle();
    expect(repo.queries.last.doctorId, 'd1');
    // A lone section needs no title.
    expect(find.text(t.sectionSessions), findsNothing);
    expect(find.text('Laila Fawzy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('doctor sessions stack on a phone', (tester) async {
    await pumpBilling(tester, repo: FakeBillingReportRepository(), width: 390, height: 2400);
    await openSessions(tester);
    expect(find.text('Dr. Mona Saeed'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
