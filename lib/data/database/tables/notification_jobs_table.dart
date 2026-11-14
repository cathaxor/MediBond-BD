import 'package:drift/drift.dart';

import 'dose_events_table.dart';

@DataClassName('NotificationJobData')
class NotificationJobs extends Table {
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get doseEventId =>
      text().references(DoseEvents, #id, onDelete: KeyAction.cascade)();
  IntColumn get notificationId => integer()();
  DateTimeColumn get scheduledAt => dateTime()(); // UTC
  BoolColumn get isDelivered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
