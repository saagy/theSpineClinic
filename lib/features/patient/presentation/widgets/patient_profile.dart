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
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_profile_header.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_quick_actions.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_appointments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_documents.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_info.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_payments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_programs.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_records.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/pill_tab_bar.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/pinned_tab_bar_delegate.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Full patient profile layout containing header, tab controller, and FAB.
class PatientProfile extends ConsumerStatefulWidget {
  const PatientProfile({super.key, required this.patient, required this.isDoctor});

  final Patient patient;
  final bool isDoctor;

  @override
  ConsumerState<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends ConsumerState<PatientProfile>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final TabController _tabController;
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    final int tabCount = widget.isDoctor ? 5 : 6;
    final int savedIndex = ref.read(patientActiveTabProvider(widget.patient.id));
    final int initialIndex =
        (savedIndex >= 0 && savedIndex < tabCount) ? savedIndex : 0;
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: initialIndex,
    )..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      ref
          .read(patientActiveTabProvider(widget.patient.id).notifier)
          .setTab(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final bool show = _scrollController.offset > 80;
    if (show != _showAppBarTitle) {
      setState(() => _showAppBarTitle = show);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final isDoctor = widget.isDoctor;
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final bool canHandlePayments = user?.canHandlePayments ?? false;
    final canDelete =
        user?.role == UserRole.superAdmin ||
        user?.role == UserRole.receptionist ||
        (user?.isSeniorDoctor ?? false);
    final isEmptyAsync = ref.watch(patientIsEmptyProvider(patient.id));
    final bool patientIsEmpty = isEmptyAsync.value ?? false;

    final isDeleting = ref.watch(deletePatientControllerProvider).isLoading;

    final tabEntries = <(Tab, Widget)>[
      (const Tab(text: AppStrings.tabInfo), PatientTabInfo(patient: patient)),
      (const Tab(text: AppStrings.appointments), PatientTabAppointments(patient: patient)),
      (const Tab(text: AppStrings.programs), PatientTabPrograms(patient: patient)),
      (const Tab(text: AppStrings.tabRecords), PatientTabRecords(patient: patient)),
      if (!isDoctor)
        (const Tab(text: AppStrings.payments), PatientTabPayments(patient: patient)),
      (const Tab(text: AppStrings.tabDocuments), PatientTabDocuments(patient: patient)),
    ];
    final tabs = tabEntries.map((e) => e.$1).toList();
    final views = tabEntries.map((e) => e.$2).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: cs.surface.withAlpha(0),
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
        actions: isDeleting
            ? const []
            : [
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
      body: LoadingOverlay(
        isLoading: isDeleting,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: PatientProfileHeader(
                patient: patient,
                isDoctor: isDoctor,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedTabBarDelegate(
                tabBar: UnderlineTabBar(
                  controller: _tabController,
                  tabs: tabs,
                ),
                bgColor: cs.surface,
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: views,
          ),
        ),
      ),
      floatingActionButton: isDeleting
          ? null
          : PatientQuickActionsFab(
              patient: patient,
              isDoctor: isDoctor && !(user?.isSeniorDoctor ?? false),
              canHandlePayments: canHandlePayments,
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
        AppSnackbar.show(
          context,
          message: AppStrings.patientDeleted,
          variant: AppSnackbarVariant.success,
        );
        context.pop();
      },
      failure: (e) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(e.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }
}
