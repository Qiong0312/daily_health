import 'package:flutter/material.dart';

class AppColors {
  static const rose800 = Color(0xFF9D174D);
  static const rose700 = Color(0xFFBE185D);
  static const rose600 = Color(0xFFDB2777);
  static const rose500 = Color(0xFFEC4899);
  static const rose400 = Color(0xFFF472B6);
  static const rose300 = Color(0xFFF9A8D4);
  static const rose100 = Color(0xFFFCE7F3);
  static const lavender500 = Color(0xFFA78BFA);
  static const lavender300 = Color(0xFFC4B5FD);
  static const cream = Color(0xFFFFF7ED);
  static const peach = Color(0xFFFED7AA);
  static const foreground = Color(0xFF831843);
  static const muted = Color(0xFFBE185D);
}

class AppTheme {
  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.rose500,
        brightness: Brightness.light,
        primary: AppColors.rose600,
        secondary: AppColors.lavender500,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.foreground,
        displayColor: AppColors.foreground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.rose800,
      ),
    );
  }

  static BoxDecoration shellGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFDF2F8),
        Color(0xFFFCE7F3),
        Color(0xFFF5F3FF),
        Color(0xFFFFF7ED),
      ],
    ),
  );

  static BoxDecoration loadingGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFBCFE8),
        Color(0xFFF5D0FE),
        Color(0xFFFFE4E6),
      ],
    ),
  );

  static BoxDecoration ctaGradient = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
    ),
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.borderColor = AppColors.rose300,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose500.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CtaButton extends StatelessWidget {
  const CtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.expand = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: enabled
              ? AppTheme.ctaGradient
              : BoxDecoration(
                  color: AppColors.rose100,
                  borderRadius: BorderRadius.circular(14),
                ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: enabled ? Colors.white : AppColors.rose400, size: 18),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: enabled ? Colors.white : AppColors.rose400,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.title,
    this.subtitle,
    this.color = AppColors.rose600,
  });

  final String title;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.rose800,
            ),
          ),
      ],
    );
  }
}
