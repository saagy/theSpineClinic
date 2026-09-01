/// Screen displaying the full detail view for a single appointment.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/edit_appointment_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_detail_body.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_detail_skeleton.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/detail_overflow_button.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

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
    final isMutating = ref.watch(editAppointmentControllerProvider).isLoading;
    final AsyncValue<AppointmentDetailState> detailAsync = ref.watch(
      appointmentDetailControllerProvider(appointmentId),
    );
    final detailState = detailAsync.value;
    final user = ref.watch(currentUserProvider).value;
    final canEditAsync = detailState != null
        ? ref.watch(
            canEditAppointmentProvider(
              appointmentId: detailState.appointment.id,
              patientId: detailState.patient.id,
            ),
          )
        : const AsyncValue.data(false);
    final bool showEdit = canEditAsync.value ?? false;
    final bool showDelete =
        detailState != null &&
        user != null &&
        (user.role != UserRole.doctor || user.isSeniorDoctor) &&
        (detailState.appointment.status == AppointmentStatus.scheduled ||
            detailState.appointment.status == AppointmentStatus.cancelled);
    final String? patientName = detailState?.patient.fullName;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.colorScheme.surface.withAlpha(0),
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
        actions: isMutating
            ? const []
            : [
                if (showEdit && detailState != null)
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      context.push(
                        AppRoutes.editAppointment.replaceAll(
                          ':id',
                          detailState.appointment.id,
                        ),
                      );
                    },
                    tooltip: AppStrings.editDetails,
                  ),
                if (showDelete)
                  DetailOverflowButton(appointment: detailState.appointment),
              ],
      ),
      body: LoadingOverlay(
        isLoading: isMutating,
        child: detailAsync.when(
          loading: () => const AppointmentDetailSkeleton(),
          error: (Object error, StackTrace stack) => ErrorView(
            exception: error is AppException
                ? error
                : AppException.fromSupabaseException(error),
            onRetry: () => ref.invalidate(
              appointmentDetailControllerProvider(appointmentId),
            ),
          ),
          data: (AppointmentDetailState state) => AppointmentDetailBody(
            state: state,
            scrollController: _scrollController,
          ),
        ),
      ),
    );
  }
}
