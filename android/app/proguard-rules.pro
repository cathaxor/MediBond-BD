# ProGuard / R8 rules for MediBond BD

# Flutter Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Drift & SQLite
-keep class * extends drift.** { *; }
-keep class * extends sqlite3.** { *; }
-dontwarn com.sqlite.database.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Flutter Secure Storage
-keep class com.it_effekt.flutter_secure_storage.** { *; }
