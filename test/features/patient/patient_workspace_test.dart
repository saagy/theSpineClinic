import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_appointments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_due.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_medical_history.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_programs.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_documents.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_gallery_viewer_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_summary_sidebar.dart';
import '../../fixtures/workspace_harness.dart';

void main() {
  Future<void> mount(WidgetTester tester, Widget child, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(child);
    await tester.pumpAndSettle();
  }

  for (final role in ['doctor', 'senior']) {
    testWidgets('$role sees clinical priorities without financial information', (tester) async {
      await mount(tester, WorkspaceHarness(role: role), const Size(1280, 1000));
      expect(find.text(AppStrings.totalOutstanding), findsNothing);
      expect(find.byType(WorkspaceDue), findsNothing);
      expect(
        find.descendant(of: find.byType(WorkspacePrograms), matching: find.text('Lumbar disc prolapse')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(WorkspacePrograms), matching: find.text('Cervical spondylosis')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.medicalHistory), findsOneWidget);
      final clinicalTop = tester.getTopLeft(find.byType(WorkspacePrograms)).dy;
      final historyTop = tester.getTopLeft(find.byType(WorkspaceMedicalHistory)).dy;
      expect(historyTop, greaterThan(clinicalTop));
      expect(tester.takeException(), isNull);
    });
  }

  for (final role in ['reception', 'reception-payments']) {
    testWidgets('$role prioritizes details and gates payment actions', (tester) async {
      await mount(tester, WorkspaceHarness(role: role), const Size(1280, 1000));
      expect(find.byType(PatientSummarySidebar), findsOneWidget);
      await tester.tap(find.text(AppStrings.payments));
      await tester.pumpAndSettle();
      expect(find.text('600 EGP'), findsWidgets);
      expect(
        find.text(AppStrings.recordPayment),
        role == 'reception-payments' ? findsOneWidget : findsNothing,
      );
      expect(find.text(AppStrings.collectDue), role == 'reception-payments' ? findsOneWidget : findsNothing);
      expect(find.text(AppStrings.totalOutstanding), findsWidgets);
      expect(find.text(AppStrings.totalPaid), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('long name and enlarged text fit a narrow window', (tester) async {
    await mount(tester, const WorkspaceHarness(longName: true, scale: 1.8), const Size(360, 900));
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing history is not presented as a negative clinical finding', (tester) async {
    await mount(tester, const WorkspaceHarness(empty: true), const Size(1280, 1000));
    expect(find.text(AppStrings.historyNotRecorded), findsOneWidget);
    expect(find.text(AppStrings.noConditionsRecorded), findsNothing);
    expect(find.text(AppStrings.totalOutstanding), findsNothing);
    expect(find.text(AppStrings.nextAppointment), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment failure leaves programs and history usable', (tester) async {
    await mount(
      tester,
      const WorkspaceHarness(role: 'reception', paymentError: true),
      const Size(1280, 1000),
    );
    expect(find.text(AppStrings.retry), findsOneWidget);
    expect(
      find.descendant(of: find.byType(WorkspacePrograms), matching: find.text('Lumbar disc prolapse')),
      findsOneWidget,
    );
    expect(find.text(AppStrings.medicalHistory), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('program navigation returns to the selected section', (tester) async {
    await mount(tester, const WorkspaceHarness(), const Size(1280, 1000));
    await tester.tap(find.text(AppStrings.programs).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lumbar disc prolapse'));
    await tester.pumpAndSettle();
    expect(find.text('program-0'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Cervical spondylosis'), findsOneWidget);
    expect(find.text(AppStrings.medicalHistory), findsNothing);
  });

  testWidgets('private image documents group into a program folder and open the gallery', (tester) async {
    await mount(tester, const WorkspaceHarness(), const Size(1280, 1000));
    await tester.tap(find.text(AppStrings.tabDocuments).first);
    await tester.pumpAndSettle();
    expect(find.text('Sample image.jpg'), findsNothing);
    expect(find.byType(DocumentThumbnail), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<MemoryImage>());
    await tester.tap(find.byType(DocumentThumbnail));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramGalleryViewerScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all appointments appear with dates and no disclosure', (tester) async {
    await mount(tester, const WorkspaceHarness(), const Size(1280, 1000));
    await tester.tap(find.text(AppStrings.appointments).first);
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(WorkspaceAppointments), matching: find.text('Dr. Mariam Khaled')), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text('Dr. Omar Salem'), findsOneWidget);
    expect(find.descendant(of: find.byType(WorkspaceAppointments), matching: find.text('Aug 12, 2026')), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.filterSort));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AppointmentFilterSheet), findsOneWidget);
    expect(find.text(AppStrings.allDates), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 1280.0]) {
    testWidgets('dated appointment rows use available width at $width', (tester) async {
      await mount(tester, const WorkspaceHarness(), Size(width, 900));
      expect(find.textContaining('Patient since'), findsNothing);
      await tester.ensureVisible(find.text(AppStrings.appointments).first);
      await tester.tap(find.text(AppStrings.appointments).first);
      await tester.pumpAndSettle();
      final rows = find.byType(AppointmentAgendaRow);
      expect(rows, findsNWidgets(2));
      final expectedWidth = width >= 960 ? (width - 320 - 48) : (width - 32);
      expect(tester.getSize(rows.first).width, expectedWidth);
      expect(find.descendant(of: find.byType(WorkspaceAppointments), matching: find.textContaining('Aug 12, 2026')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('archived programs remain behind an expandable row', (tester) async {
    await mount(tester, const WorkspaceHarness(), const Size(1280, 1000));
    await tester.tap(find.text(AppStrings.programs).first);
    await tester.pumpAndSettle();
    expect(find.text('Lumbar disc prolapse'), findsOneWidget);
    await tester.tap(find.text(AppStrings.archivedProgramsCount(1)));
    await tester.pumpAndSettle();
    expect(find.text('Lumbar disc prolapse'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow screen compact action and filter buttons match in size and have filled styling', (tester) async {
    await mount(tester, const WorkspaceHarness(), const Size(360, 900));
    await tester.ensureVisible(find.text(AppStrings.appointments).first);
    await tester.tap(find.text(AppStrings.appointments).first);
    await tester.pumpAndSettle();

    final filterBtnFinder = find.byTooltip(AppStrings.filterSort);
    final actionBtnFinder = find.byTooltip(AppStrings.bookAppointment);
    expect(filterBtnFinder, findsOneWidget);
    expect(actionBtnFinder, findsOneWidget);

    final filterSize = tester.getSize(filterBtnFinder);
    final actionSize = tester.getSize(actionBtnFinder);
    expect(actionSize, equals(filterSize));

    final actionButtonWidget = tester.widget<IconButton>(
      find.ancestor(of: actionBtnFinder, matching: find.byType(IconButton)),
    );
    final actionStyle = actionButtonWidget.style;
    final theme = Theme.of(tester.element(actionBtnFinder));
    expect(actionStyle?.backgroundColor?.resolve({}), equals(theme.colorScheme.primary));
    expect(actionStyle?.foregroundColor?.resolve({}), equals(theme.colorScheme.onPrimary));
  });
}
