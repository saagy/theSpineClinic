/// Text for discounts given on an invoice after it was issued.
final class InvoiceDiscountStrings {
  const InvoiceDiscountStrings();

  // Actions
  final String addDiscount = 'Add discount';
  final String recorded = 'Discount recorded';

  // Form
  final String title = 'Discount';
  String screenTitle(String number) => 'Discount · $number';
  final String sectionAmount = 'Discount';
  String fieldsHelp(String value) =>
      'The invoice keeps its number and payments. A percentage is of the invoice value now, $value. 100% makes it free.';
  final String amountInvalid = 'Enter an amount up to the invoice value now';
  final String empty = 'Enter a percentage or an amount.';
  final String nothingLeft = 'Nothing is left to discount on this invoice.';
  final String details = 'Discount details';
  final String paybackNone =
      'No money is paid back. This discount only lowers what the patient owes.';
  final String reasonHint = 'For example, who approved it';
  final String summary = 'Discount summary';
  final String record = 'Record discount';

  // Invoice view
  String number(String number) => 'Discount $number';
  final String laterDiscounts = 'Discounts after issue';

  // Cancelling
  final String voidTitle = 'Cancel discount';
  final String voidHelp = 'The invoice value and any money paid back are restored.';
  final String voided = 'Discount cancelled';

  // Printed document
  final String document = 'Discount';
  final String columnDiscount = 'Discount';
}
