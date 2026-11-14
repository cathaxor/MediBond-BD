import 'package:drift/drift.dart';

import 'profiles_table.dart';

@DataClassName('PrescriptionData')
class Prescriptions extends Table {
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get profileId =>
      text().references(Profiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get doctorName => text()();
  TextColumn get hospitalName => text()();
  DateTimeColumn get date => dateTime()(); // UTC
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get tags =>
      text().withDefault(const Constant(''))(); // Comma-separated tags
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
