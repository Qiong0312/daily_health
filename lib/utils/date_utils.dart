import 'package:intl/intl.dart';

import '../models/health_models.dart';

String todayKey([DateTime? ref]) => formatDateKey(ref ?? DateTime.now());

String formatDateKey(DateTime date) {
  final y = date.year;
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String formatDisplayDate(DateTime date) {
  return DateFormat('EEEE, MMMM d', 'en_US').format(date);
}

String formatShortDate(DateTime date) {
  return DateFormat('MMM d', 'en_US').format(date);
}

String formatMonthYear(DateTime date) {
  return DateFormat('MMMM yyyy', 'en_US').format(date);
}

DateTime parseDateKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

/// Move [key] forward or backward by whole days (local calendar).
String addDaysToDateKey(String key, int days) {
  final dt = parseDateKey(key).add(Duration(days: days));
  return formatDateKey(dt);
}

int daysBetween(String startKey, String endKey) {
  final start = parseDateKey(startKey);
  final end = parseDateKey(endKey);
  return end.difference(start).inDays;
}

bool isDateInPeriod(String dateKey, PeriodEvent event) {
  if (dateKey.compareTo(event.startDate) < 0) return false;
  final end = event.endDate ?? todayKey();
  return dateKey.compareTo(end) <= 0;
}

int getDaysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

String formatTime(DateTime time) {
  return DateFormat('h:mm a', 'en_US').format(time);
}
