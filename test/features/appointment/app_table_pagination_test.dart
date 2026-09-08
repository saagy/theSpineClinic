import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/app_table_pagination.dart';

void main() {
  group('AppTablePagination', () {
    testWidgets('displays correct range, page count, and button states',
        (tester) async {
      bool prevTapped = false;
      bool nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTablePagination(
              currentPage: 1,
              totalPages: 3,
              totalCount: 75,
              pageSize: 30,
              hasPrevious: false,
              hasNext: true,
              onPrevious: () => prevTapped = true,
              onNext: () => nextTapped = true,
              entityLabel: AppStrings.paginationAppointments,
            ),
          ),
        ),
      );

      // Verify text display: "Showing 1 to 30 of 75 appointments"
      expect(
        find.text(
          '${AppStrings.paginationShowing} 1 ${AppStrings.paginationTo} 30 ${AppStrings.paginationOf} 75 ${AppStrings.paginationAppointments}',
        ),
        findsOneWidget,
      );

      // Verify page text: "Page 1 of 3"
      expect(
        find.text('${AppStrings.paginationPage} 1 ${AppStrings.paginationOf} 3'),
        findsOneWidget,
      );

      // Verify Next button works
      await tester.tap(find.text(AppStrings.paginationNext));
      expect(nextTapped, isTrue);

      // Verify Previous button is disabled (hasPrevious: false)
      await tester.tap(find.text(AppStrings.paginationPrevious));
      expect(prevTapped, isFalse);
    });

    testWidgets('enables Previous button when on page > 1', (tester) async {
      bool prevTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTablePagination(
              currentPage: 2,
              totalPages: 3,
              totalCount: 75,
              pageSize: 30,
              hasPrevious: true,
              hasNext: true,
              onPrevious: () => prevTapped = true,
              onNext: () {},
              entityLabel: AppStrings.paginationAppointments,
            ),
          ),
        ),
      );

      await tester.tap(find.text(AppStrings.paginationPrevious));
      expect(prevTapped, isTrue);
    });
  });
}
