import 'package:daily_health/data/storage.dart';
import 'package:daily_health/models/health_models.dart';
import 'package:daily_health/widget/widget_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WidgetSnapshot.mergeIntoAppData', () {
    test('merges Bristol log from widget', () {
      const snapshot = WidgetSnapshot(
        updatedAt: 't',
        needsAppSync: true,
        dateKey: '2026-05-27',
        poopLogsToday: [
          WidgetSnapshotPoopLog(
            id: 'w1',
            date: '2026-05-27',
            time: '09:30',
            shape: 'type3',
          ),
        ],
      );

      final merged = WidgetSnapshot.mergeIntoAppData(emptyAppData, snapshot);
      expect(merged.poopLogs, hasLength(1));
      expect(merged.poopLogs.first.shape, PoopShape.type3);
    });

    test('widget Bristol replaces prior logs for today on sync', () {
      final data = emptyAppData.copyWith(
        poopLogs: [
          const PoopLog(
            id: 'old',
            date: '2026-05-27',
            time: '08:00',
            shape: PoopShape.type2,
          ),
        ],
      );
      const snapshot = WidgetSnapshot(
        updatedAt: 't',
        needsAppSync: true,
        dateKey: '2026-05-27',
        poopLogsToday: [
          WidgetSnapshotPoopLog(
            id: 'w1',
            date: '2026-05-27',
            time: '09:30',
            shape: 'type5',
          ),
        ],
      );

      final merged = WidgetSnapshot.mergeIntoAppData(data, snapshot);
      expect(merged.poopLogs, hasLength(1));
      expect(merged.poopLogs.first.shape, PoopShape.type5);
    });

    test('merges period start from widget', () {
      const snapshot = WidgetSnapshot(
        updatedAt: 't',
        needsAppSync: true,
        dateKey: '2026-05-27',
        periodEvents: [
          WidgetSnapshotPeriodEvent(
            id: 'p1',
            startDate: '2026-05-27',
          ),
        ],
      );

      final merged = WidgetSnapshot.mergeIntoAppData(emptyAppData, snapshot);
      expect(merged.periodEvents, hasLength(1));
      expect(merged.periodEvents.first.startDate, '2026-05-27');
      expect(merged.periodEvents.first.endDate, isNull);
    });

    test('merges supplement taken and respects untaken', () {
      final data = emptyAppData.copyWith(
        supplements: [
          const Supplement(
            id: 's1',
            name: 'Iron',
            enabled: true,
            slots: [SupplementSlot.morning],
          ),
        ],
        supplementLogs: [
          const SupplementLog(
            date: '2026-05-27',
            supplementId: 's1',
            slot: SupplementSlot.morning,
          ),
        ],
      );

      const snapshot = WidgetSnapshot(
        updatedAt: 't',
        needsAppSync: true,
        dateKey: '2026-05-27',
        supplements: [
          WidgetSnapshotSupplement(
            id: 's1',
            name: 'Iron',
            slots: ['morning'],
          ),
        ],
        supplementDoses: [
          WidgetSnapshotSupplementDose(
            supplementId: 's1',
            slot: 'morning',
            taken: false,
          ),
        ],
      );

      final merged = WidgetSnapshot.mergeIntoAppData(data, snapshot);
      expect(
        merged.supplementLogs.where((l) => l.date == '2026-05-27'),
        isEmpty,
      );
    });

    test('merges supplement toggle on', () {
      final data = emptyAppData.copyWith(
        supplements: [
          const Supplement(
            id: 's1',
            name: 'Iron',
            enabled: true,
            slots: [SupplementSlot.evening],
          ),
        ],
      );

      const snapshot = WidgetSnapshot(
        updatedAt: 't',
        needsAppSync: true,
        dateKey: '2026-05-27',
        supplementDoses: [
          WidgetSnapshotSupplementDose(
            supplementId: 's1',
            slot: 'evening',
            taken: true,
          ),
        ],
      );

      final merged = WidgetSnapshot.mergeIntoAppData(data, snapshot);
      expect(merged.supplementLogs, hasLength(1));
      expect(merged.supplementLogs.first.slot, SupplementSlot.evening);
    });
  });
}
