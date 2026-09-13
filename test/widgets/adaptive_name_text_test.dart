import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/adaptive_name_text.dart';
import '../previews/ui_polish_capture.dart';

void main() {
  const name = 'Mohamed Ahmed';
  Future<void> show(WidgetTester tester, double width, {double scale = 1}) async {
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: Center(child: SizedBox(width: width,
        child: const AdaptiveNameText(name, style: AppTextStyles.bodyBold),
      ))),
    )));
    await tester.pumpAndSettle();
  }
  testWidgets('names stay normal when they fit and shrink only to the bounded floor', (tester) async {
    await loadPolishFonts();
    final painter = TextPainter(
      text: const TextSpan(text: name, style: AppTextStyles.bodyBold),
      textDirection: TextDirection.ltr,
    )..layout();
    final fullWidth = painter.width;
    painter.dispose();
    await show(tester, fullWidth + 10);
    expect(tester.widget<Text>(find.text(name)).style!.fontSize, 14);
    final fullHeight = tester.getSize(find.text(name)).height;
    await show(tester, fullWidth * 0.97);
    expect(tester.widget<Text>(find.text(name)).style!.fontSize, inInclusiveRange(13, 13.5));
    expect(tester.getSize(find.text(name)).height, lessThanOrEqualTo(fullHeight));
    await show(tester, fullWidth / 2);
    expect(tester.widget<Text>(find.text(name)).style!.fontSize, 13);
    expect(tester.getSize(find.text(name)).height, greaterThan(fullHeight));
    expect(tester.widget<Text>(find.text(name)).maxLines, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('enlarged accessibility text wraps without reducing the font', (tester) async {
    await show(tester, 100, scale: 1.8);
    final text = tester.widget<Text>(find.text(name));
    expect(text.style!.fontSize, AppTextStyles.bodyBold.fontSize);
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    expect(tester.takeException(), isNull);
  });
}
