import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/services/program_pdf_sections.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_picker_bottom_sheet.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Generates and previews a clinical assessment and rehabilitation report PDF.
class ProgramPdfService {
  const ProgramPdfService._();

  /// Dispatches the complete program PDF export flow for a given [patient].
  ///
  /// Automatically resolves single vs multiple active or archived programs,
  /// displays a picker modal if disambiguation is required, and previews
  /// the generated report.
  static Future<void> exportProgramForPatient({
    required BuildContext context,
    required WidgetRef ref,
    required Patient patient,
  }) async {
    try {
      final List<PatientProgram> programs =
          await ref.read(patientProgramsProvider(patient.id).future);

      if (programs.isEmpty) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: AppStrings.noProgramsRecorded,
            variant: AppSnackbarVariant.info,
          );
        }
        return;
      }

      final List<PatientProgram> activePrograms =
          programs.where((p) => p.status == ProgramStatus.active).toList();

      PatientProgram? targetProgram;
      if (programs.length == 1) {
        targetProgram = programs.first;
      } else if (activePrograms.length == 1) {
        targetProgram = activePrograms.first;
      } else {
        if (!context.mounted) return;
        targetProgram = await AppBottomSheet.show<PatientProgram>(
          context: context,
          title: AppStrings.selectProgram,
          builder: (ctx, scrollController) => ProgramPickerBottomSheet(
            programs: programs,
            scrollController: scrollController,
          ),
        );
      }

      if (targetProgram == null || !context.mounted) return;

      final PatientMedicalHistory? history = await ref
          .read(patientMedicalHistoryProvider(patient.id).future);

      await printProgramReport(
        program: targetProgram,
        patient: patient,
        medicalHistory: history,
      );
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: AppStrings.pdfExportError,
          variant: AppSnackbarVariant.error,
        );
      }
    }
  }

  static Future<void> printProgramReport({
    required PatientProgram program,
    Patient? patient,
    PatientMedicalHistory? medicalHistory,
  }) async {
    final doc = pw.Document();
    pw.Font font = pw.Font.helvetica();
    pw.Font boldFont = pw.Font.helveticaBold();
    try {
      final fontData = await rootBundle.load('assets/fonts/Inter-VariableFont_opsz,wght.ttf');
      font = pw.Font.ttf(fontData);
      boldFont = font;
    } catch (_) {}

    final title = program.affectedRegions.isNotEmpty ? program.affectedRegions.map((r) => r.displayName).join(' & ') : 'Rehabilitation Program';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) => [
          _buildHeader(title, program),
          pw.SizedBox(height: 12),
          ProgramPdfSections.buildPatientSection(patient, medicalHistory),
          pw.SizedBox(height: 12),
          ProgramPdfSections.buildAssessmentSection(program),
          pw.SizedBox(height: 12),
          ProgramPdfSections.buildTreatmentPlanSection(program),
          if (program.notes != null && program.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Clinical Advice & Program Notes', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                pw.SizedBox(height: 2),
                pw.Text(program.notes!.trim(), style: const pw.TextStyle(fontSize: 8.5)),
              ],
            ),
          ],
        ],
      ),
    );

    final pdfBytes = await doc.save();
    final sanitizedName = (patient?.fullName ?? 'Patient').trim().replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_');
    final fileName = 'SpineClinic_${sanitizedName}_Program.pdf';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }

  static pw.Widget _buildHeader(String title, PatientProgram program) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('THE SPINE CLINIC', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
              pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Status: ${program.status.name.toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
              pw.Text('Date: ${Formatters.formatDateMedium(program.createdAt)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    );
  }
}
