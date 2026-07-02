import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_live_summary_strip.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_mode_selector.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_package_credit_section.dart';
import 'package:spine_clinic_app/shared/widgets/reason_chips_row.dart';

void main() {
  testWidgets('reason picker reports selected option', (tester) async {
    String selected = AppStrings.paymentReasonNormalPtSession;
    await tester.pumpWidget(
      _Host(
        child: StatefulBuilder(
          builder: (context, setState) {
            return ReasonChipsRow(
              options: const [
                AppStrings.paymentReasonNormalPtSession,
                AppStrings.paymentReasonOther,
              ],
              selected: selected,
              onChanged: (value) => setState(() => selected = value),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.paymentReasonOther));
    await tester.pump();

    expect(selected, AppStrings.paymentReasonOther);
  });

  testWidgets('payment mode selector toggles partial mode', (tester) async {
    bool isPartial = false;
    await tester.pumpWidget(
      _Host(
        child: StatefulBuilder(
          builder: (context, setState) {
            return PaymentModeSelector(
              isPartial: isPartial,
              onChanged: (value) => setState(() => isPartial = value),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.partialPaymentMode).last);
    await tester.pump();

    expect(isPartial, isTrue);
  });

  testWidgets('live summary shows remaining due', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: PaymentLiveSummaryStrip(
          amount: 75,
          amountLabel: AppStrings.amountToCollect,
          remainingDue: 25,
        ),
      ),
    );

    expect(find.text(AppStrings.remainingDue), findsOneWidget);
    expect(find.text('25 EGP'), findsOneWidget);
  });

  testWidgets('assessment disables package credit fields', (tester) async {
    final sessionCtrl = TextEditingController();
    final tractionCtrl = TextEditingController();
    addTearDown(sessionCtrl.dispose);
    addTearDown(tractionCtrl.dispose);

    await tester.pumpWidget(
      _Host(
        child: PaymentPackageCreditSection(
          addToPackage: false,
          isAssessment: true,
          enabled: true,
          onChanged: (_) {},
          sessionController: sessionCtrl,
          tractionController: tractionCtrl,
        ),
      ),
    );

    expect(find.text(AppStrings.addBalanceAssessmentDisabled), findsOneWidget);
    expect(find.text(AppStrings.sessionBalanceAddedField), findsNothing);
  });
}

class _Host extends StatelessWidget {
  const _Host({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    );
  }
}
