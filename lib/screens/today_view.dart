import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/health_models.dart';
import '../providers/health_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _PeriodCalendarCard(provider: provider),
        const SizedBox(height: 16),
        _PoopCard(provider: provider),
        const SizedBox(height: 16),
        _SupplementCard(provider: provider),
      ],
    );
  }
}

class _PeriodCalendarCard extends StatefulWidget {
  const _PeriodCalendarCard({required this.provider});

  final HealthProvider provider;

  @override
  State<_PeriodCalendarCard> createState() => _PeriodCalendarCardState();
}

class _PeriodCalendarCardState extends State<_PeriodCalendarCard> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  Future<void> _showDayActions(BuildContext context, String dateKey) async {
    final provider = widget.provider;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final pretty = formatDisplayDate(parseDateKey(dateKey));
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.rose100,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    pretty,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.rose800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded, color: AppColors.rose600),
                title: const Text(
                  'Set period start on this day',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  provider.setPeriodStartOnDate(dateKey);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.stop_rounded, color: AppColors.rose600),
                title: const Text(
                  'Set period end on this day',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  provider.setPeriodEndOnDate(dateKey);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_rounded, color: AppColors.rose600),
                title: const Text(
                  'Clear period on this day',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  provider.clearPeriodOnDate(dateKey);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final events = provider.data.periodEvents;
    final onPeriod = provider.isOnPeriod();
    final cycleDay = provider.getCycleDay();
    final predictedStart = provider.predictedNextPeriodStartKey();

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month).weekday;
    final leadingEmpty = firstWeekday == DateTime.sunday ? 6 : firstWeekday - 1;

    return AppCard(
      borderColor: AppColors.rose400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionLabel(
                  title: 'Period',
                  subtitle: 'Track your cycle',
                ),
              ),
              if (cycleDay != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.rose100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    onPeriod ? 'Day $cycleDay' : 'Day $cycleDay of cycle',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.rose700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tap a day to set start, end, or clear.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.muted.withValues(alpha: 0.88),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.rose600,
              ),
              Expanded(
                child: Text(
                  formatMonthYear(_focusedMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.rose800,
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.rose600,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              _CalendarWeekLabel('Mo'),
              _CalendarWeekLabel('Tu'),
              _CalendarWeekLabel('We'),
              _CalendarWeekLabel('Th'),
              _CalendarWeekLabel('Fr'),
              _CalendarWeekLabel('Sa'),
              _CalendarWeekLabel('Su'),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              // Wider than tall: ~2/3 of square height at same column width.
              childAspectRatio: 1.5,
            ),
            itemCount: leadingEmpty + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmpty) return const SizedBox.shrink();

              final day = index - leadingEmpty + 1;
              final date = DateTime(year, month, day);
              final key = formatDateKey(date);
              final isToday = key == todayKey();
              final onBleeding = events.any((e) => isDateInPeriod(key, e));
              final isStart = events.any((e) => e.startDate == key);
              final isEnd = events.any((e) => e.endDate == key);
              final isPredicted =
                  predictedStart != null && key == predictedStart && !onBleeding;

              Color? bg;
              Color? borderColor;
              if (onBleeding) {
                bg = AppColors.rose300.withValues(alpha: 0.32);
                borderColor = AppColors.rose300.withValues(alpha: 0.55);
              } else if (isToday) {
                bg = AppColors.lavender300.withValues(alpha: 0.18);
                borderColor = AppColors.rose400.withValues(alpha: 0.45);
              } else if (isPredicted) {
                bg = AppColors.rose400.withValues(alpha: 0.10);
                borderColor = AppColors.rose300.withValues(alpha: 0.4);
              } else {
                bg = Colors.transparent;
                borderColor = null;
              }

              String? label;
              if (isStart || isEnd) {
                label = isStart && isEnd ? '●' : (isStart ? 'S' : 'E');
              } else if (isPredicted) {
                label = 'P';
              } else {
                label = null;
              }

              return GestureDetector(
                onTap: () => _showDayActions(context, key),
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: 1.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                          color: onBleeding || isToday || isPredicted
                              ? AppColors.rose800
                              : AppColors.foreground,
                        ),
                      ),
                      if (label != null)
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isPredicted && !isStart && !isEnd
                                ? AppColors.rose400
                                    .withValues(alpha: 0.95)
                                : AppColors.rose700,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _CalendarLegendDot(
                color: AppColors.rose300.withValues(alpha: 0.32),
                label: 'Period',
              ),
              _CalendarLegendDot(
                color: AppColors.lavender300.withValues(alpha: 0.18),
                border: AppColors.rose400.withValues(alpha: 0.45),
                label: 'Current day',
              ),
              _CalendarLegendDot(
                color: AppColors.rose400.withValues(alpha: 0.10),
                border: AppColors.rose300.withValues(alpha: 0.4),
                label: 'Predicted start',
              ),
              const Text(
                'S / E / P = start · end · predicted',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarWeekLabel extends StatelessWidget {
  const _CalendarWeekLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _CalendarLegendDot extends StatelessWidget {
  const _CalendarLegendDot({
    required this.color,
    required this.label,
    this.border,
  });

  final Color color;
  final String label;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border != null
                ? Border.all(color: border!, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _PoopCard extends StatelessWidget {
  const _PoopCard({required this.provider});

  final HealthProvider provider;

  @override
  Widget build(BuildContext context) {
    final logs = provider.getTodayPoopLogs();

    return AppCard(
      borderColor: const Color(0xFFFDE68A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            title: 'Bowel log',
            subtitle: 'Bristol scale (1–7)',
            color: Color(0xFFD97706),
          ),
          const SizedBox(height: 6),
          Text(
            '1 = firmer · 7 = softer — tap to log',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          BristolScaleBar(onTypeSelected: provider.addPoopLog),
          if (logs.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Today\'s logs',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            ...logs.map((log) {
              final shape = poopShapeOptionFor(log.shape);
              final parts = log.time.split(':');
              final time = DateTime(
                2000,
                1,
                1,
                int.parse(parts[0]),
                int.parse(parts[1]),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.rose100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${shape.typeNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rose700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Type ${shape.typeNumber} · ${shape.label} · ${formatTime(time)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.rose400,
                      onPressed: () => provider.removePoopLog(log.id),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _SupplementCard extends StatelessWidget {
  const _SupplementCard({required this.provider});

  final HealthProvider provider;

  @override
  Widget build(BuildContext context) {
    final supplements = provider.enabledSupplements;

    return AppCard(
      borderColor: AppColors.lavender300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            title: 'Supplements',
            subtitle: 'Check off today\'s doses',
            color: AppColors.lavender500,
          ),
          const SizedBox(height: 12),
          if (supplements.isEmpty)
            Text(
              'Add supplements in Settings to track them here.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted.withValues(alpha: 0.85),
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: provider.reorderEnabledSupplements,
              children: [
                for (int index = 0; index < supplements.length; index++)
                  _SupplementListItem(
                    key: ValueKey(supplements[index].id),
                    provider: provider,
                    supplement: supplements[index],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SupplementListItem extends StatelessWidget {
  const _SupplementListItem({
    super.key,
    required this.provider,
    required this.supplement,
  });

  final HealthProvider provider;
  final Supplement supplement;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final slot in supplement.slots)
          _SupplementDoseRow(
            provider: provider,
            supplement: supplement,
            slot: slot,
          ),
      ],
    );
  }
}

class _SupplementDoseRow extends StatelessWidget {
  const _SupplementDoseRow({
    required this.provider,
    required this.supplement,
    required this.slot,
  });

  final HealthProvider provider;
  final Supplement supplement;
  final SupplementSlot slot;

  @override
  Widget build(BuildContext context) {
    final taken = provider.isSupplementTaken(supplement.id, slot);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: taken ? AppColors.rose100 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => provider.toggleSupplement(supplement.id, slot),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: taken ? AppColors.rose400 : AppColors.rose100,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  taken ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: taken ? AppColors.rose600 : AppColors.rose300,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplement.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rose800,
                        ),
                      ),
                      Text(
                        '${slotLabels[slot]}${supplement.dose != null ? ' · ${supplement.dose}' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
