/// Tab-shell combining today's appointments and all-appointments views
/// under a single [TabBar] with "Today" and "All" tabs.
///
/// Rendered inside the [AppShell] body for the `/appointments` route.
/// Intended for admin and receptionist roles only.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/home_screen.dart';

/// Thin shell with a top [TabBar] switching between today and all appointments.
class AppointmentsShell extends StatelessWidget {
  /// Creates an [AppointmentsShell].
  const AppointmentsShell({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: AppColors.surface,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.bodyBold,
              unselectedLabelStyle: AppTextStyles.bodyMedium,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2,
              tabs: const [
                Tab(text: AppStrings.today),
                Tab(text: AppStrings.allAppointments),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                HomeScreen(),
                AllAppointmentsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
