/// A durable editor destination, including after a browser reload.
enum ProgramEditSection {
  conditions,
  findings,
  documents;

  static ProgramEditSection fromQuery(String? value) =>
      values.where((section) => section.name == value).firstOrNull ?? conditions;
}
