library;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/services/program_pdf_sections.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

/// Generates and previews a clinical assessment and rehabilitation report PDF.
class ProgramPdfService {
  const ProgramPdfService._();

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

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save(), name: 'SpineClinic_${patient?.fullName ?? 'Patient'}_Program.pdf');
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
