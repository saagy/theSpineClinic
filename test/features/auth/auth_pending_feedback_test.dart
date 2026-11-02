import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/login_screen.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';
import '../../previews/ui_polish_capture.dart';

class _DelayedLogin extends CurrentUser {
  final completed = Completer<void>();
  int calls = 0;
  @override
  Future<Staff?> build() async => null;
  @override
  Future<void> login(String email, String password) async {
    calls++;
    state = const AsyncLoading();
    await completed.future;
    state = AsyncError(
      const AuthException(
        code: 'auth/invalid-credentials',
        message: 'Invalid credentials',
      ),
      StackTrace.current,
    );
  }
}

void main() {
  setUpAll(loadPolishFonts);
  for (final width in [360.0, 1280.0]) {
    for (final dark in [false, true]) {
      testWidgets('login pending and failure at $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = _DelayedLogin();
        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [currentUserProvider.overrideWith(() => auth)],
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: dark
                    ? AppTheme.dark(clinicalBluePaletteDark)
                    : AppTheme.light(clinicalBluePaletteLight),
                home: const LoginScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'doctor@example.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'test-password',
        );
        await tester.tap(find.byType(AppButton));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(find.text(AppStringsAuth.signingIn), findsOneWidget);
        expect(find.byType(LoadingOverlay), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppButton),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byType(AppButton));
        await tester.tap(find.text(AppStringsAuth.register));
        expect(auth.calls, 1);
        expect(find.text(AppStringsAuth.welcomeBack), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capturePolish(
          tester,
          key,
          'login-pending-$width-${dark ? 'dark' : 'light'}',
        );
        auth.completed.complete();
        await tester.pumpAndSettle();
        expect(find.text(AppStringsAuth.signingIn), findsNothing);
        expect(find.text('doctor@example.com'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).last)
              .controller!
              .text,
          'test-password',
        );
        expect(
          tester.widget<AppButton>(find.byType(AppButton)).isLoading,
          isFalse,
        );
        expect(
          tester.widget<AppButton>(find.byType(AppButton)).onPressed,
          isNotNull,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
