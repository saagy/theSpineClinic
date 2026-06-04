import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_balance_chip.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_appointments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_documents.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_info.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_payments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_records.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Top-level orchestrator screen for patient details.
class PatientDetailScreen extends ConsumerWidget {
  /// Creates a [PatientDetailScreen].
  const PatientDetailScreen({super.key, required this.patientId});

  /// The unique patient identifier path parameter.
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Patient> asyncPatient =
        ref.watch(patientDetailProvider(patientId));

    return asyncPatient.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) {
        final exception = error is AppException
            ? error
            : const UnknownException(message: AppStrings.errorDatabaseQueryFailed);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
          ),
          backgroundColor: AppColors.background,
          body: ErrorView(
            exception: exception,
            onRetry: () => ref.invalidate(patientDetailProvider(patientId)),
          ),
        );
      },
      data: (patient) => DefaultTabController(
        length: 5,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            title: Text(patient.fullName, style: AppTextStyles.headingSmall),
            bottom: const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              isScrollable: true,
              tabs: [
                Tab(text: 'Info'),
                Tab(text: 'Appointments'),
                Tab(text: 'Records'),
                Tab(text: 'Payments'),
                Tab(text: 'Documents'),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildHeader(patient),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              Expanded(
                child: TabBarView(
                  children: [
                    PatientTabInfo(patient: patient),
                    PatientTabAppointments(patient: patient),
                    PatientTabRecords(patient: patient),
                    PatientTabPayments(patient: patient),
                    PatientTabDocuments(patient: patient),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Patient patient) {
    final bool isTagamoa = patient.clinic == ClinicLocation.tagamoa;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppBadge(
            label: patient.clinic.displayLabel,
            textColor: isTagamoa ? AppColors.primary : AppColors.info,
            backgroundColor: isTagamoa ? AppColors.primaryLight : AppColors.infoBg,
          ),
          PatientBalanceChip(balance: patient.packageBalance),
        ],
      ),
    );
  }
}
