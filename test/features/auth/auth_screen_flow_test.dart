import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/features/auth/presentation/login_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_segmented_tab.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/register_step_identity.dart';

void main() {
  group('AuthScreen & Flow UI Tests', () {
    testWidgets('AuthSegmentedTab renders both tabs and switches cleanly', (
      tester,
    ) async {
      bool isRegister = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AuthSegmentedTab(
                  isRegister: isRegister,
                  onTabChanged: (val) => setState(() => isRegister = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text(AppStringsAuth.signIn), findsOneWidget);
      expect(find.text(AppStringsAuth.register), findsOneWidget);

      // Tap Register tab
      await tester.tap(find.text(AppStringsAuth.register));
      await tester.pumpAndSettle();

      expect(isRegister, isTrue);

      // Tap Sign In tab
      await tester.tap(find.text(AppStringsAuth.signIn));
      await tester.pumpAndSettle();

      expect(isRegister, isFalse);
    });

    testWidgets('LoginScreen initial render displays login inputs without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStringsAuth.welcomeBack), findsOneWidget);
      expect(find.text(AppStrings.email), findsOneWidget);
      expect(find.text(AppStringsAuth.password), findsOneWidget);
      expect(find.text(AppStringsAuth.signIn), findsWidgets);
    });

    testWidgets('LoginScreen switches to Register mode and expands branch for receptionist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Register tab
      await tester.tap(find.text(AppStringsAuth.register));
      await tester.pumpAndSettle();

      // Should show Step 1 Identity
      expect(find.text(AppStringsAuth.stepIdentity), findsOneWidget);
      expect(find.text(AppStrings.fullName), findsOneWidget);
      expect(find.text(AppStrings.phone), findsOneWidget);
      expect(find.byType(RegisterStepIdentity), findsOneWidget);

      // Branch dropdown not visible for Doctor (default)
      expect(find.text(AppStrings.selectBranch), findsNothing);

      // Tap Receptionist role button
      await tester.tap(find.text(AppStrings.receptionistRoleLabel));
      await tester.pumpAndSettle();

      // Branch dropdown is now visible
      expect(find.text(AppStrings.branch), findsOneWidget);
      expect(find.text(AppStringsAuth.next), findsOneWidget);
    });
  });
}
