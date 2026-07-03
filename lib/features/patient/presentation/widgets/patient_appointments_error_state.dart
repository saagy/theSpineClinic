import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

class PatientAppointmentsErrorState extends StatelessWidget {
  const PatientAppointmentsErrorState({
    super.key,
    required this.message,
    required this.onRefresh,
  });

  final String? message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final AppException ex = UnknownException(message: message ?? '');

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: ErrorView(exception: ex, onRetry: onRefresh),
          ),
        ),
      ),
    );
  }
}
