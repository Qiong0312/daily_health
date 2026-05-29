import '../models/health_models.dart';
import '../utils/date_utils.dart';

/// JSON shared with the iOS home screen widget (App Group file).
class WidgetSnapshot {
  const WidgetSnapshot({
    this.version = 1,
    required this.updatedAt,
    this.needsAppSync = false,
    required this.dateKey,
    this.averageCycleLength = 28,
    this.periodEvents = const [],
    this.supplements = const [],
    this.supplementDoses = const [],
    this.poopLogsToday = const [],
    this.periodEndedTimeToday,
  });

  final int version;
  final String updatedAt;
  final bool needsAppSync;
  final String dateKey;
  final int averageCycleLength;
  final List<WidgetSnapshotPeriodEvent> periodEvents;
  final List<WidgetSnapshotSupplement> supplements;
  final List<WidgetSnapshotSupplementDose> supplementDoses;
  final List<WidgetSnapshotPoopLog> poopLogsToday;
  final String? periodEndedTimeToday;

  Map<String, dynamic> toJson() => {
        'version': version,
        'updatedAt': updatedAt,
        'needsAppSync': needsAppSync,
        'dateKey': dateKey,
        'averageCycleLength': averageCycleLength,
        'periodEvents': periodEvents.map((e) => e.toJson()).toList(),
        'supplements': supplements.map((s) => s.toJson()).toList(),
        'supplementDoses': supplementDoses.map((d) => d.toJson()).toList(),
        'poopLogsToday': poopLogsToday.map((p) => p.toJson()).toList(),
        if (periodEndedTimeToday != null)
          'periodEndedTimeToday': periodEndedTimeToday,
      };

  factory WidgetSnapshot.fromJson(Map<String, dynamic> json) {
    return WidgetSnapshot(
      version: json['version'] as int? ?? 1,
      updatedAt: json['updatedAt'] as String? ?? '',
      needsAppSync: json['needsAppSync'] as bool? ?? false,
      dateKey: json['dateKey'] as String? ?? todayKey(),
      averageCycleLength: json['averageCycleLength'] as int? ?? 28,
      periodEvents: (json['periodEvents'] as List<dynamic>? ?? [])
          .map((e) => WidgetSnapshotPeriodEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      supplements: (json['supplements'] as List<dynamic>? ?? [])
          .map((e) => WidgetSnapshotSupplement.fromJson(e as Map<String, dynamic>))
          .toList(),
      supplementDoses: (json['supplementDoses'] as List<dynamic>? ?? [])
          .map((e) => WidgetSnapshotSupplementDose.fromJson(e as Map<String, dynamic>))
          .toList(),
      poopLogsToday: (json['poopLogsToday'] as List<dynamic>? ?? [])
          .map((e) => WidgetSnapshotPoopLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      periodEndedTimeToday: json['periodEndedTimeToday'] as String?,
    );
  }

  static WidgetSnapshot fromAppData(AppData data) {
    final dateKey = todayKey();
    final enabled = data.supplements.where((s) => s.enabled).toList();

    final doses = <WidgetSnapshotSupplementDose>[];
    for (final s in enabled) {
      for (final slot in s.slots) {
        doses.add(
          WidgetSnapshotSupplementDose(
            supplementId: s.id,
            slot: slot.name,
            taken: data.supplementLogs.any(
              (l) => l.date == dateKey && l.supplementId == s.id && l.slot == slot,
            ),
          ),
        );
      }
    }

    final poopToday = data.poopLogs
        .where((l) => l.date == dateKey)
        .map(
          (l) => WidgetSnapshotPoopLog(
            id: l.id,
            date: l.date,
            time: l.time,
            shape: l.shape.name,
          ),
        )
        .toList();

    return WidgetSnapshot(
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      needsAppSync: false,
      dateKey: dateKey,
      averageCycleLength: data.averageCycleLength,
      periodEvents: data.periodEvents
          .map(
            (e) => WidgetSnapshotPeriodEvent(
              id: e.id,
              startDate: e.startDate,
              endDate: e.endDate,
            ),
          )
          .toList(),
      supplements: enabled
          .map(
            (s) => WidgetSnapshotSupplement(
              id: s.id,
              name: s.name,
              dose: s.dose,
              slots: s.slots.map((sl) => sl.name).toList(),
            ),
          )
          .toList(),
      supplementDoses: doses,
      poopLogsToday: poopToday,
    );
  }

  static AppData mergeIntoAppData(AppData data, WidgetSnapshot snapshot) {
    final dateKey = snapshot.dateKey;

    final periodEvents = snapshot.periodEvents
        .map(
          (e) => PeriodEvent(
            id: e.id,
            startDate: e.startDate,
            endDate: e.endDate,
          ),
        )
        .toList();

    var supplementLogs = data.supplementLogs
        .where((l) => l.date != dateKey)
        .toList();

    for (final dose in snapshot.supplementDoses) {
      if (!dose.taken) continue;
      try {
        final slot = SupplementSlot.values.byName(dose.slot);
        supplementLogs.add(
          SupplementLog(
            date: dateKey,
            supplementId: dose.supplementId,
            slot: slot,
          ),
        );
      } catch (_) {
        // ignore unknown slot
      }
    }

    final widgetPoopToday = <PoopLog>[];
    for (final p in snapshot.poopLogsToday) {
      try {
        widgetPoopToday.add(
          PoopLog(
            id: p.id,
            date: p.date,
            time: p.time,
            shape: PoopShape.values.byName(p.shape),
          ),
        );
      } catch (_) {
        // skip malformed widget entries
      }
    }
    final poopLogs = [
      ...data.poopLogs.where((l) => l.date != dateKey),
      ...widgetPoopToday,
    ];

    return data.copyWith(
      periodEvents: periodEvents,
      supplementLogs: supplementLogs,
      poopLogs: poopLogs,
      averageCycleLength: snapshot.averageCycleLength,
    );
  }
}

class WidgetSnapshotPeriodEvent {
  const WidgetSnapshotPeriodEvent({
    required this.id,
    required this.startDate,
    this.endDate,
  });

  final String id;
  final String startDate;
  final String? endDate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

  factory WidgetSnapshotPeriodEvent.fromJson(Map<String, dynamic> json) {
    return WidgetSnapshotPeriodEvent(
      id: json['id'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String?,
    );
  }
}

class WidgetSnapshotSupplement {
  const WidgetSnapshotSupplement({
    required this.id,
    required this.name,
    this.dose,
    required this.slots,
  });

  final String id;
  final String name;
  final String? dose;
  final List<String> slots;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (dose != null) 'dose': dose,
        'slots': slots,
      };

  factory WidgetSnapshotSupplement.fromJson(Map<String, dynamic> json) {
    return WidgetSnapshotSupplement(
      id: json['id'] as String,
      name: json['name'] as String,
      dose: json['dose'] as String?,
      slots: (json['slots'] as List<dynamic>).map((s) => s as String).toList(),
    );
  }
}

class WidgetSnapshotSupplementDose {
  const WidgetSnapshotSupplementDose({
    required this.supplementId,
    required this.slot,
    required this.taken,
  });

  final String supplementId;
  final String slot;
  final bool taken;

  Map<String, dynamic> toJson() => {
        'supplementId': supplementId,
        'slot': slot,
        'taken': taken,
      };

  factory WidgetSnapshotSupplementDose.fromJson(Map<String, dynamic> json) {
    return WidgetSnapshotSupplementDose(
      supplementId: json['supplementId'] as String,
      slot: json['slot'] as String,
      taken: json['taken'] as bool? ?? false,
    );
  }
}

class WidgetSnapshotPoopLog {
  const WidgetSnapshotPoopLog({
    required this.id,
    required this.date,
    required this.time,
    required this.shape,
  });

  final String id;
  final String date;
  final String time;
  final String shape;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'time': time,
        'shape': shape,
      };

  factory WidgetSnapshotPoopLog.fromJson(Map<String, dynamic> json) {
    return WidgetSnapshotPoopLog(
      id: json['id'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      shape: json['shape'] as String,
    );
  }
}
