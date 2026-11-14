/// Sample `doctor_session_report` responses. Dr. Ahmed saw three sessions,
/// one of them shared with Dr. Mona; Dr. Karim has only a past appointment
/// that was never checked in.
library;

Map<String, dynamic> _visit(String id, String type, int day, String patient, int fileNumber) => {
  'appointment_id': id,
  'type': type,
  'scheduled_at': DateTime.utc(2026, 11, day, 8).toIso8601String(),
  'patient_id': 'patient-$fileNumber',
  'patient_name': patient,
  'file_number': fileNumber,
};

Map<String, dynamic> _row(String id, String name,
        {int pt = 0, int assessments = 0, int shared = 0, int pending = 0}) =>
    {
      'doctor_id': id,
      'doctor_name': name,
      'pt_sessions': pt,
      'assessments': assessments,
      'reassessments': 0,
      'total': pt + assessments,
      'shared': shared,
      'pending': pending,
    };

Map<String, dynamic> doctorSessionsJson({bool oneDoctor = false}) => {
  'totals': oneDoctor
      ? {'sessions': 3, 'pt_sessions': 2, 'assessments': 1, 'reassessments': 0,
          'shared': 1, 'credits': 3, 'pending': 0, 'doctors': 1}
      : {'sessions': 3, 'pt_sessions': 2, 'assessments': 1, 'reassessments': 0,
          'shared': 1, 'credits': 4, 'pending': 1, 'doctors': 2},
  'rows': [
    _row('d1', 'Dr. Ahmed Hassan', pt: 2, assessments: 1, shared: 1),
    if (!oneDoctor) ...[
      _row('d3', 'Dr. Karim Adel', pending: 1),
      _row('d2', 'Dr. Mona Saeed', pt: 1, shared: 1),
    ],
  ],
  'sessions': [
    {..._visit('a1', 'normal_pt_session', 2, 'Omar Khaled', 12),
        'doctor_id': 'd1', 'shared_with': ['Dr. Mona Saeed']},
    {..._visit('a2', 'normal_pt_session', 3, 'Laila Fawzy', 13), 'doctor_id': 'd1', 'shared_with': []},
    {..._visit('a3', 'initial_assessment', 4, 'Hany Samir', 14), 'doctor_id': 'd1', 'shared_with': []},
    if (!oneDoctor)
      {..._visit('a1', 'normal_pt_session', 2, 'Omar Khaled', 12),
          'doctor_id': 'd2', 'shared_with': ['Dr. Ahmed Hassan']},
  ],
  'pending': [
    if (!oneDoctor)
      {..._visit('a4', 'reassessment', 5, 'Nour Ibrahim', 15), 'doctors': ['Dr. Karim Adel']},
  ],
};
