/// Centralized GoRouter configuration with role-based redirect guards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/network/app_page_transitions.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/admin/presentation/admin_hub_screen.dart';
import 'package:spine_clinic_app/features/admin/presentation/analytics_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_replacement_args.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_replacement_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/edit_appointment_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/new_appointment_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_screen.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_history_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_profile_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/login_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/receptionist_profile_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/register_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/splash_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/add_visit_notes_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/visit_detail_screen.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/edit_patient_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/my_patients_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_document_viewer_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/new_patient_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_detail_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_search_screen.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_screen.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_form_screen.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_list_screen.dart';
import 'package:spine_clinic_app/shared/widgets/app_shell.dart';

part 'router.g.dart';
part 'router_guards.dart';
part 'router_navigation.dart';
part 'router_routes.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<Staff?>>(
      currentUserProvider,
      (_, __) => notifyListeners(),
    );
  }
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final _RouterRefreshNotifier refreshNotifier = _RouterRefreshNotifier(ref);
  final GoRouter goRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) =>
        _redirect(ref, state),
    routes: _buildRoutes(ref),
  );
  ref.onDispose(() {
    refreshNotifier.dispose();
    goRouter.dispose();
  });
  return goRouter;
}
