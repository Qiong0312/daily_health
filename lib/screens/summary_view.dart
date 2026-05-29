import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/health_models.dart';
import '../providers/health_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';

class SummaryView extends StatelessWidget {
  const SummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthProvider>();
    final adherence = provider.getSupplementAdherence();
    final events = provider.sortedPeriodEvents;
    final avgCycle = provider.data.averageCycleLength;
    final bowelLogsThisWeek = _bowelLogCountLastDays(provider, 7);

    final poopTrend = _poopTrend(provider, 14);
    final maxPoop = poopTrend.fold<int>(0, (max, e) => e.count > max ? e.count : max);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        AppCard(
          borderColor: AppColors.lavender300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel(
                title: 'This week',
                subtitle: 'Your health snapshot',
                color: AppColors.lavender500,
              ),
              const SizedBox(height: 16),
              _StatRow(
                icon: '💊',
                label: 'Supplement adherence',
                value: '${(adherence * 100).round()}%',
                progress: adherence,
              ),
              const SizedBox(height: 12),
              _StatRow(
                iconLabel: '7d',
                label: 'Bowel log entries (last 7 days)',
                value: '$bowelLogsThisWeek',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cycle insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.rose800,
                ),
              ),
              const SizedBox(height: 12),
              _StatRow(
                icon: '🌸',
                label: 'Expected cycle length',
                value: '$avgCycle days',
              ),
              const SizedBox(height: 12),
              _StatRow(
                icon: '📅',
                label: 'Logged cycles',
                value: '${events.length}',
              ),
              if (events.length >= 2) ...[
                const SizedBox(height: 12),
                _StatRow(
                  icon: '📊',
                  label: 'Avg period length',
                  value: '${_avgPeriodLength(events)} days',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          borderColor: AppColors.peach,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bowel trends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.rose800,
                ),
              ),
              const SizedBox(height: 12),
              ...poopTrend.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.option.typeNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.rose700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 72,
                        child: Text(
                          entry.option.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: maxPoop == 0 ? 0 : entry.count / maxPoop,
                            minHeight: 8,
                            backgroundColor: AppColors.rose100,
                            color: AppColors.rose400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${entry.count}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_bowelLogCountLastDays(provider, 14) == 0)
                const Text(
                  'Log from Today to see trends here.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Total Bristol-scale log entries (not days) in the rolling window.
  int _bowelLogCountLastDays(HealthProvider provider, int days) {
    final today = DateTime.now();
    var count = 0;
    for (var i = 0; i < days; i++) {
      final key = formatDateKey(today.subtract(Duration(days: i)));
      count += provider.getPoopLogsForDate(key).length;
    }
    return count;
  }

  int _avgPeriodLength(List<PeriodEvent> events) {
    final lengths = events
        .where((e) => e.endDate != null)
        .map((e) => daysBetween(e.startDate, e.endDate!) + 1)
        .toList();
    if (lengths.isEmpty) return 0;
    return (lengths.reduce((a, b) => a + b) / lengths.length).round();
  }

  List<({PoopShapeOption option, int count})> _poopTrend(
    HealthProvider provider,
    int days,
  ) {
    final counts = <PoopShape, int>{};
    final today = DateTime.now();
    for (var i = 0; i < days; i++) {
      final key = formatDateKey(today.subtract(Duration(days: i)));
      for (final log in provider.getPoopLogsForDate(key)) {
        counts[log.shape] = (counts[log.shape] ?? 0) + 1;
      }
    }

    return [
      for (final opt in poopShapeOptions)
        (option: opt, count: counts[opt.value] ?? 0),
    ];
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    this.icon,
    this.iconLabel,
    required this.label,
    required this.value,
    this.progress,
  }) : assert(icon != null || iconLabel != null);

  final String? icon;
  final String? iconLabel;
  final String label;
  final String value;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null)
              Text(icon!, style: const TextStyle(fontSize: 20))
            else
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.rose100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  iconLabel!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.rose700,
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.rose700,
              ),
            ),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.rose100,
              color: AppColors.rose500,
            ),
          ),
        ],
      ],
    );
  }
}
