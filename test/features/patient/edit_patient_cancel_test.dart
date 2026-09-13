import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/edit_patient_form.dart';
import '../../fixtures/workspace_data.dart';
import '../../fixtures/workspace_overrides.dart';

void main() {
  testWidgets('dirty edit asks once and leaves after confirming discard', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/edit',
          builder: (_, _) => EditPatientForm(patient: workspacePatient, assignedDoctors: const []),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWith(() => WorkspaceUser('reception'))],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/edit');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Changed name');
    await tester.pump();
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.discardChanges), findsOneWidget);
    await tester.tap(find.text(AppStrings.discard));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text(AppStrings.discardChanges), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
