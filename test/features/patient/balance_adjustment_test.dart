import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import '../../fixtures/balance_adjustment_fixture.dart';
import '../../fixtures/workspace_harness.dart';

const _t = AppStrings.balances;

Future<void> _openPayments(WidgetTester tester, WorkspaceHarness harness) async {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(harness);
  await tester.pumpAndSettle();
  final tab = find.text(AppStrings.payments).first;
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the front desk sees past corrections but cannot adjust', (tester) async {
    await _openPayments(tester, const WorkspaceHarness(role: 'reception'));
    expect(find.text(_t.adjust), findsNothing);
    expect(find.text(_t.history), findsOneWidget);
    expect(find.text('Carried over from the paper file'), findsOneWidget);
  });

  testWidgets('payment staff correct a balance with a reason', (tester) async {
    final repo = FakeBalanceAdjustmentRepository();
    await _openPayments(tester, WorkspaceHarness(role: 'reception-payments', balances: repo));
    await tester.ensureVisible(find.text(_t.adjust));
    await tester.tap(find.text(_t.adjust));
    await tester.pumpAndSettle();
    expect(find.text(_t.title), findsOneWidget);

    // Nothing changed yet: refused before any request.
    await tester.enterText(find.byType(TextFormField).at(2), 'Old file');
    await tester.tap(find.text(_t.save));
    await tester.pumpAndSettle();
    expect(find.text(_t.noChange), findsOneWidget);
    expect(repo.calls, isEmpty);

    // A reason is required.
    await tester.enterText(find.byType(TextFormField).at(0), '6');
    await tester.enterText(find.byType(TextFormField).at(2), '  ');
    await tester.tap(find.text(_t.save));
    await tester.pumpAndSettle();
    expect(find.text(_t.reasonRequired), findsOneWidget);
    expect(repo.calls, isEmpty);

    await tester.enterText(find.byType(TextFormField).at(2), 'Two sessions from the paper file');
    await tester.tap(find.text(_t.save));
    await tester.pumpAndSettle();
    expect(repo.calls.single, {
      'expected': [4, 2],
      'new': [6, 2],
      'reason': 'Two sessions from the paper file',
    });
    expect(find.text(_t.title), findsNothing);
    expect(find.text(_t.saved), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
