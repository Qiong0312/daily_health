import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/defaults.dart';
import '../models/health_models.dart';

const storageKey = 'bloom_health_data';
const _uuid = Uuid();

const emptyAppData = AppData(
  dayEntries: [],
  periodEvents: [],
  poopLogs: [],
  supplements: [],
  supplementLogs: [],
);

AppData seedDefaultSupplements(AppData data) {
  if (data.supplements.isNotEmpty) return data;

  final supplements = defaultSupplements
      .map(
        (s) => Supplement(
          id: _uuid.v4(),
          name: s.name,
          dose: s.dose,
          slots: s.slots,
        ),
      )
      .toList();

  return data.copyWith(supplements: supplements);
}

Future<AppData> loadAppData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return seedDefaultSupplements(emptyAppData);

    final parsed = AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return seedDefaultSupplements(parsed);
  } catch (_) {
    return seedDefaultSupplements(emptyAppData);
  }
}

Future<void> saveAppData(AppData data) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(storageKey, jsonEncode(data.toJson()));
}
