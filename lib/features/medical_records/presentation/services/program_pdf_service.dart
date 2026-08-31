library;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
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
    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    final title = program.affectedRegions.isNotEmpty
        ? program.affectedRegions.map((r) => r.displayName).join(' & ')
        : 'Rehabilitation Program';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) => [
          _buildHeader(title, program),
          pw.SizedBox(height: 14),
          _buildPatientAndHistorySection(patient, medicalHistory),
          pw.SizedBox(height: 14),
          _buildAssessmentSection(program),
          pw.SizedBox(height: 14),
          _buildTreatmentPlanSection(program),
          if (program.notes != null && program.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _buildNotesSection('Clinical Advice & Program Notes', program.notes!),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'SpineClinic_${patient?.fullName ?? 'Patient'}_Program.pdf',
    );
  }

  static pw.Widget _buildHeader(String title, PatientProgram program) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('THE SPINE CLINIC', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
              pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Status: ${program.status.name.toUpperCase()}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
              pw.Text('Date: ${Formatters.formatDateMedium(program.createdAt)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPatientAndHistorySection(Patient? patient, PatientMedicalHistory? history) {
    final historyItems = <String>[];
    if (history != null) {
      if (history.hasDiabetes) historyItems.add('Diabetes${history.hba1cValue != null ? ' (HbA1c: ${history.hba1cValue}%)' : ''}');
      if (history.hasHypertension) historyItems.add('Hypertension');
      if (history.hasHyperlipidemia) historyItems.add('Hyperlipidemia');
      if (history.hasRheumatology) historyItems.add('Rheumatoid${history.rheumatologyDetails != null ? ' (${history.rheumatologyDetails})' : ''}');
      if (history.additionalNotes != null && history.additionalNotes!.trim().isNotEmpty) historyItems.add('Notes: ${history.additionalNotes!.trim()}');
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PATIENT INFORMATION', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 3),
                pw.Text('Name: ${patient?.fullName ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                if (patient?.phoneNumber != null) pw.Text('Phone: ${patient!.phoneNumber}', style: const pw.TextStyle(fontSize: 9)),
                if (patient?.clinic != null) pw.Text('Branch: ${patient!.clinic.name.toUpperCase()}', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('MEDICAL HISTORY & LABS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 3),
                pw.Text(
                  historyItems.isEmpty ? 'No chronic conditions recorded.' : historyItems.join(' • '),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAssessmentSection(PatientProgram program) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('CLINICAL ASSESSMENT & DIAGNOSIS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
        pw.SizedBox(height: 4),
        if (program.conditions.isNotEmpty) ...[
          pw.Text('Diagnosed Conditions: ${program.conditions.map((c) => c.condition?.conditionName ?? '').where((n) => n.isNotEmpty).join(', ')}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 3),
        ],
        if (program.examination != null && program.examination!.trim().isNotEmpty)
          pw.Text('Physical Exam: ${program.examination!.trim()}', style: const pw.TextStyle(fontSize: 9)),
        if (program.exaggeratingPositions != null && program.exaggeratingPositions!.trim().isNotEmpty)
          pw.Text('Aggravating Factors: ${program.exaggeratingPositions!.trim()}', style: const pw.TextStyle(fontSize: 9)),
        if (program.relievingPositions != null && program.relievingPositions!.trim().isNotEmpty)
          pw.Text('Relieving Factors: ${program.relievingPositions!.trim()}', style: const pw.TextStyle(fontSize: 9)),
        if (program.imagingNotes != null && program.imagingNotes!.trim().isNotEmpty)
          pw.Text('Imaging / Scans: ${program.imagingNotes!.trim()}', style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget _buildTreatmentPlanSection(PatientProgram program) {
    final activePlan = program.activePlan;
    if (activePlan == null) return pw.Text('No active treatment plan configured.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ACTIVE TREATMENT PLAN (${activePlan.planName.toUpperCase()})', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
        pw.SizedBox(height: 5),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
          cellStyle: const pw.TextStyle(fontSize: 8.5),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          headers: ['Modality', 'Target Region & Laterality', 'Duration', 'Parameters / Notes'],
          data: activePlan.modalities.map((m) {
            final regStr = m.regions.map((r) => '${r.targetRegion}${r.laterality != null ? ' (${r.laterality!.shortLabel})' : ''}').join(', ');
            final totalMin = m.regions.fold<int>(0, (sum, r) => sum + r.timeMinutes);
            return [m.modalityType.displayLabel, regStr.isEmpty ? 'General Technique' : regStr, totalMin > 0 ? '$totalMin min' : '-', m.notes ?? '-'];
          }).toList(),
        ),
        if (activePlan.notes != null && activePlan.notes!.trim().isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text('Prescribed Exercises & Plan Notes: ${activePlan.notes!.trim()}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ],
    );
  }

  static pw.Widget _buildNotesSection(String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
        pw.SizedBox(height: 3),
        pw.Text(content.trim(), style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }
}
