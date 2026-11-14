import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/money.dart';
import '../../domain/service_catalog_item.dart';

const _t = AppStrings.invoices;

/// Which services the catalog shows.
enum ServiceShow { active, archived, all }

/// Catalog sections, in display order.
enum ServiceGroup { physicalTherapy, traction, assessments, other }

extension ServiceTypeLabels on ServiceType {
  String get label => switch (this) {
    ServiceType.ptSession => _t.typePt,
    ServiceType.tractionSession => _t.typeTraction,
    ServiceType.initialAssessment => _t.typeInitial,
    ServiceType.reassessment => _t.typeReassessment,
    ServiceType.other => _t.typeOther,
  };

  IconData get icon => switch (this) {
    ServiceType.ptSession => Icons.accessibility_new,
    ServiceType.tractionSession => Icons.straighten,
    ServiceType.initialAssessment => Icons.assignment_outlined,
    ServiceType.reassessment => Icons.assignment_turned_in_outlined,
    ServiceType.other => Icons.medical_services_outlined,
  };

  ServiceGroup get group => switch (this) {
    ServiceType.ptSession => ServiceGroup.physicalTherapy,
    ServiceType.tractionSession => ServiceGroup.traction,
    ServiceType.initialAssessment || ServiceType.reassessment => ServiceGroup.assessments,
    ServiceType.other => ServiceGroup.other,
  };
}

extension ServiceGroupLabels on ServiceGroup {
  String get label => switch (this) {
    ServiceGroup.physicalTherapy => _t.groupPt,
    ServiceGroup.traction => _t.groupTraction,
    ServiceGroup.assessments => _t.groupAssessments,
    ServiceGroup.other => _t.groupOther,
  };
}

extension ServiceShowLabels on ServiceShow {
  String get label => switch (this) {
    ServiceShow.active => _t.showActive,
    ServiceShow.archived => _t.showArchived,
    ServiceShow.all => _t.showAll,
  };

  bool includes(ServiceCatalogItem item) => switch (this) {
    ServiceShow.active => item.active,
    ServiceShow.archived => !item.active,
    ServiceShow.all => true,
  };
}

extension ServiceCatalogItemLabels on ServiceCatalogItem {
  /// "6-session package", "Single session" or "Single service".
  String get soldAs => isPackage
      ? _t.packageOf(sessionsPerUnit)
      : type.usesSessions
      ? _t.singleSession
      : _t.singleService;

  /// Per-session price for packages, otherwise null.
  String? get perSessionLabel => isPackage ? _t.perSession(Money.format(perSessionMinor)) : null;
}

/// Sections in display order, each sorted singles first, then by size and name.
List<(ServiceGroup, List<ServiceCatalogItem>)> groupServices(
  Iterable<ServiceCatalogItem> services,
) {
  final Map<ServiceGroup, List<ServiceCatalogItem>> groups = {};
  for (final service in services) {
    groups.putIfAbsent(service.type.group, () => []).add(service);
  }
  return [
    for (final group in ServiceGroup.values)
      if (groups[group] case final items?)
        (
          group,
          items..sort(
            (a, b) => a.sessionsPerUnit != b.sessionsPerUnit
                ? a.sessionsPerUnit.compareTo(b.sessionsPerUnit)
                : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          ),
        ),
  ];
}
