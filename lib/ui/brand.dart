import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Black-figure pottery palette: warm black, terracotta, bone.
abstract final class MiloColors {
  static const ink = Color(0xFF121110);
  static const surface = Color(0xFF1A1816);
  static const surfaceHigh = Color(0xFF24201D);
  static const surfaceHighest = Color(0xFF2E2925);
  static const line = Color(0xFF3A332D);
  static const terracotta = Color(0xFFD2693C);
  static const terracottaDeep = Color(0xFF8E4325);
  static const bone = Color(0xFFEDE4D6);
  static const boneMuted = Color(0xFFA89D8F);
  static const ochre = Color(0xFFD9A441);
  static const olive = Color(0xFF8FA35A);
  static const fail = Color(0xFFE5484D);
}

const displayFont = 'BarlowCondensed';
const bodyFont = 'Barlow';

ThemeData buildMiloTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: MiloColors.terracotta,
    onPrimary: MiloColors.ink,
    primaryContainer: MiloColors.terracottaDeep,
    onPrimaryContainer: MiloColors.bone,
    secondary: MiloColors.ochre,
    onSecondary: MiloColors.ink,
    tertiary: MiloColors.ochre,
    onTertiary: MiloColors.ink,
    error: MiloColors.fail,
    onError: MiloColors.ink,
    surface: MiloColors.ink,
    onSurface: MiloColors.bone,
    onSurfaceVariant: MiloColors.boneMuted,
    surfaceContainerLowest: MiloColors.ink,
    surfaceContainerLow: MiloColors.surface,
    surfaceContainer: MiloColors.surface,
    surfaceContainerHigh: MiloColors.surfaceHigh,
    surfaceContainerHighest: MiloColors.surfaceHighest,
    outline: MiloColors.line,
    outlineVariant: MiloColors.line,
  );

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: bodyFont,
    scaffoldBackgroundColor: MiloColors.ink,
  );
  TextStyle? display(TextStyle? s, {FontWeight w = FontWeight.w700}) =>
      s?.copyWith(fontFamily: displayFont, fontWeight: w);
  final t = base.textTheme;
  final text = t.copyWith(
    displayLarge: display(t.displayLarge, w: FontWeight.w800),
    displayMedium: display(t.displayMedium, w: FontWeight.w800),
    displaySmall: display(t.displaySmall, w: FontWeight.w800),
    headlineLarge: display(t.headlineLarge, w: FontWeight.w800),
    headlineMedium: display(t.headlineMedium, w: FontWeight.w800),
    headlineSmall: display(t.headlineSmall),
    titleLarge: display(t.titleLarge),
    titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );

  final buttonText = const TextStyle(
    fontFamily: displayFont,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    letterSpacing: 1.6,
  );
  final buttonShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: MiloColors.ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge?.copyWith(
        fontSize: 22,
        letterSpacing: 1.2,
        color: MiloColors.bone,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: MiloColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(textStyle: buttonText, shape: buttonShape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: buttonText,
        shape: buttonShape,
        side: const BorderSide(color: MiloColors.line, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: MiloColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: MiloColors.terracotta.withValues(alpha: 0.18),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? MiloColors.terracotta
                : MiloColors.boneMuted,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: displayFont,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            fontSize: 13,
            color: s.contains(WidgetState.selected)
                ? MiloColors.bone
                : MiloColors.boneMuted,
          )),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: MiloColors.surfaceHigh,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: MiloColors.surfaceHighest,
      contentTextStyle: TextStyle(color: MiloColors.bone, fontFamily: bodyFont),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(color: MiloColors.line, space: 1),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MiloColors.line)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: MiloColors.terracotta,
        selectedForegroundColor: MiloColors.ink,
        side: const BorderSide(color: MiloColors.line),
        textStyle: const TextStyle(
            fontFamily: displayFont, fontWeight: FontWeight.w700, fontSize: 18),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

/// Small spaced-caps label, e.g. "NEXT WORKOUT".
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: displayFont,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 2.2,
          color: color ?? MiloColors.terracotta,
        ),
      );
}

/// The Milo calf-bearer mark in a disc.
class MiloBadge extends StatelessWidget {
  const MiloBadge({super.key, this.size = 40, this.ink = false});

  final double size;

  /// Terracotta figure on a dark disc, for quieter placements.
  final bool ink;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        ink ? 'assets/brand/milo_badge_ink.svg' : 'assets/brand/milo_badge.svg',
        width: size,
        height: size,
        semanticsLabel: 'MiloLifts',
      );
}

/// "MILOLIFTS" wordmark.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: displayFont,
      fontWeight: FontWeight.w800,
      fontSize: size,
      letterSpacing: size * 0.08,
      height: 1,
    );
    return Text.rich(TextSpan(children: [
      TextSpan(text: 'MILO', style: style.copyWith(color: MiloColors.bone)),
      TextSpan(
          text: 'LIFTS', style: style.copyWith(color: MiloColors.terracotta)),
    ]));
  }
}

/// A band of Greek key (meander) pattern.
class MeanderBand extends StatelessWidget {
  const MeanderBand({super.key, this.height = 14, this.color});

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _MeanderPainter(
              color ?? MiloColors.terracotta.withValues(alpha: 0.35)),
        ),
      );
}

class _MeanderPainter extends CustomPainter {
  _MeanderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Grid of 5 units high; stroke width equals the gaps, like pottery bands.
    final u = size.height / 5;
    double g(double n) => (n + 0.5) * u; // centre of grid cell n
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = u
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    final path = Path()..moveTo(0, g(4));
    for (double x = 0; x < size.width + 6 * u; x += 6 * u) {
      // Baseline, then a hook: up, across, down, back in.
      path
        ..lineTo(x + g(0), g(4))
        ..lineTo(x + g(0), g(0))
        ..lineTo(x + g(4), g(0))
        ..lineTo(x + g(4), g(2))
        ..lineTo(x + g(2), g(2))
        ..moveTo(x + g(0), g(4))
        ..lineTo(x + 6 * u, g(4));
    }
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MeanderPainter old) => old.color != color;
}

/// The Milo of Croton story, used as a recurring motif.
const miloStory = 'Milo of Croton lifted a newborn calf every day. '
    'As the calf grew into a bull, Milo grew strong enough to carry it. '
    'Small jumps, every session.';
