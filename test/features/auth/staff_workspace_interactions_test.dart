import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_directory_tab.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_form_body.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import '../../fixtures/staff_workspace.dart';

class _Roster extends StaffList {
  _Roster(this.result);
  final Future<List<Staff>> result;
  @override
  Future<List<Staff>> build() => result;
}

class _Save extends StaffFormController {
  _Save({this.pending});
  final Completer<Result<void>>? pending;
  Staff? submitted;
  int calls = 0;
  @override
  Future<Result<void>> updateStaff({
    required Staff staff,
    String? newPassword,
  }) async {
    submitted = staff;
    calls++;
    if (pending != null) return pending!.future;
    return const Result.failure(UnknownException(message: 'Test save failure'));
  }
}

void main() {
  testWidgets(
    'staff save blocks duplicate submissions and returns after success',
    (tester) async {
      final pending = Completer<Result<void>>();
      final save = _Save(pending: pending);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/edit'),
                child: const Text('Open editor'),
              ),
            ),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, _) =>
                StaffFormBody(currentUser: staffAdmin, staff: staffAdmin),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [staffFormControllerProvider.overrideWith(() => save)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      tester
          .state<FormBuilderState>(find.byType(FormBuilder))
          .fields['full_name']!
          .didChange('Changed admin name');
      await tester.pump();
      final submit = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      submit();
      submit();
      await tester.pump();
      expect(save.calls, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(StaffFormBody), findsOneWidget);
      pending.complete(const Result.success(null));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.text('Open editor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'directory loading, error, empty and search results remain distinct',
    (tester) async {
      Future<void> show(Future<List<Staff>> result) async {
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            retry: (_, _) => null,
            overrides: [staffListProvider.overrideWith(() => _Roster(result))],
            child: const MaterialApp(home: StaffDirectoryTab()),
          ),
        );
        await tester.pump();
      }

      final pending = Completer<List<Staff>>();
      await show(pending.future);
      expect(find.byType(SkeletonTileList), findsOneWidget);
      pending.completeError(
        const UnknownException(message: 'Test load failure'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ErrorView), findsOneWidget);
      await show(Future.value([]));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.noStaff), findsOneWidget);
      await show(Future.value(staffRoster));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'no-such-person');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.noMatchingStaff), findsOneWidget);
    },
  );

  testWidgets(
    'edit failure keeps draft and self access controls stay disabled',
    (tester) async {
      final save = _Save();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [staffFormControllerProvider.overrideWith(() => save)],
          child: MaterialApp(
            home: StaffFormBody(currentUser: staffAdmin, staff: staffAdmin),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
      expect(
        tester
            .widget<FormBuilderDropdown<UserRole>>(
              find.byType(FormBuilderDropdown<UserRole>),
            )
            .enabled,
        isFalse,
      );
      expect(find.text(AppStrings.deactivateOnSave), findsNothing);
      expect(find.text(AppStrings.staffOwnAccessHelp), findsOneWidget);
      form.fields['full_name']!.didChange('Updated Admin Name');
      await tester.pump();
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(save.submitted?.fullName, 'Updated Admin Name');
      expect(save.submitted?.role, UserRole.superAdmin);
      expect(save.submitted?.isActive, isTrue);
      expect(form.fields['full_name']!.value, 'Updated Admin Name');
      expect(find.text(AppStrings.errorUnknown), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
