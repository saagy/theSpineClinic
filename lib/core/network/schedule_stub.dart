import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Temporary stub screen for doctor schedule view.
class ScheduleStub extends ConsumerWidget {
  /// Creates a [ScheduleStub].
  const ScheduleStub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Doctor Schedule Screen (Stub)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AppButton(
              labelText: 'Log Out',
              onPressed: () async {
                await ref.read(currentUserProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}
