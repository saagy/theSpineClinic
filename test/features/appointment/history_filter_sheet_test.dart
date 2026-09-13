import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_history_provider.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/history_filter_content.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_sheet.dart';

class _History extends DoctorHistoryNotifier {
  @override
  DoctorHistoryState build() => DoctorHistoryState(
    isLoading: false,
    dateFrom: DateTime(2026, 9, 12),
    dateTo: DateTime(2026, 9, 13),
  );
}

void main() {
  testWidgets('history filter preserves inclusive end date through sheet round trip', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [doctorHistoryProvider.overrideWith(_History.new)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showHistoryFilters(context, ref),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final sheet = tester.widget<AppointmentFilterSheet>(find.byType(AppointmentFilterSheet));
    expect(sheet.initialDateTo, DateTime(2026, 9, 14));
    expect(sheet.showStatusFilter, isFalse);
    await tester.tap(find.text(AppStrings.applyFilters));
    await tester.pumpAndSettle();
    expect(container.read(doctorHistoryProvider).dateTo, DateTime(2026, 9, 13));
    expect(container.read(doctorHistoryProvider).dateFrom, DateTime(2026, 9, 12));
    expect(tester.takeException(), isNull);
  });
}
