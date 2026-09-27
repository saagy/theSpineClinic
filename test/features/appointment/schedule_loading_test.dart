import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:spine_clinic_app/features/appointment/data/appointment_repository_impl.dart';
import 'package:spine_clinic_app/features/appointment/domain/schedule_loader.dart';
import '../../fixtures/test_supabase_service.dart';

void main() {
  final date = DateTime(2026, 9, 26);
  final requests = <http.Request>[];
  late TestSupabaseService service;
  late AppointmentRepositoryImpl repository;
  bool failSecondPage = false;
  setUp(() {
    requests.clear();
    failSecondPage = false;
    service = TestSupabaseService((request) async {
      requests.add(request);
      final query = request.url.queryParameters;
      final offset = int.parse(query['offset'] ?? '0');
      if (failSecondPage && offset > 0) {
        return http.Response('{"code":"XX000","message":"test failure"}', 500);
      }
      // Deliberately lower than the requested page size to exercise server caps.
      final limit = int.parse(query['limit'] ?? '1000').clamp(0, 300);
      final rows = List.generate(
        (1250 - offset).clamp(0, limit),
        (i) => {
          'id': 'appointment-${offset + i}',
          'patient_id': 'patient',
          'type': 'normal_pt_session',
          'scheduled_at': date.toIso8601String(),
          'created_at': date.toIso8601String(),
          'patient': {
            'id': 'patient',
            'full_name': 'Test',
            'phone_number': '000',
            'clinic': 'tagamoa',
            'created_at': date.toIso8601String(),
          },
          'appointment_doctors': [],
        },
      );
      return http.Response(
        jsonEncode(rows),
        200,
        headers: {
          'content-type': 'application/json',
          'content-range': '$offset-${offset + rows.length - 1}/1250',
        },
      );
    });
    repository = AppointmentRepositoryImpl(supabaseService: service);
  });
  tearDown(() => service.client.dispose());

  test(
    'schedule loads beyond 1000 and below the requested server page size',
    () async {
      final result = await repository.getScheduleAppointments(
        dateFrom: date,
        dateTo: date.add(const Duration(days: 7)),
        doctorId: 'doctor',
      );
      expect(result.dataOrNull, hasLength(1250));
      expect(requests.map((r) => r.url.queryParameters['offset']), [
        '0',
        '300',
        '600',
        '900',
        '1200',
        '1250',
      ]);
      for (final request in requests) {
        expect(request.url.path, '/rest/v1/appointments');
        expect(
          request.url.queryParameters['doctor_filter.doctor_id'],
          'eq.doctor',
        );
        expect(
          request.url.queryParameters['doctor_filter.is_active'],
          'eq.true',
        );
        expect(
          request.url.queryParameters['select'],
          contains('doctor_filter:appointment_doctors!inner()'),
        );
        expect(
          request.url.queryParameters['order'],
          'scheduled_at.asc.nullslast,created_at.asc.nullslast,id.asc.nullslast',
        );
      }
    },
  );
  test(
    'failed later page returns an error, never a partial schedule',
    () async {
      failSecondPage = true;
      final result = await repository.getScheduleAppointments(
        dateFrom: date,
        dateTo: date.add(const Duration(days: 7)),
      );
      expect(result.isFailure, true);
      expect(result.dataOrNull, null);
    },
  );
  test(
    'operational counts use the exact server total, not returned row length',
    () async {
      expect(
        (await repository.countAllAppointments(
          doctorId: 'doctor',
          clinic: 'tagamoa',
          patientQuery: 'Test',
        )).dataOrNull,
        1250,
      );
      expect(
        (await repository.countAppointmentsForPatient(
          patientId: 'patient',
          doctorId: 'doctor',
        )).dataOrNull,
        1250,
      );
      expect(
        (await repository.getFutureScheduledAppointmentsCount(
          'patient',
        )).dataOrNull,
        1250,
      );
      for (final request in requests) {
        expect(request.headers['Prefer'], contains('count=exact'));
        expect(request.url.queryParameters['limit'], '1');
      }
      expect(
        requests.first.url.queryParameters['patient.or'],
        contains('full_name.ilike'),
      );
    },
  );
}
