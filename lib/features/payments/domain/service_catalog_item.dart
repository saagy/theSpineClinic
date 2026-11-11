import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_catalog_item.freezed.dart';
part 'service_catalog_item.g.dart';

/// Matches `service_catalog.service_type`.
enum ServiceType {
  ptSession('pt_session'),
  tractionSession('traction_session'),
  initialAssessment('initial_assessment'),
  reassessment('reassessment'),
  other('other');

  const ServiceType(this.dbValue);
  final String dbValue;

  /// Only PT and traction services add sessions and can be packages.
  bool get usesSessions => this == ptSession || this == tractionSession;

  static ServiceType fromDb(String value) =>
      values.firstWhere((type) => type.dbValue == value, orElse: () => other);
}

ServiceType _typeFromJson(String value) => ServiceType.fromDb(value);
String _typeToJson(ServiceType type) => type.dbValue;

/// A row of `public.service_catalog`. Prices are EGP minor units.
@freezed
abstract class ServiceCatalogItem with _$ServiceCatalogItem {
  const ServiceCatalogItem._();

  const factory ServiceCatalogItem({
    required String id,
    required String name,
    @JsonKey(name: 'service_type', fromJson: _typeFromJson, toJson: _typeToJson)
    required ServiceType type,
    @JsonKey(name: 'sessions_per_unit') required int sessionsPerUnit,
    @JsonKey(name: 'price_minor') required int priceMinor,
    @JsonKey(name: 'attributes_doctors') required bool creditsDoctors,
    required bool active,
    required int version,
  }) = _ServiceCatalogItem;

  factory ServiceCatalogItem.fromJson(Map<String, dynamic> json) =>
      _$ServiceCatalogItemFromJson(json);

  bool get isPackage => sessionsPerUnit > 1;

  /// Price of one session in a package, rounded to the nearest piaster.
  int get perSessionMinor => (priceMinor / sessionsPerUnit).round();
}

/// The editable fields of a service, sent to `service_save`.
class ServiceDraft {
  const ServiceDraft({
    this.id,
    this.version,
    required this.name,
    required this.type,
    required this.sessionsPerUnit,
    required this.priceMinor,
    required this.creditsDoctors,
    required this.active,
  });

  factory ServiceDraft.of(ServiceCatalogItem item) => ServiceDraft(
    id: item.id,
    version: item.version,
    name: item.name,
    type: item.type,
    sessionsPerUnit: item.sessionsPerUnit,
    priceMinor: item.priceMinor,
    creditsDoctors: item.creditsDoctors,
    active: item.active,
  );

  final String? id;
  final int? version;
  final String name;
  final ServiceType type;
  final int sessionsPerUnit;
  final int priceMinor;
  final bool creditsDoctors;
  final bool active;

  Map<String, Object?> toPayload() => {
    'id': id,
    'version': version,
    'name': name.trim(),
    'service_type': type.dbValue,
    'sessions_per_unit': type.usesSessions ? sessionsPerUnit : 1,
    'price_minor': priceMinor,
    'attributes_doctors': creditsDoctors,
    'active': active,
  };

  /// True when saving would change nothing.
  bool sameAs(ServiceDraft other) =>
      name.trim() == other.name.trim() &&
      type == other.type &&
      (type.usesSessions ? sessionsPerUnit : 1) ==
          (other.type.usesSessions ? other.sessionsPerUnit : 1) &&
      priceMinor == other.priceMinor &&
      creditsDoctors == other.creditsDoctors &&
      active == other.active;
}
