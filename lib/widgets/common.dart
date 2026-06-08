import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../theme/app_theme.dart';

/// Blossom emoji asset (transparent PNG; home-screen icon keeps its pink backdrop).
class BloomMark extends StatelessWidget {
  const BloomMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/bloom_mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      // Avoid any flat color behind the blossom in the header / loading UI.
      gaplessPlayback: true,
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onTabChanged;

  static const tabs = [
    (tab: AppTab.today, label: 'Today', icon: Icons.spa_rounded),
    (tab: AppTab.summary, label: 'Summary', icon: Icons.insights_rounded),
    (tab: AppTab.settings, label: 'Settings', icon: Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.rose100, width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: tabs.map((t) {
            final active = activeTab == t.tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(t.tab),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active ? AppColors.rose400 : AppColors.rose100,
                          width: 2,
                        ),
                        gradient: active
                            ? const LinearGradient(
                                colors: [Color(0xFFFCE7F3), Color(0xFFF5D0FE)],
                              )
                            : null,
                        color: active ? null : AppColors.cream.withValues(alpha: 0.5),
                      ),
                      child: Icon(
                        t.icon,
                        size: 20,
                        color: active ? AppColors.rose700 : AppColors.rose400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: active ? AppColors.rose800 : AppColors.rose400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class EmojiButton extends StatelessWidget {
  const EmojiButton({
    super.key,
    required this.emoji,
    required this.selected,
    required this.onTap,
    this.size = 36,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected ? AppColors.rose100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.rose500 : AppColors.rose100,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.rose400.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}

/// Horizontal Bristol stool scale — seven tappable segments (1 = firmest … 7 = softest).
class BristolScaleBar extends StatelessWidget {
  const BristolScaleBar({
    super.key,
    required this.onTypeSelected,
  });

  final ValueChanged<PoopShape> onTypeSelected;

  static Color _segmentFill(int typeNumber) {
    final t = (typeNumber - 1) / 6.0;
    return Color.lerp(
          const Color(0xFFFFF7ED),
          const Color(0xFFFCE7F3),
          t,
        ) ??
        AppColors.rose100;
  }

  static BorderSide _segmentBorder(int typeNumber) {
    final t = (typeNumber - 1) / 6.0;
    final alpha = 0.35 + 0.45 * t;
    return BorderSide(color: AppColors.rose400.withValues(alpha: alpha), width: 1.5);
  }

  @override
  Widget build(BuildContext context) {
    const gap = 4.0;
    final options = poopShapeOptions;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: gap),
          Expanded(
            child: Tooltip(
              message: 'Type ${options[i].typeNumber}: ${options[i].label}',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: _segmentFill(options[i].typeNumber),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => onTypeSelected(options[i].value),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.fromBorderSide(
                            _segmentBorder(options[i].typeNumber),
                          ),
                        ),
                        child: Text(
                          '${options[i].typeNumber}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.rose800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 34,
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Text(
                          options[i].label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class OptionGroup extends StatelessWidget {
  const OptionGroup({
    super.key,
    required this.label,
    required this.children,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: children),
      ],
    );
  }
}
