/// Error scaffold widget for the Patient Detail screen.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

class PatientErrorScaffold extends StatelessWidget {
  const PatientErrorScaffold({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppException ex = error is AppException
        ? error as AppException
        : UnknownException(message: AppStrings.errorDatabaseQueryFailed);
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton()),
      body: ErrorView(exception: ex, onRetry: onRetry),
    );
  }
}
