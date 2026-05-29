import 'package:daily_health/models/health_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChecklistItemStats.computeBreakdown', () {
    const iron = Supplement(
      id: 'iron',
      name: 'Iron',
      slots: [SupplementSlot.morning],
    );
    const yoga = Supplement(
      id: 'yoga',
      name: 'Yoga',
      slots: [SupplementSlot.evening],
    );

    test('counts days where all slots for an item were completed', () {
      final logs = <SupplementLog>[
        for (var d = 21; d <= 27; d++)
          SupplementLog(
            date: '2026-05-$d',
            supplementId: 'iron',
            slot: SupplementSlot.morning,
          ),
        const SupplementLog(
          date: '2026-05-25',
          supplementId: 'yoga',
          slot: SupplementSlot.evening,
        ),
        const SupplementLog(
          date: '2026-05-26',
          supplementId: 'yoga',
          slot: SupplementSlot.evening,
        ),
        const SupplementLog(
          date: '2026-05-27',
          supplementId: 'yoga',
          slot: SupplementSlot.evening,
        ),
      ];

      final stats = ChecklistItemStats.computeBreakdown(
        supplements: [iron, yoga],
        logs: logs,
        days: 7,
        now: DateTime(2026, 5, 27),
      );

      expect(stats, hasLength(2));
      expect(stats.firstWhere((s) => s.name == 'Iron').daysCompleted, 7);
      expect(stats.firstWhere((s) => s.name == 'Yoga').daysCompleted, 3);
    });

    test('requires every slot on a day for multi-slot items', () {
      const multi = Supplement(
        id: 'multi',
        name: 'Multi',
        slots: [SupplementSlot.morning, SupplementSlot.evening],
      );
      const logs = [
        SupplementLog(
          date: '2026-05-27',
          supplementId: 'multi',
          slot: SupplementSlot.morning,
        ),
      ];

      final stats = ChecklistItemStats.computeBreakdown(
        supplements: [multi],
        logs: logs,
        days: 7,
        now: DateTime(2026, 5, 27),
      );

      expect(stats.single.daysCompleted, 0);
    });
  });
}
