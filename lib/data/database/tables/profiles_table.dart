import 'package:drift/drift.dart';

@DataClassName('ProfileData')
class Profiles extends Table {
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get relationship => text()();
  TextColumn get relationshipBn => text()();
  IntColumn get age => integer()();
  TextColumn get bloodGroup => text()();
  TextColumn get avatarInitials => text()();
  IntColumn get avatarColorValue => integer()();
  TextColumn get emergencyContact => text()();
  TextColumn get medicalNotes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
