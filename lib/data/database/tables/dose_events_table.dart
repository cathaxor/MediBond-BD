import 'package:drift/drift.dart';

import 'medicines_table.dart';
import 'profiles_table.dart';

@DataClassName('DoseEventData')
class DoseEvents extends Table {
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get medicineId =>
      text().references(Medicines, #id, onDelete: KeyAction.cascade)();
  TextColumn get profileId =>
      text().references(Profiles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledAt => dateTime()(); // UTC
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, taken, missed, skipped
  DateTimeColumn get actionAt => dateTime().nullable()(); // UTC
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
