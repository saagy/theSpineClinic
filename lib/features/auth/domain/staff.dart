/// Freezed domain model for the `public.staff` table.
///
/// Maps exactly to the schema defined in AGENT_CONTEXT §3.
/// Used as the authenticated user profile throughout the application.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

part 'staff.freezed.dart';
part 'staff.g.dart';

/// Represents a single staff member (doctor, receptionist, or super admin).
@freezed
abstract class Staff with _$Staff {
  /// Creates a [Staff] instance.
  const factory Staff({
    /// Primary key (`uuid`).
    required String id,

    /// FK to `auth.users(id)` — nullable until the user completes sign-up.
    @JsonKey(name: 'user_id') String? userId,

    /// Display name shown across the application.
    @JsonKey(name: 'full_name') required String fullName,

    /// Unique email address used for authentication.
    required String email,

    /// Phone number of the staff member.
    String? phone,

    /// Access-control tier (super_admin / receptionist / doctor).
    required UserRole role,

    /// Whether the account has been approved by an admin.
    @JsonKey(name: 'is_active') @Default(true) bool isActive,

    /// The primary clinic location/branch for this staff member (synced preference).
    @JsonKey(name: 'branch') ClinicLocation? branch,

    /// Row creation timestamp.
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Staff;

  /// Deserialises a JSON map (e.g. from a Supabase query) into [Staff].
  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);
}
