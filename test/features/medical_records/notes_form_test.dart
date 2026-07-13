import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/notes_form.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

void main() {
  testWidgets('visit notes expose one save action', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: NotesForm(note: null, appointmentId: 'appointment-1'),
          ),
        ),
      ),
    );

    expect(find.byType(AppButton), findsOneWidget);
    expect(find.text(AppStrings.saveNotes), findsOneWidget);
  });
}
