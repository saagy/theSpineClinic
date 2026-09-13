import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/new_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_form_fields.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_select_field.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

import 'package:spine_clinic_app/shared/widgets/form_page_body.dart';
import 'package:spine_clinic_app/shared/widgets/form_section.dart';
import 'package:spine_clinic_app/shared/widgets/form_columns.dart';
part 'new_patient_form_actions.dart';
part 'new_patient_form_view.dart';
part 'new_patient_attachment_row.dart';

/// Form component for registering a new patient.
class NewPatientForm extends ConsumerStatefulWidget {
  /// Creates a [NewPatientForm].
  const NewPatientForm({super.key});

  @override
  ConsumerState<NewPatientForm> createState() => _NewPatientFormState();
}

class _NewPatientFormState extends ConsumerState<NewPatientForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final List<PlatformFile> _selectedFiles = [];

  Future<void> _pickFiles() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
    );
    if (result == null) return;

    for (final PlatformFile f in result.files) {
      final String ext = p.extension(f.name).toLowerCase();
      final bool isPdf = ext == '.pdf';
      final int maxBytes = isPdf ? 10 * 1024 * 1024 : 10 * 1024 * 1024;
      if (f.size > maxBytes) {
        if (!mounted) return;
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(
            isPdf ? 'error_doc_pdf_too_large' : 'error_doc_image_too_large',
          ),
          variant: AppSnackbarVariant.error,
        );
        continue;
      }
      _selectedFiles.add(f);
    }
    setState(() {});
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  @override
  Widget build(BuildContext context) => _buildForm(context);
}
