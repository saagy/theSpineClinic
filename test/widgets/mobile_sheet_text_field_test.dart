import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_note_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';

void main() {
  testWidgets('add note opens compact and focuses from the empty field area', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AddNoteSheet(patientId: '1')),
        ),
      ),
    );
    await tester.pump();

    EditableText editable = tester.widget(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isFalse);
    expect(tester.getSize(find.byType(TextField)).height, lessThan(200));

    final Rect field = tester.getRect(find.byType(TextField));
    await tester.tapAt(Offset(field.center.dx, field.bottom - 8));
    await tester.pump();

    editable = tester.widget(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
  });

  testWidgets('shared sheet uses its maximum height above the keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: AppBottomSheet(
            title: AppStrings.filters,
            builder: (_, __) => const Material(child: TextField()),
          ),
        ),
      ),
    );

    final DraggableScrollableSheet sheet = tester.widget(
      find.byType(DraggableScrollableSheet),
    );
    final EditableText editable = tester.widget(find.byType(EditableText));
    expect(sheet.initialChildSize, sheet.maxChildSize);
    expect(editable.focusNode.hasFocus, isFalse);
  });
}
