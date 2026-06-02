import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_controller.dart';

const Color kAccentGreen = Color(0xFF82CD27);
const Color kSurfaceDark = Color(0xFF111820);
const Color kSurfaceDeep = Color(0xFF0D1319);
const Color kSurfaceInk = Color(0xFF091116);
const Color kTextPrimary = Color(0xFFE8EDF3);
const Color kTextMuted = Color(0xFF5A6A7A);
const Color kBorder = Color.fromRGBO(255, 255, 255, 0.07);
const double kBreakpointTablet = 600.0;   // >= 600px = tablet
const double kBreakpointDesktop = 960.0;  // >= 960px = desktop

TextStyle _syne({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Color color = kTextPrimary,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.syne(
    textStyle: TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    ),
  );
}

TextStyle _orbitron({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w700,
  Color color = kTextPrimary,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.orbitron(
    textStyle: TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    ),
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kAccentGreen,
      brightness: Brightness.dark,
      surface: kSurfaceDark,
      primary: kAccentGreen,
    ),
    scaffoldBackgroundColor: const Color(0xFF090D12),
    textTheme: GoogleFonts.syneTextTheme(base.textTheme).copyWith(
      headlineLarge: _orbitron(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
      headlineMedium: _orbitron(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
      headlineSmall: _orbitron(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
      titleLarge: _orbitron(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.45,
      ),
      titleMedium: _syne(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.25,
      ),
      titleSmall: _syne(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.18,
      ),
      bodyLarge: _syne(fontSize: 15, color: kTextPrimary, height: 1.45),
      bodyMedium: _syne(fontSize: 13, color: kTextPrimary, height: 1.42),
      bodySmall: _syne(fontSize: 11, color: kTextMuted, height: 1.42),
      labelLarge: _orbitron(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0B1016),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      hintStyle: _syne(
        fontSize: 12.5,
        color: kTextMuted.withValues(alpha: 0.7),
      ),
      labelStyle: _syne(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: kTextMuted,
        letterSpacing: 0.5,
      ),
      floatingLabelStyle: _syne(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: kAccentGreen,
        letterSpacing: 0.5,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kAccentGreen, width: 1.2),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return kAccentGreen;
        }
        return Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(Colors.black),
      side: const BorderSide(color: kBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    dividerTheme: const DividerThemeData(color: kBorder, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF121A23),
      contentTextStyle: _syne(fontSize: 13, color: kTextPrimary),
      actionTextColor: kAccentGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
    iconTheme: const IconThemeData(color: kTextPrimary),
    cardTheme: CardThemeData(
      color: kSurfaceDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder),
      ),
    ),
  );
}

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = SkindecideScope.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image(image: controller.backgroundImageProvider, fit: BoxFit.cover),
        Container(color: const Color(0xFB090D12)),
        Positioned(
          left: -80,
          top: -20,
          child: _GlowOrb(
            size: 300,
            colors: [kAccentGreen.withValues(alpha: 0.12), Colors.transparent],
          ),
        ),
        Positioned(
          right: -100,
          bottom: 40,
          child: _GlowOrb(
            size: 350,
            colors: [
              const Color(0xFF8A5BD8).withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.backgroundColor = const Color(0xD9111820),
    this.borderColor = kBorder,
    this.radius = 14,
    this.shadow = const [],
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double radius;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class GlassTag extends StatelessWidget {
  const GlassTag({
    super.key,
    required this.label,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    this.fontSize = 11,
  });

  final String label;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF141A20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor ?? kBorder),
      ),
      child: Text(
        label,
        style: _orbitron(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: textColor ?? kTextMuted,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class AppBrand extends StatelessWidget {
  const AppBrand({super.key, this.size = 22, this.footer = false});

  final double size;
  final bool footer;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'SKIN',
        style: _orbitron(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: kAccentGreen,
          letterSpacing: 1.2,
        ),
        children: [
          TextSpan(
            text: 'DECIDE',
            style: _orbitron(
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: footer ? kTextMuted : kTextPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassActionButton extends StatelessWidget {
  const GlassActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double? width;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFF141A20),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kBorder),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: kTextMuted),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: _syne(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: kTextMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NeonPrimaryButton extends StatelessWidget {
  const NeonPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(
            label.toUpperCase(),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: _orbitron(
              fontSize: 12.8,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.black),
              const SizedBox(width: 10),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: _orbitron(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );

    return Container(
      width: expand ? double.infinity : null,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: kAccentGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccentGreen,
          foregroundColor: Colors.black,
          disabledBackgroundColor: kAccentGreen.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.black54,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class NeonSecondaryButton extends StatelessWidget {
  const NeonSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.height = 44,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final double height;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final background = filled ? const Color(0xFF0B1016) : Colors.transparent;
    final child = icon == null
        ? Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: _syne(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextMuted,
              letterSpacing: 0.2,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: kTextMuted),
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: _syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: kTextMuted,
          side: const BorderSide(color: kBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

String formatFlow(double value) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(4)}';
}

String formatWeight(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}
