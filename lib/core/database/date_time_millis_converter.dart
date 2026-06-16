import 'package:drift/drift.dart';

class DateTimeMillisConverter extends TypeConverter<DateTime, int> {
  const DateTimeMillisConverter();

  @override
  DateTime fromSql(int fromDb) {
    return DateTime.fromMillisecondsSinceEpoch(fromDb);
  }

  @override
  int toSql(DateTime value) {
    return value.millisecondsSinceEpoch;
  }
}
