/// Full detail view for a single appointment.
///
/// Handles four states: loading, error, empty, and data.
/// Delegates to extracted sub-widgets for header, doctors, and actions.
///
/// Rule 9 — four strict UI states handled via AsyncValue.when.
/// Rule 1 — under 200 lines by delegating to sub-widgets.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_action_buttons.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_detail_header.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_doctors_section.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_banner.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/detail_overflow_button.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_notes_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_schedule_card.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';

/// Screen displaying the full detail view for a single appointment.
class AppointmentDetailScreen extends ConsumerStatefulWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  late final ScrollController _scrollController;
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final bool show = _scrollController.offset > 60;
    if (show != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = show;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentId = widget.appointmentId;
    final AsyncValue<AppointmentDetailState> detailAsync =
        ref.watch(appointmentDetailControllerProvider(appointmentId));
    final detailState = detailAsync.value;
    final user = ref.watch(currentUserProvider).value;
    final bool showEdit = detailState != null && user != null;
    final bool showDelete = detailState != null &&
        user != null &&
        user.role != UserRole.doctor &&
        (detailState.appointment.status == AppointmentStatus.scheduled ||
         detailState.appointment.status == AppointmentStatus.cancelled);
    final String? patientName = detailState?.patient.fullName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        leading: const AppBackButton(),
        centerTitle: false,
        title: patientName != null
            ? AnimatedOpacity(
                opacity: _showAppBarTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  patientName,
                  style: AppTextStyles.headingSmall.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : const SizedBox.shrink(),
        actions: [
          if (showEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
              onPressed: () {
                context.push(
                  AppRoutes.editAppointment.replaceAll(':id', detailState.appointment.id),
                );
              },
              tooltip: AppStrings.editDetails,
            ),
          if (showDelete)
            DetailOverflowButton(
              appointment: detailState.appointment,
            ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSizes.p16),
          child: SkeletonTileList(count: 5),
        ),
        error: (Object error, StackTrace stack) => ErrorView(
          exception: error is AppException
              ? error
              : AppException.fromSupabaseException(error),
          onRetry: () => ref.invalidate(
            appointmentDetailControllerProvider(appointmentId),
          ),
        ),
        data: (AppointmentDetailState state) =>
            _AppointmentDetailBody(state: state, scrollController: _scrollController),
      ),
    );
  }
}

/// Data-state body with flat segments and pinned bottom actions.
class _AppointmentDetailBody extends ConsumerWidget {
  const _AppointmentDetailBody({
    required this.state,
    required this.scrollController,
  });
  final AppointmentDetailState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(currentUserProvider).value?.role;
    if (userRole == null) {
      return const EmptyState(
        message: AppStrings.appointmentNotFound,
        icon: Icons.event_busy_rounded,
      );
    }

    final bool hasActions = state.appointment.status == AppointmentStatus.scheduled ||
        state.appointment.status == AppointmentStatus.checkedIn ||
        state.appointment.status == AppointmentStatus.cancelled;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(appointmentDetailControllerProvider(state.appointment.id));
              try {
                await ref.read(
                  appointmentDetailControllerProvider(state.appointment.id).future,
                );
              } catch (_) {}
            },
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppointmentDetailHeader(
                    appointment: state.appointment,
                    patient: state.patient,
                  ).animate().fadeIn(duration: 300.ms),
                  AppointmentStatusBanner(status: state.appointment.status),
                  const SizedBox(height: AppSizes.p8),
                  AppointmentScheduleCard(appointment: state.appointment),
                  AppointmentDoctorsSection(
                    activeDoctors: state.activeDoctors,
                    inactiveDoctors: state.inactiveDoctors,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                    child: AppointmentNotesCard(
                      appointmentId: state.appointment.id,
                      patientId: state.appointment.patientId,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p24),
                ],
              ),
            ),
          ),
        ),
        if (hasActions)
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.p24, AppSizes.p16, AppSizes.p24, AppSizes.p16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: AppointmentActionButtons(
                appointment: state.appointment,
                userRole: userRole,
              ),
            ),
          ),
      ],
    );
  }
}
