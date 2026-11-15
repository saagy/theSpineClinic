/// Text for correcting a patient's session balances by hand and the record
/// those corrections leave.
final class BalanceStrings {
  const BalanceStrings();

  final String adjust = 'Adjust balance';
  final String shortAtBooking =
      'You can still book. Each check-in uses a session, so add the sessions on an invoice '
      'before the visit.';
  final String title = 'Adjust session balances';
  final String help =
      'Use this to correct a balance, for example sessions carried over from the old system. '
      'Invoices, refunds and check-ins already change the balance by themselves.';
  final String ptSessions = 'PT sessions';
  final String tractionSessions = 'Traction sessions';
  String now(int value) => 'Now $value';
  final String reason = 'Reason';
  final String reasonHint = 'For example: sessions carried over from the paper file';
  final String reasonRequired = 'Enter a reason.';
  final String wholeNumber = 'Enter a whole number, 0 or more.';
  final String noChange = 'Change at least one balance.';
  final String save = 'Save balances';
  final String cancel = 'Cancel';
  final String saved = 'Balances updated.';

  // Record of corrections.
  final String history = 'Balance corrections';
  final String historyError = 'Balance corrections could not be loaded.';
  String change(String label, int before, int after) => '$label $before → $after';
  String by(String name, String when) => '$name · $when';

  Map<String, String> get errorKeys => {
    'balance_changed':
        'The balance changed while you were editing. Check the new numbers and try again.',
    'invalid_adjustment': 'Balances must be 0 or more, and a reason is required.',
  };
}
