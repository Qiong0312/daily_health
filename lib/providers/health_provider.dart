import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/storage.dart';
import '../models/health_models.dart';
import '../utils/date_utils.dart';
import '../widget/widget_bridge.dart';

class HealthProvider extends ChangeNotifier {
  HealthProvider();

  static const _uuid = Uuid();

  AppData _data = emptyAppData;
  var _ready = false;

  AppData get data => _data;
  bool get ready => _ready;

  Future<void> init() async {
    var data = await loadAppData();
    data = await WidgetBridge.importIfNeeded(data);
    _data = data;
    await saveAppData(_data);
    _ready = true;
    notifyListeners();
    if (WidgetBridge.isSupported) {
      await WidgetBridge.exportSnapshot(_data);
      await syncFromWidget();
    }
  }

  /// Merge widget edits (period, Bristol, supplements) into app state.
  Future<void> syncFromWidget() async {
    if (!WidgetBridge.isSupported || !_ready) return;
    final merged = await WidgetBridge.importIfNeeded(_data);
    if (identical(merged, _data)) return;
    _data = merged;
    await saveAppData(_data);
    await WidgetBridge.exportSnapshot(_data);
    notifyListeners();
  }

  Future<void> _persist() async {
    await saveAppData(_data);
    await WidgetBridge.exportSnapshot(_data);
    notifyListeners();
  }

  DayEntry? getEntryForDate(String date) {
    try {
      return _data.dayEntries.firstWhere((e) => e.date == date);
    } catch (_) {
      return null;
    }
  }

  DayEntry? getTodayEntry() => getEntryForDate(todayKey());

  void setWeather(Weather weather) => _upsertToday((e) => e.copyWith(weather: weather));

  void setMood(Mood mood) => _upsertToday((e) => e.copyWith(mood: mood));

  void _upsertToday(DayEntry Function(DayEntry) update) {
    final date = todayKey();
    final existing = getEntryForDate(date);
    final updated = existing != null
        ? update(existing)
        : update(DayEntry(date: date));

    final entries = [..._data.dayEntries.where((e) => e.date != date), updated];
    _data = _data.copyWith(dayEntries: entries);
    _persist();
  }

  PeriodEvent? getOpenPeriod() {
    final today = todayKey();
    for (final event in _data.periodEvents.reversed) {
      if (event.endDate == null || event.endDate!.compareTo(today) >= 0) {
        if (event.startDate.compareTo(today) <= 0 ||
            (event.endDate != null && event.endDate!.compareTo(today) >= 0)) {
          return event;
        }
      }
    }
    for (final event in _data.periodEvents.reversed) {
      if (event.endDate == null) return event;
    }
    return null;
  }

  bool isOnPeriod([String? date]) {
    final key = date ?? todayKey();
    return _data.periodEvents.any((e) => isDateInPeriod(key, e));
  }

  int? getCycleDay([String? date]) {
    final key = date ?? todayKey();
    for (final event in _data.periodEvents.reversed) {
      if (isDateInPeriod(key, event)) {
        return daysBetween(event.startDate, key) + 1;
      }
    }
    final lastEnded = _data.periodEvents
        .where((e) => e.endDate != null)
        .toList()
      ..sort((a, b) => b.endDate!.compareTo(a.endDate!));
    if (lastEnded.isEmpty) return null;
    final last = lastEnded.first;
    return daysBetween(last.endDate!, key);
  }

  /// Average days between consecutive period **starts**, when at least two logs exist.
  int? averageCycleLengthFromHistory() {
    final events = [..._data.periodEvents];
    if (events.length < 2) return null;
    events.sort((a, b) => a.startDate.compareTo(b.startDate));
    var sum = 0;
    for (var i = 0; i < events.length - 1; i++) {
      sum += daysBetween(events[i].startDate, events[i + 1].startDate);
    }
    final n = events.length - 1;
    return (sum / n).round().clamp(21, 45);
  }

  /// Prefer history when ≥2 periods; otherwise [AppData.averageCycleLength] from Settings.
  int effectiveCycleLengthForPrediction() {
    return averageCycleLengthFromHistory() ?? _data.averageCycleLength;
  }

  /// Estimated first day of the next cycle from the latest logged start + cycle length.
  String? predictedNextPeriodStartKey() {
    if (_data.periodEvents.isEmpty) return null;
    final events = [..._data.periodEvents]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final lastStart = events.last.startDate;
    return addDaysToDateKey(lastStart, effectiveCycleLengthForPrediction());
  }

  void startPeriodToday() {
    setPeriodStartOnDate(todayKey());
  }

  void endPeriodToday() {
    setPeriodEndOnDate(todayKey());
  }

  /// Sets period bleeding start on [dateKey]. Opens a new ongoing period from that date
  /// and trims or removes overlapping later data.
  void setPeriodStartOnDate(String dateKey) {
    final list = <PeriodEvent>[];

    for (final e in _data.periodEvents) {
      if (e.startDate.compareTo(dateKey) > 0) continue;

      if (e.endDate != null) {
        if (e.endDate!.compareTo(dateKey) < 0) {
          list.add(e);
          continue;
        }
        if (e.startDate.compareTo(dateKey) < 0) {
          final prev = addDaysToDateKey(dateKey, -1);
          if (prev.compareTo(e.startDate) >= 0) {
            list.add(e.copyWith(endDate: prev));
          }
        }
        continue;
      }

      if (dateKey.compareTo(e.startDate) <= 0) continue;

      final prev = addDaysToDateKey(dateKey, -1);
      if (prev.compareTo(e.startDate) >= 0) {
        list.add(e.copyWith(endDate: prev));
      }
    }

    list.removeWhere((e) => e.startDate == dateKey && e.endDate == null);

    list.add(PeriodEvent(id: _uuid.v4(), startDate: dateKey, endDate: null));
    list.sort((a, b) => a.startDate.compareTo(b.startDate));

    _data = _data.copyWith(periodEvents: list);
    _persist();
  }

  /// Clears bleeding on a specific [dateKey], adjusting or splitting spans as needed.
  void clearPeriodOnDate(String dateKey) {
    final updated = <PeriodEvent>[];

    for (final e in _data.periodEvents) {
      final inSpan = isDateInPeriod(dateKey, e);
      if (!inSpan) {
        updated.add(e);
        continue;
      }

      final start = e.startDate;
      final end = e.endDate ?? todayKey();

      if (start == end && start == dateKey) {
        // Whole span is just this day: drop it.
        continue;
      }

      if (start == dateKey) {
        // Trim start forward by one day.
        final next = addDaysToDateKey(dateKey, 1);
        if (next.compareTo(end) <= 0) {
          updated.add(e.copyWith(startDate: next));
        }
        continue;
      }

      if (end == dateKey) {
        // Trim end backward by one day.
        final prev = addDaysToDateKey(dateKey, -1);
        if (prev.compareTo(start) >= 0) {
          updated.add(e.copyWith(endDate: prev));
        }
        continue;
      }

      // Middle of a span: split into two.
      final prev = addDaysToDateKey(dateKey, -1);
      final next = addDaysToDateKey(dateKey, 1);
      if (prev.compareTo(start) >= 0) {
        updated.add(e.copyWith(endDate: prev));
      }
      if (next.compareTo(end) <= 0) {
        updated.add(
          PeriodEvent(
            id: _uuid.v4(),
            startDate: next,
            endDate: e.endDate,
          ),
        );
      }
    }

    updated.sort((a, b) => a.startDate.compareTo(b.startDate));
    _data = _data.copyWith(periodEvents: updated);
    _persist();
  }

  /// Sets period end on [dateKey] for the most relevant span (latest start ≤ that day).
  void setPeriodEndOnDate(String dateKey) {
    var list = [..._data.periodEvents];
    PeriodEvent? target;
    for (final e in list) {
      if (e.startDate.compareTo(dateKey) > 0) continue;
      if (e.endDate != null && e.endDate!.compareTo(dateKey) < 0) continue;
      if (target == null || e.startDate.compareTo(target.startDate) > 0) {
        target = e;
      }
    }

    if (target == null) {
      list.add(PeriodEvent(id: _uuid.v4(), startDate: dateKey, endDate: dateKey));
    } else {
      final i = list.indexWhere((x) => x.id == target!.id);
      list[i] = target.copyWith(endDate: dateKey);
    }

    list.sort((a, b) => a.startDate.compareTo(b.startDate));

    _data = _data.copyWith(periodEvents: list);
    _persist();
  }

  List<PoopLog> getPoopLogsForDate(String date) {
    return _data.poopLogs.where((l) => l.date == date).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<PoopLog> getTodayPoopLogs() => getPoopLogsForDate(todayKey());

  void addPoopLog(PoopShape shape) {
    final now = DateTime.now();
    final log = PoopLog(
      id: _uuid.v4(),
      date: todayKey(now),
      time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      shape: shape,
    );
    _data = _data.copyWith(poopLogs: [..._data.poopLogs, log]);
    _persist();
  }

  void removePoopLog(String id) {
    _data = _data.copyWith(
      poopLogs: _data.poopLogs.where((l) => l.id != id).toList(),
    );
    _persist();
  }

  List<Supplement> get enabledSupplements =>
      _data.supplements.where((s) => s.enabled).toList();

  bool isSupplementTaken(String supplementId, SupplementSlot slot, [String? date]) {
    final key = date ?? todayKey();
    return _data.supplementLogs.any(
      (l) => l.date == key && l.supplementId == supplementId && l.slot == slot,
    );
  }

  void toggleSupplement(String supplementId, SupplementSlot slot) {
    final date = todayKey();
    final existing = _data.supplementLogs.where(
      (l) => !(l.date == date && l.supplementId == supplementId && l.slot == slot),
    );

    final wasTaken = _data.supplementLogs.length != existing.length;
    final logs = wasTaken
        ? existing.toList()
        : [...existing, SupplementLog(date: date, supplementId: supplementId, slot: slot)];

    _data = _data.copyWith(supplementLogs: logs);
    _persist();
  }

  void addSupplement(String name, {String? dose, List<SupplementSlot>? slots}) {
    final supplement = Supplement(
      id: _uuid.v4(),
      name: name.trim(),
      dose: dose?.trim().isEmpty == true ? null : dose?.trim(),
      slots: slots ?? [SupplementSlot.morning],
    );
    _data = _data.copyWith(supplements: [..._data.supplements, supplement]);
    _persist();
  }

  void updateSupplement(Supplement supplement) {
    _data = _data.copyWith(
      supplements: _data.supplements
          .map((s) => s.id == supplement.id ? supplement : s)
          .toList(),
    );
    _persist();
  }

  void removeSupplement(String id) {
    _data = _data.copyWith(
      supplements: _data.supplements.where((s) => s.id != id).toList(),
      supplementLogs: _data.supplementLogs.where((l) => l.supplementId != id).toList(),
    );
    _persist();
  }

  /// Reorder only enabled supplements as shown on the Today tab.
  /// Disabled supplements keep their relative order and remain after enabled ones.
  void reorderEnabledSupplements(int oldIndex, int newIndex) {
    final enabled = [...enabledSupplements];
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex < 0 || oldIndex >= enabled.length) return;
    if (newIndex < 0 || newIndex >= enabled.length) return;

    final moved = enabled.removeAt(oldIndex);
    enabled.insert(newIndex, moved);

    final enabledIds = enabled.map((s) => s.id).toSet();
    final disabled = _data.supplements.where((s) => !enabledIds.contains(s.id)).toList();

    _data = _data.copyWith(supplements: [...enabled, ...disabled]);
    _persist();
  }

  void setAverageCycleLength(int days) {
    _data = _data.copyWith(averageCycleLength: days.clamp(21, 45));
    _persist();
  }

  double getSupplementAdherence({int days = 7}) {
    final breakdown = getChecklistBreakdown(days: days);
    if (breakdown.isEmpty) return 0;
    final sum = breakdown.fold<double>(
      0,
      (total, item) => total + item.completionRatio,
    );
    return sum / breakdown.length;
  }

  List<ChecklistItemStats> getChecklistBreakdown({int days = 7}) {
    return ChecklistItemStats.computeBreakdown(
      supplements: _data.supplements,
      logs: _data.supplementLogs,
      days: days,
    );
  }

  List<PeriodEvent> get sortedPeriodEvents {
    final events = [..._data.periodEvents];
    events.sort((a, b) => b.startDate.compareTo(a.startDate));
    return events;
  }
}
