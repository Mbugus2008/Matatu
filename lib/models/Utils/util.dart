import 'package:intl/intl.dart';

DateFormat formattedDate = DateFormat('MM/dd/yyyy');
DateFormat formattedDate2 = DateFormat('dd-MMM-yyyy');
DateFormat formattedDateTime = DateFormat('MM/dd/yyyy HH:mm:ss');
DateFormat printedon = DateFormat('dd-MMM-yy HH:mm:ss');
DateFormat formattedTime = DateFormat('HH:mm:ss');

DateTime getdate() {
  DateTime d = DateTime.now();
  int year = d.year;
  int month = d.month;
  int day = d.day;
  return DateTime(year, month, day);
}

DateTime getdatetime() {
  DateTime d = DateTime.now();
  int year = d.year;
  int month = d.month;
  int day = d.day;

  return DateTime(year, month, day, d.hour, d.minute, d.second, d.millisecond,
      d.microsecond);
}

DateTime getnulldatetime() {
  DateTime d = DateTime.now();
  int year = d.year;
  int month = d.month;
  int day = d.day;

  return DateTime(year, month, day, d.hour, 0, 0, 0, d.microsecond);
}

DateTime getdates(DateTime? d) {
  if (d != null ) {
    int year = d.year;
    int month = d.month;
    int day = d.day;
    return DateTime(year, month, day);
  }
  return getdate();
}

extension StringExtensions on String? {
  bool get isNullOrEmpty {
    return this == null || this!.isEmpty;
  }
}
