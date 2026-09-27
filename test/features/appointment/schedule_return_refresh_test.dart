import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/schedule_week.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import '../../fixtures/schedule_return_harness.dart';

void main() {
  for (final doctor in [true, false]) {
    group(doctor ? 'doctor' : 'reception', () {
      late ScheduleReturnHarness h;
      setUp(() async {
        h = ScheduleReturnHarness(doctor);
        addTearDown(h.container.dispose);
        await h.settle();
        await h.refresh(); // Initial request must not be duplicated.
        expect(h.repo.calls.length, 1);
        h.repo.pending.last.complete(Result.success([scheduleItem('a')]));
        await h.settle();
      });

      test(
        'only stale returns refresh, silently, once; day/filter survive',
        () async {
          h.advance(59);
          await h.refresh();
          expect(h.repo.calls.length, 1);
          h.advance(1);
          final refresh = h.refresh();
          await h.refresh();
          expect(h.repo.calls.length, 2);
          expect(h.loading, false);
          expect(h.items.single.appointment.id, 'a');
          final selected = ScheduleWeek.start(
            h.selected,
          ).add(const Duration(days: 3));
          h.select(selected);
          h.toggleCancelled();
          h.repo.pending.last.complete(Result.success([scheduleItem('b')]));
          await refresh;
          expect(h.items.single.appointment.id, 'b');
          expect(h.selected, selected);
          expect(h.showCancelled, true);
          await h.refresh();
          expect(h.repo.calls.length, 2);
          h.advance(600);
          await h.settle();
          expect(h.repo.calls.length, 2); // Time alone never polls.
        },
      );

      test('failure preserves rows and throttles repeated returns', () async {
        h.advance(60);
        final refresh = h.refresh();
        h.repo.pending.last.complete(
          const Result.failure(UnknownException(message: 'offline')),
        );
        await refresh;
        expect(h.items.single.appointment.id, 'a');
        expect(h.loading, false);
        expect(h.error, null);
        await h.refresh();
        h.advance(59);
        await h.refresh();
        expect(h.repo.calls.length, 2);
        h.advance(1);
        final retry = h.refresh();
        expect(h.repo.calls.length, 3);
        h.repo.pending.last.complete(const Result.success([]));
        await retry;
        expect(h.items, isEmpty);
      });

      test('response cannot undo an overlapping local status change', () async {
        h.advance(60);
        final refresh = h.refresh();
        h.checkIn();
        expect(h.items.single.doctorNames, ['Dr. Test']);
        h.repo.pending.last.complete(Result.success([scheduleItem('a')]));
        await refresh;
        expect(h.items.single.appointment.status, AppointmentStatus.checkedIn);
        expect(h.repo.calls.length, 2);
        h.advance(60);
        final retry = h
            .refresh(); // Local edit/discard must not mark the week fresh.
        expect(h.repo.calls.length, 3);
        h.repo.pending.last.complete(Result.success(h.items));
        await retry;
      });

      test(
        'weeks have independent ages and old responses cannot replace a new week',
        () async {
          final first = h.selected;
          h.advance(60);
          h.select(first.add(const Duration(days: 7)));
          h.repo.pending.last.complete(Result.success([scheduleItem('next')]));
          await h.settle();
          await h.refresh();
          expect(h.repo.calls.length, 2);
          h.select(first);
          expect(h.items.single.appointment.id, 'a');
          final refresh = h.refresh();
          expect(h.repo.calls.length, 3);
          h.select(first.add(const Duration(days: 7)));
          h.repo.pending.last.complete(Result.success([scheduleItem('old')]));
          await refresh;
          expect(h.items.single.appointment.id, 'next');
          expect(h.selected, first.add(const Duration(days: 7)));
        },
      );
    });
  }

  test('branch switch fences an in-flight background refresh', () async {
    final h = ScheduleReturnHarness(false);
    addTearDown(h.container.dispose);
    await h.settle();
    h.repo.pending.last.complete(Result.success([scheduleItem('a')]));
    await h.settle();
    h.advance(60);
    final refresh = h.refresh();
    final oldRequest = h.repo.pending.last;
    await h.container
        .read(activeBranchProvider.notifier)
        .setBranch(ClinicLocation.masrElgedida);
    await h.settle();
    expect(h.repo.calls.last.namedArguments[#clinic], 'masr_elgedida');
    h.repo.pending.last.complete(Result.success([scheduleItem('new-branch')]));
    await h.settle();
    oldRequest.complete(Result.success([scheduleItem('old-branch')]));
    await refresh;
    expect(h.items.single.appointment.id, 'new-branch');
    await h.refresh();
    expect(h.repo.calls.length, 3);
  });
}
