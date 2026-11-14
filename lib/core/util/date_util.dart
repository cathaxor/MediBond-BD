class DateUtil {
  /// Converts local DateTime to explicit UTC for database persistence
  static DateTime toUtc(DateTime dt) {
    return dt.toUtc();
  }

  /// Converts stored UTC DateTime back to local timezone for UI display
  static DateTime toLocal(DateTime dt) {
    return dt.toLocal();
  }

  /// Formats UTC DateTime as ISO-8601 string
  static String toIso8601(DateTime dt) {
    return dt.toUtc().toIso8601String();
  }

  /// Parses ISO-8601 string to local DateTime
  static DateTime fromIso8601(String iso) {
    return DateTime.parse(iso).toLocal();
  }
}
