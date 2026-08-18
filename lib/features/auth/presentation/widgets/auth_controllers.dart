import 'package:flutter/material.dart';

/// Encapsulated form keys and text editing controllers for the auth screen.
class AuthControllers {
  final GlobalKey<FormState> loginKey = GlobalKey<FormState>();
  final GlobalKey<FormState> regStep1Key = GlobalKey<FormState>();
  final GlobalKey<FormState> regStep2Key = GlobalKey<FormState>();

  final TextEditingController loginEmailCtrl = TextEditingController();
  final TextEditingController loginPasswordCtrl = TextEditingController();
  final TextEditingController regNameCtrl = TextEditingController();
  final TextEditingController regEmailCtrl = TextEditingController();
  final TextEditingController regPhoneCtrl = TextEditingController();
  final TextEditingController regPasswordCtrl = TextEditingController();
  final TextEditingController regConfirmCtrl = TextEditingController();

  /// Disposes all allocated text editing controllers.
  void dispose() {
    loginEmailCtrl.dispose();
    loginPasswordCtrl.dispose();
    regNameCtrl.dispose();
    regEmailCtrl.dispose();
    regPhoneCtrl.dispose();
    regPasswordCtrl.dispose();
    regConfirmCtrl.dispose();
  }
}
