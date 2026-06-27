/// Patient profile screen with scroll-away header, pinned pill TabBar,
/// and FAB quick-actions hub.
///
/// Uses NestedScrollView so the profile header scrolls off-screen when
/// browsing tab data, while the tab bar stays pinned. This maximises
/// vertical space for list content.
///
/// Sub-tabs: Info | Appointments | Records | Payments | Documents
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/delete_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/error_scaffold.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_profile_header.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_profile_skeleton.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_quick_actions.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_appointments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_documents.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_info.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_payments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_records.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/pinned_tab_bar_delegate.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/pill_tab_bar.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPatient = ref.watch(patientDetailProvider(patientId));
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;

    return asyncPatient.when(
      loading: () => const Scaffold(body: PatientProfileSkeleton()),
      error: (error, _) => PatientErrorScaffold(
        error: error,
        onRetry: () => ref.invalidate(patientDetailProvider(patientId)),
      ),
      data: (patient) => _PatientProfile(patient: patient, isDoctor: isDoctor),
    );
  }
}

class _PatientProfile extends ConsumerStatefulWidget {
  const _PatientProfile({required this.patient, required this.isDoctor});
  final Patient patient;
  final bool isDoctor;

  @override
  ConsumerState<_PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends ConsumerState<_PatientProfile> {
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
    final bool show = _scrollController.offset > 80;
    if (show != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = show;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final isDoctor = widget.isDoctor;
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final canDelete = user?.role == UserRole.superAdmin ||
        user?.role == UserRole.receptionist;
    final isEmptyAsync = ref.watch(patientIsEmptyProvider(patient.id));
    final bool patientIsEmpty = isEmptyAsync.value ?? false;

    final tabs = <Tab>[
      const Tab(text: AppStrings.tabInfo),
      const Tab(text: AppStrings.appointments),
      const Tab(text: AppStrings.tabRecords),
      if (!isDoctor) const Tab(text: AppStrings.payments),
      const Tab(text: AppStrings.tabDocuments),
    ];
    final views = <Widget>[
      PatientTabInfo(patient: patient),
      PatientTabAppointments(patient: patient),
      PatientTabRecords(patient: patient),
      if (!isDoctor) PatientTabPayments(patient: patient),
      PatientTabDocuments(patient: patient),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: const AppBackButton(),
          title: AnimatedOpacity(
            opacity: _showAppBarTitle ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              patient.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.edit,
              onPressed: () => context.push(
                AppRoutes.editPatient.replaceAll(':id', patient.id),
                extra: patient,
              ),
            ),
            if (canDelete && patientIsEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                onSelected: (_) => _confirmDelete(context),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: cs.error),
                        const SizedBox(width: AppSizes.p12),
                        Text(AppStrings.deletePatient),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: PatientProfileHeader(patient: patient, isDoctor: isDoctor),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedTabBarDelegate(
                tabBar: UnderlineTabBar(tabs: tabs),
                bgColor: cs.surface,
              ),
            ),
          ],
          body: TabBarView(children: views),
        ),
        floatingActionButton: PatientQuickActionsFab(
          patient: patient,
          isDoctor: isDoctor,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.deletePatient,
        message: AppStrings.deletePatientWarning,
        isDestructive: true,
      ),
    );
    if (confirm != true || !context.mounted) return;
    final result = await ref
        .read(deletePatientControllerProvider.notifier)
        .deletePatient(widget.patient.id);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show(context,
            message: AppStrings.patientDeleted,
            variant: AppSnackbarVariant.success);
        context.pop();
      },
      failure: (e) => AppSnackbar.show(context,
          message: AppStrings.fromKey(e.userMessageKey),
          variant: AppSnackbarVariant.error),
    );
  }
}
