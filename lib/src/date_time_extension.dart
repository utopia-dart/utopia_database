extension DateTimeExtension on DateTime {
  String format() {
    return toString().split('.')[0];
  }

  DateTime addSeconds(int seconds) {
    var interval = Duration(seconds: seconds);
    return add(interval);
  }

  String? formatTz(String? dbFormat) {
    if (dbFormat == null) {
      return null;
    }

    try {
      return '${toUtc().toString().split('.')[0]}Z';
    } catch (e) {
      return dbFormat;
    }
  }
}
