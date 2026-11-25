import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The seal shown after a verified person's name, in the theme's tint.
///
/// ```dart
/// Row(children: [Text(person.name), const Gap.xs(), const VerifiedBadge()])
/// ```
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({this.style, super.key});

  /// The style of the name the seal follows, which sets its size. Defaults
  /// to the name of a row: the theme's `large` style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PhosphorIcon(
      PhosphorIconsFill.sealCheck,
      size: theme.iconBeside(style ?? theme.textTheme.large),
      color: theme.colorScheme.tint,
      semanticLabel: 'Verified',
    );
  }
}
