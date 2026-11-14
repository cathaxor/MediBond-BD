import 'package:drift/drift.dart';

import 'profiles_table.dart';

@DataClassName('MedicineData')
class Medicines extends Table {
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get profileId =>
      text().references(Profiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get strength =>
      text().withDefault(const Constant(''))(); // e.g. 500mg
  TextColumn get form =>
      text()(); // tablet, capsule, liquid, injection, drops, ointment, other
  TextColumn get dosage => text()();
  TextColumn get instructions => text()(); // beforeFood, afterFood, etc.
  IntColumn get timesPerDay => integer().withDefault(const Constant(1))();
  IntColumn get stockCount => integer().withDefault(const Constant(0))();
  IntColumn get reorderThreshold => integer().withDefault(const Constant(5))();
  IntColumn get colorHex => integer().withDefault(const Constant(0xFF087F79))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get weekdays =>
      text().withDefault(const Constant('1,2,3,4,5,6,7'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
