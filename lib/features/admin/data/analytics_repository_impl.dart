import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_appointment_staff.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_dtos.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_financial_patient.dart';
import 'package:spine_clinic_app/features/admin/domain/analytics_repository.dart';

/// Supabase-backed implementation of [AnalyticsRepository].
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl({required SupabaseService supabaseService})
    : _service = supabaseService;

  final SupabaseService _service;

  @override
  Future<Result<FinancialSummary>> getFinancialSummary({
    required DateTimeRange range,
    String? branchId,
  }) => fetchFinancialSummary(_service, range, branchId);

  @override
  Future<Result<AppointmentSummary>> getAppointmentSummary({
    required DateTimeRange range,
    String? branchId,
  }) => fetchAppointmentSummary(_service, range, branchId);

  @override
  Future<Result<StaffSummary>> getStaffSummary({
    required DateTimeRange range,
  }) => fetchStaffSummary(_service, range);

  @override
  Future<Result<PatientSummary>> getPatientSummary({
    required DateTimeRange range,
    String? branchId,
  }) => fetchPatientSummary(_service, range, branchId);
}
