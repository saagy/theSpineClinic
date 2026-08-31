library;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

/// Helper section builders for the clinical assessment PDF report.
class ProgramPdfSections {
  const ProgramPdfSections._();

  static pw.Widget buildPatientSection(Patient? patient, PatientMedicalHistory? history) {
    final historyItems = <String>[];
    if (history != null) {
      if (history.hasDiabetes) historyItems.add('Diabetes${history.hba1cValue != null ? ' (HbA1c: ${history.hba1cValue}%)' : ''}');
      if (history.hasHypertension) historyItems.add('Hypertension');
      if (history.hasHyperlipidemia) historyItems.add('Hyperlipidemia');
      if (history.hasRheumatology) historyItems.add('Rheumatoid${history.rheumatologyDetails != null ? ' (${history.rheumatologyDetails})' : ''}');
      if (history.additionalNotes != null && history.additionalNotes!.trim().isNotEmpty) historyItems.add('Notes: ${history.additionalNotes!.trim()}');
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PATIENT INFORMATION', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 2),
                pw.Text('Name: ${patient?.fullName ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                if (patient?.phoneNumber != null) pw.Text('Phone: ${patient!.phoneNumber}', style: const pw.TextStyle(fontSize: 8.5)),
                if (patient?.clinic != null) pw.Text('Branch: ${patient!.clinic.name.toUpperCase()}', style: const pw.TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('MEDICAL HISTORY & LABS', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 2),
                pw.Text(historyItems.isEmpty ? 'No chronic conditions recorded.' : historyItems.join(' • '), style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildAssessmentSection(PatientProgram program) {
    final regions = program.affectedRegions.toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
    final findingsRows = <List<String>>[];
    if (program.examination?.isNotEmpty ?? false) findingsRows.add(['Physical Examination', program.examination!.trim()]);
    if (program.exaggeratingPositions?.isNotEmpty ?? false) findingsRows.add(['Exaggerating Positions', program.exaggeratingPositions!.trim()]);
    if (program.relievingPositions?.isNotEmpty ?? false) findingsRows.add(['Relieving Positions', program.relievingPositions!.trim()]);
    if (program.imagingNotes?.isNotEmpty ?? false) findingsRows.add(['Imaging & Scans', program.imagingNotes!.trim()]);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('CLINICAL ASSESSMENT & DIAGNOSIS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
        pw.SizedBox(height: 4),
        if (regions.isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5), borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DIAGNOSED CONDITIONS BY REGION', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 3),
                for (final region in regions)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(width: 90, child: pw.Text('• ${region.displayName}:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800))),
                        pw.Expanded(
                          child: pw.Text(
                            program.conditions.where((c) => c.condition?.region == region).map((c) => c.condition?.conditionName ?? '').where((n) => n.isNotEmpty).join(' • '),
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
        ],
        if (findingsRows.isNotEmpty)
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: findingsRows.asMap().entries.map((entry) {
                final isLast = entry.key == findingsRows.length - 1;
                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: isLast ? null : const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                  ),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 130,
                        child: pw.Text(
                          entry.value[0],
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          entry.value[1],
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  static pw.Widget buildTreatmentPlanSection(PatientProgram program) {
    final activePlan = program.activePlan;
    if (activePlan == null) return pw.Text('No active treatment plan configured.', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ACTIVE TREATMENT PLAN (${activePlan.planName.toUpperCase()})', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
          cellStyle: const pw.TextStyle(fontSize: 8),
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
          pw.Text('Prescribed Exercises & Plan Notes: ${activePlan.notes!.trim()}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
        ],
      ],
    );
  }
}
