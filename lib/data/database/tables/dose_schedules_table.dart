import 'package:drift/drift.dart';

import 'medicines_table.dart';

@DataClassName('DoseScheduleData')
class DoseSchedules extends Table {
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get medicineId =>
      text().references(Medicines, #id, onDelete: KeyAction.cascade)();
  IntColumn get timeHour => integer()(); // 0-23
  IntColumn get timeMinute => integer()(); // 0-59
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
