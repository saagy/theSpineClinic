import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/record_skeleton.dart';
import '../../fixtures/workspace_harness.dart';

void main() {
  testWidgets('horizontal tab scrolling preserves the patient record app bar', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WorkspaceHarness());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(TabBar), const Offset(-240, 0));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar), matching: find.text(AppStrings.patientRecord)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion swaps async content without size animation', (tester) async {
    Widget frame(String text) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: RecordTransition(child: Text(text)),
      ),
    );
    await tester.pumpWidget(frame('Loading'));
    await tester.pumpWidget(frame('Ready'));
    expect(find.text('Ready'), findsOneWidget);
    expect(find.byType(AnimatedSize), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
