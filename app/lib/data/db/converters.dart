import 'package:drift/drift.dart';

import '../../domain/enums.dart';

/// Stores a [Coded] enum by its TickTick code. An unknown code in the database throws
/// [FormatException] instead of silently becoming a default value.
class IntCodeConverter<T extends Coded<int>> extends TypeConverter<T, int> {
  const IntCodeConverter(this._fromCode);

  final T Function(int) _fromCode;

  @override
  T fromSql(int fromDb) => _fromCode(fromDb);

  @override
  int toSql(T value) => value.code;
}

class TextCodeConverter<T extends Coded<String>> extends TypeConverter<T, String> {
  const TextCodeConverter(this._fromCode);

  final T Function(String) _fromCode;

  @override
  T fromSql(String fromDb) => _fromCode(fromDb);

  @override
  String toSql(T value) => value.code;
}
