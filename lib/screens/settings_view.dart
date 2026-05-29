import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/health_models.dart';
import '../providers/health_provider.dart';
import '../copy/checklist_copy.dart';
import '../theme/app_theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel(
                title: 'Cycle',
                subtitle: 'Personalize tracking',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Average cycle length',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  _CycleStepper(
                    value: provider.data.averageCycleLength,
                    onChanged: provider.setAverageCycleLength,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          borderColor: AppColors.lavender300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: SectionLabel(
                      title: ChecklistCopy.settingsTitle,
                      subtitle: ChecklistCopy.settingsSubtitle,
                      color: AppColors.lavender500,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.rose600,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (provider.data.supplements.isEmpty)
                const Text(
                  ChecklistCopy.emptySettings,
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                )
              else
                ...provider.data.supplements.map(
                  (s) => _SupplementTile(supplement: s),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          borderColor: AppColors.rose100,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Text('🌷', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bloom v1 — your gentle daily health companion. All data stays on this device.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _SupplementDialog(
        onSave: (name, dose, slots) {
          context.read<HealthProvider>().addSupplement(name, dose: dose, slots: slots);
        },
      ),
    );
  }
}

class _CycleStepper extends StatelessWidget {
  const _CycleStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.rose100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value > 21 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
            color: AppColors.rose700,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '$value d',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.rose800,
            ),
          ),
          IconButton(
            onPressed: value < 45 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
            color: AppColors.rose700,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SupplementTile extends StatelessWidget {
  const _SupplementTile({required this.supplement});

  final Supplement supplement;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HealthProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: supplement.enabled ? Colors.white : AppColors.rose100.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.rose100, width: 2),
      ),
      child: Row(
        children: [
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
                  [
                    if (supplement.dose != null) supplement.dose,
                    supplement.slots.map((s) => slotLabels[s]).join(', '),
                  ].whereType<String>().join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: supplement.enabled,
            activeTrackColor: AppColors.rose400,
            onChanged: (v) => provider.updateSupplement(supplement.copyWith(enabled: v)),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.rose500,
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => _SupplementDialog(
                  initial: supplement,
                  onSave: (name, dose, slots) {
                    provider.updateSupplement(
                      supplement.copyWith(name: name, dose: dose, slots: slots),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.rose400,
            onPressed: () => provider.removeSupplement(supplement.id),
          ),
        ],
      ),
    );
  }
}

class _SupplementDialog extends StatefulWidget {
  const _SupplementDialog({this.initial, required this.onSave});

  final Supplement? initial;
  final void Function(String name, String? dose, List<SupplementSlot> slots) onSave;

  @override
  State<_SupplementDialog> createState() => _SupplementDialogState();
}

class _SupplementDialogState extends State<_SupplementDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _doseCtrl;
  late Set<SupplementSlot> _slots;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _doseCtrl = TextEditingController(text: widget.initial?.dose ?? '');
    _slots = widget.initial?.slots.toSet() ?? {SupplementSlot.morning};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.initial == null
            ? ChecklistCopy.addDialogTitle
            : ChecklistCopy.editDialogTitle,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.rose800,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: ChecklistCopy.nameLabel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.rose400, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _doseCtrl,
              decoration: InputDecoration(
                labelText: ChecklistCopy.notesLabel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.rose400, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              ChecklistCopy.timeOfDayLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SupplementSlot.values.map((slot) {
                final selected = _slots.contains(slot);
                return FilterChip(
                  label: Text(slotLabels[slot]!),
                  selected: selected,
                  selectedColor: AppColors.rose100,
                  checkmarkColor: AppColors.rose700,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _slots.add(slot);
                      } else if (_slots.length > 1) {
                        _slots.remove(slot);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.rose500,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            widget.onSave(name, _doseCtrl.text.trim(), _slots.toList());
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
