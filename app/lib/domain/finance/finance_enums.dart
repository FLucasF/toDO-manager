import '../enums.dart' show Coded;

/// Money in (receita) or out (despesa).
enum FinKind implements Coded<String> {
  income('income'),
  expense('expense');

  const FinKind(this.code);
  @override
  final String code;

  static FinKind fromCode(String code) =>
      values.firstWhere((k) => k.code == code, orElse: () => throw FormatException('unknown finance kind: $code'));
}

/// How often a recurring bill ("conta fixa") comes back.
enum FinFrequency implements Coded<String> {
  monthly('monthly'),
  yearly('yearly');

  const FinFrequency(this.code);
  @override
  final String code;

  static FinFrequency fromCode(String code) =>
      values.firstWhere((f) => f.code == code, orElse: () => throw FormatException('unknown finance frequency: $code'));
}
