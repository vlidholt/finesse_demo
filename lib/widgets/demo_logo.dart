import 'package:flutter/widgets.dart';
import 'package:una/una.dart';

/// The Demo mark: a rounded primary tile with the two-wave glyph, and the
/// "demo" wordmark beside it.
///
/// The tile follows the form factor — 32 on a desktop, 30 on a phone — as
/// the designs' app bars do.
class DemoLogo extends StatelessWidget {
  const DemoLogo({this.onPressed, this.showWordmark = true, super.key});

  /// Called when the logo is tapped; the shell uses it to go home.
  final VoidCallback? onPressed;

  /// Whether "demo" is written beside the tile.
  final bool showWordmark;

  // Off the theme's scales on purpose: the mark is a brand asset, drawn at
  // the sizes the designs give it rather than at a control size.
  static const _wordmarkGap = 10.0;

  static double _tileSize(ThemeData theme) =>
      theme.formFactor == FormFactor.mobile ? 30 : 32;

  static TextStyle _wordmarkStyle(ThemeData theme) =>
      theme.textTheme.large.copyWith(
        fontSize: 19,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -.03 * 19,
        color: theme.colorScheme.foreground,
      );

  /// The width the logo takes in [context], with or without its wordmark.
  /// The shell uses it to drop the wordmark before the app bar overflows.
  static double widthOf(BuildContext context, {bool showWordmark = true}) {
    final theme = Theme.of(context);
    final tile = _tileSize(theme);
    if (!showWordmark) return tile;
    final painter = TextPainter(
      text: TextSpan(text: 'demo', style: _wordmarkStyle(theme)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return tile + _wordmarkGap + width.ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = _tileSize(theme);
    final glyph = theme.formFactor == FormFactor.mobile ? 18.0 : 19.0;

    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tile,
          height: tile,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: CustomPaint(
            size: Size.square(glyph),
            painter: _WavesPainter(theme.colorScheme.primaryForeground),
          ),
        ),
        if (showWordmark) ...[
          const Gap.raw(_wordmarkGap),
          Text(
            'demo',
            maxLines: 1,
            softWrap: false,
            style: _wordmarkStyle(theme),
          ),
        ],
      ],
    );

    if (onPressed == null) {
      return Semantics(
        label: 'Demo',
        child: ExcludeSemantics(child: logo),
      );
    }
    return Pressable(
      onPressed: onPressed,
      semanticLabel: 'Demo home',
      builder: (context, states) => FocusRing(
        visible: states.contains(WidgetState.focused),
        borderRadius: BorderRadius.circular(9),
        child: ExcludeSemantics(child: logo),
      ),
    );
  }
}

/// The glyph from the design's SVG: two strokes on a 24-unit grid,
/// `M5 8c4-4 10 4 14 0` and the same at y=16 and 45% opacity, 2.4 wide with
/// round caps.
class _WavesPainter extends CustomPainter {
  const _WavesPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    Path wave(double y) => Path()
      ..moveTo(5, y)
      ..relativeCubicTo(4, -4, 10, 4, 14, 0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas
      ..drawPath(wave(8), paint)
      ..drawPath(wave(16), paint..color = color.withValues(alpha: .45));
  }

  @override
  bool shouldRepaint(_WavesPainter oldDelegate) => oldDelegate.color != color;
}
