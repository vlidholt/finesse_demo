import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/demo_pieces.dart';

/// Pulling the feed down asks for new posts.
///
/// A finger pulls, and so does a trackpad; a mouse wheel cannot, which is
/// what "Refresh feed" in the feed's "Sort by" menu is for ([show]). The
/// circle comes out from under the shell's app bar, and spins until the
/// model has its answer.
class HomeFeedRefresh extends StatelessWidget {
  const HomeFeedRefresh({required this.child, super.key});

  /// The scrolling page.
  final Widget child;

  /// Refreshes the feed [context] is in as a pull would, with the circle
  /// showing: for a menu entry or a button.
  static void show(BuildContext context) {
    final indicator = context.findAncestorStateOfType<RefreshIndicatorState>();
    unawaited(indicator?.show() ?? _refresh(context));
  }

  /// Asks the feed for new posts and, when there are none, says so: a
  /// refresh that changes nothing on screen would look like one that
  /// failed.
  static Future<void> _refresh(BuildContext context) async {
    final arrived = await context.demo.feed.refresh();
    if (arrived > 0 || !context.mounted) return;
    showDemoToast(
      context,
      'You’re all caught up',
      description: 'No new posts since you last looked.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: child,
    );
  }
}
