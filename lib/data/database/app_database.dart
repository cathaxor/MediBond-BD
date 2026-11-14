import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/app_settings_table.dart';
import 'tables/dose_events_table.dart';
import 'tables/dose_schedules_table.dart';
import 'tables/medicines_table.dart';
import 'tables/notification_jobs_table.dart';
import 'tables/prescriptions_table.dart';
import 'tables/profiles_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Profiles,
    Medicines,
    DoseSchedules,
    DoseEvents,
    Prescriptions,
    AppSettings,
    NotificationJobs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Future schema migrations will be handled here
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'medibond_bd.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
