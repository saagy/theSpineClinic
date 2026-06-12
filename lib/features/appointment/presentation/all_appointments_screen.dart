/// Management screen listing all appointments across doctors and branches.
///
/// Accessible to admin and receptionist roles only. Supports combinable
/// filters: date range, doctor, branch, status, and patient name search.
/// Infinite-scroll pagination loads 30 items at a time.
///
/// Rule 9 — handles loading, error, empty, and data states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/all_appointments_filter_bar.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Full-screen management view of all appointments with infinite-scroll pagination.
class AllAppointmentsScreen extends ConsumerStatefulWidget {
  /// Creates an [AllAppointmentsScreen].
  const AllAppointmentsScreen({super.key});

  @override
  ConsumerState<AllAppointmentsScreen> createState() => _AllAppointmentsScreenState();
}

class _AllAppointmentsScreenState extends ConsumerState<AllAppointmentsScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(allAppointmentsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Staff? user = ref.watch(currentUserProvider).value;
    if (user == null || (user.role != UserRole.superAdmin && user.role != UserRole.receptionist)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const ErrorView(
          exception: UnknownException(message: AppStrings.accessDeniedAdminReceptionOnly),
        ),
      );
    }

    final AsyncValue<List<AppointmentWithPatient>> appointmentsAsync =
        ref.watch(allAppointmentsProvider);
    final List<Staff> doctors = ref.watch(activeDoctorsProvider).value ?? [];
    final AllAppointmentsNotifier notifier = ref.read(allAppointmentsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(AppStrings.allAppointments, style: AppTextStyles.headingSmall),
      ),
      body: Column(
        children: [
          AllAppointmentsFilterBar(
            dateFrom: notifier.dateFrom,
            dateTo: notifier.dateTo,
            selectedDoctorId: notifier.doctorId,
            branchFilter: _parseClinic(notifier.clinic),
            statusFilter: _parseStatus(notifier.status),
            doctors: doctors,
            onSearchChanged: notifier.searchPatient,
            onPickDate: (bool isFrom) => _pickDate(notifier, isFrom),
            onDoctorChanged: notifier.setDoctorFilter,
            onBranchChanged: (ClinicLocation? c) => notifier.setClinicFilter(c?.dbValue),
            onStatusChanged: (AppointmentStatus? s) => notifier.setStatusFilter(s?.dbValue),
            onClear: notifier.clearAll,
          ),
          Expanded(child: _buildBody(appointmentsAsync)),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<AppointmentWithPatient>> async) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (Object error, StackTrace _) => ErrorView(
        exception: UnknownException(message: '$error'),
        onRetry: () => ref.read(allAppointmentsProvider.notifier).clearAll(),
      ),
      data: (List<AppointmentWithPatient> items) {
        if (items.isEmpty) {
          return const EmptyState(
            message: AppStrings.noAppointmentsFound,
            icon: Icons.event_busy_rounded,
          );
        }
        final bool loadingMore = ref.watch(isLoadingMoreProvider);
        return ListView.builder(
          controller: _scrollCtrl,
          itemCount: items.length + (loadingMore ? 1 : 0),
          itemBuilder: (_, int index) {
            if (index == items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
                child: Center(
                  child: SizedBox(
                    width: AppSizes.iconDefault,
                    height: AppSizes.iconDefault,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSizes.strokeWidthThin,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }
            final AppointmentWithPatient item = items[index];
            return DataListTile(
              title: item.patient.fullName,
              subtitle: '${item.appointment.type.displayLabel} · '
                  '${item.appointment.status.displayLabel} · '
                  '${Formatters.formatDateMedium(item.appointment.scheduledAt.toLocal())}',
              onTap: () => context.push(
                AppRoutes.appointmentDetail.replaceAll(':id', item.appointment.id),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate(AllAppointmentsNotifier notifier, bool isFrom) async {
    final DateTime initial = isFrom
        ? (notifier.dateFrom ?? DateTime.now().subtract(const Duration(days: 30)))
        : (notifier.dateTo ?? DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      if (isFrom) {
        notifier.setDateFrom(picked);
      } else {
        notifier.setDateTo(picked.add(const Duration(days: 1)));
      }
    }
  }

  ClinicLocation? _parseClinic(String? dbValue) {
    if (dbValue == null) return null;
    return ClinicLocation.values.cast<ClinicLocation?>().firstWhere(
          (c) => c!.dbValue == dbValue,
          orElse: () => null,
        );
  }

  AppointmentStatus? _parseStatus(String? dbValue) {
    if (dbValue == null) return null;
    return AppointmentStatus.values.cast<AppointmentStatus?>().firstWhere(
          (s) => s!.dbValue == dbValue,
          orElse: () => null,
        );
  }
}
