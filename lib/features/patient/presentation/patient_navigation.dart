import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/network/route_stack.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_workspace_tab.dart';

/// Whether the patient's record is the page right under this one, so
/// closing this page already returns to it.
bool patientRecordIsBelow(BuildContext context, String patientId) =>
    pageBelowTop(context) == AppRoutes.patientLocation(patientId);

/// Leaves a page stacked over the app (such as an invoice) for the
/// patient's record on [tab].
///
/// When the record is right underneath, this page closes onto it. Otherwise
/// this page closes and the record opens in its place, so Back returns to
/// where this page was opened from (such as Billing) instead of stacking a
/// second app shell. A page opened from a link opens the record alone.
void openPatientRecordFrom(
  BuildContext context,
  WidgetRef ref,
  String patientId, {
  PatientWorkspaceTab? tab,
}) {
  final GoRouter router = GoRouter.of(context);
  final String location = AppRoutes.patientLocation(patientId, tab: tab?.name);
  if (!router.canPop()) return router.go(location);
  if (patientRecordIsBelow(context, patientId)) {
    if (tab != null) ref.read(patientActiveTabProvider(patientId).notifier).show(tab);
    return router.pop();
  }
  router.pop();
  router.push(location);
}
