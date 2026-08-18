import 'package:flutter/material.dart';
import 'package:spine_clinic_app/features/auth/presentation/login_screen.dart';

/// Direct route entry point for registration (delegates to unified [LoginScreen]).
class RegisterScreen extends StatelessWidget {
  /// Creates a [RegisterScreen].
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialRegister: true);
  }
}
