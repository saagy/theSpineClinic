import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_filter_sheet.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_list_filter_models.dart';

void main() {
  testWidgets('staff filters apply together, reset together, and discard drafts', (tester) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    StaffFilterSelection? result;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                child: const Text('Open'),
                onPressed: () async => result = await StaffFilterSheet.show(
                  context: context,
                  initialFilters: const StaffListFilters(),
                  initialSort: StaffSortOption.nameAsc,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> open() async {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    await open();
    await tester.tap(find.text(AppStrings.doctor));
    await tester.ensureVisible(find.text(AppStrings.sortNameDesc));
    await tester.tap(find.text(AppStrings.sortNameDesc));
    await tester.tap(find.text(AppStrings.applyFilters));
    await tester.pumpAndSettle();
    expect(result?.filters.role, UserRole.doctor);
    expect(result?.sort, StaffSortOption.nameDesc);
    await open();
    await tester.tap(find.text(AppStrings.doctor));
    await tester.tap(find.text(AppStrings.resetFilters));
    await tester.tap(find.text(AppStrings.applyFilters));
    await tester.pumpAndSettle();
    expect(result?.filters.activeCount, 0);
    expect(result?.sort, StaffSortOption.nameAsc);
    await open();
    await tester.tap(find.text(AppStrings.doctor));
    Navigator.of(tester.element(find.text(AppStrings.applyFilters))).pop();
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
