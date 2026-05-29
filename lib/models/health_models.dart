enum Weather { sunny, partlyCloudy, cloudy, rainy, thunderstorm }

enum Mood { happy, okay, tired, frustrated, excited }

enum AppTab { today, summary, settings }

enum SupplementSlot { morning, noon, evening, bedtime }

enum PoopShape { type1, type2, type3, type4, type5, type6, type7 }

class WeatherOption {
  const WeatherOption(this.value, this.icon, this.label);
  final Weather value;
  final String icon;
  final String label;
}

class MoodOption {
  const MoodOption(this.value, this.icon, this.label);
  final Mood value;
  final String icon;
  final String label;
}

class PoopShapeOption {
  const PoopShapeOption(this.value, this.typeNumber, this.label);

  final PoopShape value;
  final int typeNumber;
  final String label;
}

const weatherOptions = [
  WeatherOption(Weather.sunny, '☀️', 'Sunny'),
  WeatherOption(Weather.partlyCloudy, '🌤️', 'Partly cloudy'),
  WeatherOption(Weather.cloudy, '☁️', 'Cloudy'),
  WeatherOption(Weather.rainy, '🌧️', 'Rainy'),
  WeatherOption(Weather.thunderstorm, '⛈️', 'Stormy'),
];

const moodOptions = [
  MoodOption(Mood.happy, '😊', 'Happy'),
  MoodOption(Mood.okay, '😐', 'Okay'),
  MoodOption(Mood.tired, '😴', 'Tired'),
  MoodOption(Mood.frustrated, '😤', 'Frustrated'),
  MoodOption(Mood.excited, '🤩', 'Excited'),
];

const poopShapeOptions = [
  PoopShapeOption(PoopShape.type1, 1, 'Hard lumps'),
  PoopShapeOption(PoopShape.type2, 2, 'Lumpy'),
  PoopShapeOption(PoopShape.type3, 3, 'Cracked'),
  PoopShapeOption(PoopShape.type4, 4, 'Smooth'),
  PoopShapeOption(PoopShape.type5, 5, 'Soft blobs'),
  PoopShapeOption(PoopShape.type6, 6, 'Mushy'),
  PoopShapeOption(PoopShape.type7, 7, 'Liquid'),
];

PoopShapeOption poopShapeOptionFor(PoopShape shape) {
  return poopShapeOptions.firstWhere((p) => p.value == shape);
}

const slotLabels = {
  SupplementSlot.morning: 'Morning',
  SupplementSlot.noon: 'Noon',
  SupplementSlot.evening: 'Evening',
  SupplementSlot.bedtime: 'Bedtime',
};

class DayEntry {
  const DayEntry({
    required this.date,
    this.weather,
    this.mood,
  });

  final String date;
  final Weather? weather;
  final Mood? mood;

  DayEntry copyWith({
    String? date,
    Weather? weather,
    Mood? mood,
    bool clearWeather = false,
    bool clearMood = false,
  }) {
    return DayEntry(
      date: date ?? this.date,
      weather: clearWeather ? null : (weather ?? this.weather),
      mood: clearMood ? null : (mood ?? this.mood),
    );
  }

  factory DayEntry.fromJson(Map<String, dynamic> json) {
    return DayEntry(
      date: json['date'] as String,
      weather: json['weather'] != null
          ? Weather.values.byName(json['weather'] as String)
          : null,
      mood: json['mood'] != null
          ? Mood.values.byName(json['mood'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        if (weather != null) 'weather': weather!.name,
        if (mood != null) 'mood': mood!.name,
      };
}

class PeriodEvent {
  const PeriodEvent({
    required this.id,
    required this.startDate,
    this.endDate,
  });

  final String id;
  final String startDate;
  final String? endDate;

  PeriodEvent copyWith({
    String? id,
    String? startDate,
    String? endDate,
    bool clearEndDate = false,
  }) {
    return PeriodEvent(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  factory PeriodEvent.fromJson(Map<String, dynamic> json) {
    return PeriodEvent(
      id: json['id'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };
}

class PoopLog {
  const PoopLog({
    required this.id,
    required this.date,
    required this.time,
    required this.shape,
  });

  final String id;
  final String date;
  final String time;
  final PoopShape shape;

  factory PoopLog.fromJson(Map<String, dynamic> json) {
    return PoopLog(
      id: json['id'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      shape: PoopShape.values.byName(json['shape'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'time': time,
        'shape': shape.name,
      };
}

class Supplement {
  const Supplement({
    required this.id,
    required this.name,
    this.dose,
    required this.slots,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String? dose;
  final List<SupplementSlot> slots;
  final bool enabled;

  Supplement copyWith({
    String? id,
    String? name,
    String? dose,
    List<SupplementSlot>? slots,
    bool? enabled,
  }) {
    return Supplement(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      slots: slots ?? this.slots,
      enabled: enabled ?? this.enabled,
    );
  }

  factory Supplement.fromJson(Map<String, dynamic> json) {
    return Supplement(
      id: json['id'] as String,
      name: json['name'] as String,
      dose: json['dose'] as String?,
      slots: (json['slots'] as List<dynamic>)
          .map((s) => SupplementSlot.values.byName(s as String))
          .toList(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (dose != null) 'dose': dose,
        'slots': slots.map((s) => s.name).toList(),
        'enabled': enabled,
      };
}

/// Per-item checklist stats for the summary screen (e.g. Iron 5 of 7 days).
class ChecklistItemStats {
  const ChecklistItemStats({
    required this.id,
    required this.name,
    required this.daysCompleted,
    required this.daysInWindow,
  });

  final String id;
  final String name;
  final int daysCompleted;
  final int daysInWindow;

  double get completionRatio =>
      daysInWindow <= 0 ? 0 : daysCompleted / daysInWindow;

  static List<ChecklistItemStats> computeBreakdown({
    required List<Supplement> supplements,
    required List<SupplementLog> logs,
    int days = 7,
    DateTime? now,
  }) {
    final enabled = supplements.where((s) => s.enabled).toList();
    if (enabled.isEmpty || days <= 0) return const [];

    final today = now ?? DateTime.now();
    final dateKeys = List.generate(
      days,
      (i) => _dateKeyFor(today.subtract(Duration(days: i))),
    );

    bool taken(String id, SupplementSlot slot, String date) => logs.any(
          (l) => l.date == date && l.supplementId == id && l.slot == slot,
        );

    final stats = [
      for (final s in enabled)
        ChecklistItemStats(
          id: s.id,
          name: s.name,
          daysCompleted: dateKeys
              .where(
                (date) => s.slots.every((slot) => taken(s.id, slot, date)),
              )
              .length,
          daysInWindow: days,
        ),
    ];
    stats.sort((a, b) {
      final byDays = b.daysCompleted.compareTo(a.daysCompleted);
      if (byDays != 0) return byDays;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return stats;
  }

  static String _dateKeyFor(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class SupplementLog {
  const SupplementLog({
    required this.date,
    required this.supplementId,
    required this.slot,
  });

  final String date;
  final String supplementId;
  final SupplementSlot slot;

  factory SupplementLog.fromJson(Map<String, dynamic> json) {
    return SupplementLog(
      date: json['date'] as String,
      supplementId: json['supplementId'] as String,
      slot: SupplementSlot.values.byName(json['slot'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'supplementId': supplementId,
        'slot': slot.name,
      };
}

class AppData {
  const AppData({
    required this.dayEntries,
    required this.periodEvents,
    required this.poopLogs,
    required this.supplements,
    required this.supplementLogs,
    this.averageCycleLength = 28,
  });

  final List<DayEntry> dayEntries;
  final List<PeriodEvent> periodEvents;
  final List<PoopLog> poopLogs;
  final List<Supplement> supplements;
  final List<SupplementLog> supplementLogs;
  final int averageCycleLength;

  AppData copyWith({
    List<DayEntry>? dayEntries,
    List<PeriodEvent>? periodEvents,
    List<PoopLog>? poopLogs,
    List<Supplement>? supplements,
    List<SupplementLog>? supplementLogs,
    int? averageCycleLength,
  }) {
    return AppData(
      dayEntries: dayEntries ?? this.dayEntries,
      periodEvents: periodEvents ?? this.periodEvents,
      poopLogs: poopLogs ?? this.poopLogs,
      supplements: supplements ?? this.supplements,
      supplementLogs: supplementLogs ?? this.supplementLogs,
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
    );
  }

  factory AppData.fromJson(Map<String, dynamic> json) {
    return AppData(
      dayEntries: (json['dayEntries'] as List<dynamic>? ?? [])
          .map((e) => DayEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      periodEvents: (json['periodEvents'] as List<dynamic>? ?? [])
          .map((e) => PeriodEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      poopLogs: (json['poopLogs'] as List<dynamic>? ?? [])
          .map((e) => PoopLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      supplements: (json['supplements'] as List<dynamic>? ?? [])
          .map((e) => Supplement.fromJson(e as Map<String, dynamic>))
          .toList(),
      supplementLogs: (json['supplementLogs'] as List<dynamic>? ?? [])
          .map((e) => SupplementLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageCycleLength: json['averageCycleLength'] as int? ?? 28,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayEntries': dayEntries.map((e) => e.toJson()).toList(),
        'periodEvents': periodEvents.map((e) => e.toJson()).toList(),
        'poopLogs': poopLogs.map((e) => e.toJson()).toList(),
        'supplements': supplements.map((e) => e.toJson()).toList(),
        'supplementLogs': supplementLogs.map((e) => e.toJson()).toList(),
        'averageCycleLength': averageCycleLength,
      };
}
