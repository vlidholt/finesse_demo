import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/search_data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/screens/search_screen.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/demo_previews.dart';
import 'package:una_demo/widgets/search_results.dart';

/// What choosing a search result does, from [context]: a person or a
/// company opens its preview, a job goes to Jobs, a post to the feed — or
/// to the profile, for one of the user's own.
///
/// [before] runs first, for the host to close itself and record the query.
SearchCallbacks searchCallbacksFor(
  BuildContext context, {
  required VoidCallback before,
}) {
  return SearchCallbacks(
    onPerson: (person) {
      before();
      showPersonPreview(context, person);
    },
    onCompany: (company) {
      before();
      showCompanyPreview(context, company);
    },
    onJob: (job) {
      before();
      context.leaveTo(DemoDestination.jobs);
    },
    onPost: (post) {
      before();
      context.leaveTo(
        post.own ? DemoDestination.profile : DemoDestination.home,
      );
    },
  );
}

/// The desktop app bar's search: a [SearchField], with a panel under it
/// while the focus is in the field or in the panel.
///
/// Before anything is typed the panel lists the recent and the trending
/// searches. As the user types it shows the best few people, jobs, posts
/// and companies, live. Return — or "See all results" — opens the full
/// [SearchScreen] on the same query.
///
/// ## The panel follows the focus
///
/// The panel is a `Popover` that does not take the focus
/// (`requestFocus: false`): the caret stays in the field while results
/// come and go under it. It has no barrier, so nothing but the focus says
/// whether it is in use. It opens when the field gains the focus (and when
/// the field is tapped or typed in with the focus already there), and
/// closes when the focus leaves both the field and the panel — by Tab, by a
/// click elsewhere, by a result opening a dialog — as well as on Escape and
/// on a tap outside. The popover makes field and panel one focus traversal
/// group, so Tab and the down arrow go from the field into the results and
/// Escape closes the panel from either; the field is in the popover's
/// tap-region group too, so a click on the panel's own surface neither
/// closes it nor takes the focus from the field.
///
/// ## The shortcut
///
/// ⌘K on an Apple platform, Ctrl+K elsewhere ([SearchField.isSearchShortcut])
/// puts the cursor in the field from anywhere in Demo. It is a
/// `HardwareKeyboard` handler, which hears a key wherever the focus is —
/// including inside a dialog — so it checks that nothing covers the bar
/// (`isInTopRoute`) before it acts.
class DemoSearchBar extends StatefulWidget {
  const DemoSearchBar({super.key});

  /// The panel's width: wider than the field, as a results list wants.
  static const panelWidth = 420.0;

  /// The width the designs give the field in the desktop app bar.
  static const fieldWidth = 280.0;

  /// What Demo's search fields ask for.
  static const placeholder = 'Search people, posts, jobs';

  /// The space between the panel's edge and its rows.
  static double _inset(ThemeData theme) => theme.gap(GapSize.xs);

  @override
  State<DemoSearchBar> createState() => _DemoSearchBarState();
}

class _DemoSearchBarState extends State<DemoSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// Above the field and the panel: has the focus while either does.
  final _scopeNode = FocusNode(
    debugLabel: 'DemoSearchBar',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final _group = Object();

  /// Whether the panel is showing.
  final _panel = PopoverController();

  static const _anchor = AnchorAuto(
    offset: Offset(0, 8),
    targetAnchor: AlignmentDirectional.bottomStart,
    followerAnchor: AlignmentDirectional.bottomEnd,
  );

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onQueryChanged);
    // The arrow keys are bound while the panel is open.
    _panel.addListener(_onPanelChanged);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void _onPanelChanged() => setState(() {});

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _controller.dispose();
    _focusNode.dispose();
    _scopeNode.dispose();
    _panel.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) _show();
  }

  void _onQueryChanged() {
    // The panel shows the results of what is typed.
    setState(() {});
    // Typing after Escape brings the panel back; clearing the field on
    // the way to the results page does not.
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) _panel.open();
  }

  /// The search shortcut, wherever the focus is — as long as the bar is
  /// what the user is looking at.
  bool _onKey(KeyEvent event) {
    if (!SearchField.isSearchShortcut(event)) return false;
    // Not under a dialog, a sheet or a full-screen page: the focus belongs
    // to whatever covers the bar, and the panel would open behind it.
    if (!mounted || !isInTopRoute(context)) return false;
    if (_collapsed) {
      _openEmptyPage();
    } else {
      _focusNode.requestFocus();
      // The field may have the focus already, with the panel closed by a
      // tap outside.
      _show();
    }
    return true;
  }

  void _show() => _panel.open();

  void _close() => _panel.close();

  /// Escape: the panel goes and the field gives up the focus.
  void _dismiss() {
    FocusManager.instance.primaryFocus?.unfocus();
    _close();
  }

  /// Moves the focus one stop along the field and the panel's controls, in
  /// reading order, and stops at either end: the arrow keys never leave
  /// the panel, which Tab does.
  void _step(int by) {
    final current = FocusManager.instance.primaryFocus;
    if (current == null) return;
    final stops = ReadingOrderTraversalPolicy()
        .sortDescendants(_scopeNode.traversalDescendants, current)
        .toList();
    final next = stops.indexOf(current) + by;
    if (stops.contains(current) && next >= 0 && next < stops.length) {
      FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
        stops[next],
        alignmentPolicy: by > 0
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  /// Whether the bar had no room for the field at the last layout, and
  /// showed the magnifier instead.
  bool _collapsed = false;

  void _openEmptyPage() {
    context.pushFullScreen<void>((context) => const SearchScreen());
  }

  /// Closes the panel, drops the focus and remembers the query.
  void _leave() {
    context.demo.search.add(_controller.text);
    FocusManager.instance.primaryFocus?.unfocus();
    _close();
  }

  void _openPage([String? query]) {
    final text = (query ?? _controller.text).trim();
    if (text.isEmpty) return;
    _leave();
    context.demo.search.add(text);
    _controller.clear();
    context.pushFullScreen<void>(
      (context) => SearchScreen(initialQuery: text),
    );
  }

  void _pick(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _collapsed = constraints.maxWidth < _collapseBelow;
        if (!_collapsed) return _buildField(context, constraints.maxWidth);
        // No room for a field: the phone's magnifier, which opens the
        // search page, as long as there is room for that.
        if (constraints.maxWidth < _iconFrom) return const SizedBox.shrink();
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: IconButton.ghost(
            icon: const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass),
            semanticLabel: 'Search',
            onPressed: _openEmptyPage,
          ),
        );
      },
    );
  }

  /// The width under which the field gives way to the magnifier, so a
  /// narrow app bar keeps its logo and navigation rather than a sliver of
  /// a text field, and the one under which the magnifier goes too.
  static const _collapseBelow = 120.0;
  static const _iconFrom = 40.0;

  /// The width from which the field has room for the shortcut's key cap.
  static const _shortcutFrom = 200.0;

  Widget _buildField(BuildContext context, double width) {
    final theme = Theme.of(context);
    final field = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: DemoSearchBar.fieldWidth),
      child: SearchField(
        controller: _controller,
        focusNode: _focusNode,
        placeholder: const Text(DemoSearchBar.placeholder),
        // The panel is in the field's tap-region group, so a click
        // on it leaves the focus in the field.
        groupId: _group,
        // Open on a focus *gain* is not enough: after a tap outside
        // on a touch screen the field still has the focus.
        onTap: _show,
        onSubmitted: _openPage,
        // Escape is the panel's: it closes it, query and all.
        clearOnEscape: false,
        // The hint gives way first, and to the clear button once there
        // is something to clear.
        trailing: width >= _shortcutFrom && _controller.text.isEmpty
            // The design's key cap is outlined, not filled: a hairline
            // in the strong border colour.
            ? Kbd(
                SearchField.shortcutLabel,
                backgroundColor: const Color(0x00000000),
                border: UnaBorder.all(
                  color: theme.colorScheme.borderStrong,
                  width: 1,
                  borderRadius: theme.radii.sm,
                ),
              )
            : null,
      ),
    );
    final open = _panel.isOpen;
    // Has the focus while the field or anything in the panel does: the
    // overlay is a descendant of the popover as far as the focus tree
    // goes, so the panel's controls are the stops after the field.
    return Focus(
      focusNode: _scopeNode,
      onFocusChange: (focused) {
        if (!focused) _close();
      },
      child: CallbackShortcuts(
        // Bound only while the panel is open: closed, the arrows are the
        // field's own.
        bindings: open
            ? {
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    _step(1),
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    _step(-1),
              }
            : const {},
        child: Popover(
          controller: _panel,
          // The caret stays in the field.
          requestFocus: false,
          groupId: _group,
          anchor: _anchor,
          padding: EdgeInsets.all(DemoSearchBar._inset(theme)),
          // Escape closes the panel from a result or from the field, and
          // gives up the focus with it; a text field swallows the key, so
          // each of the two has its own listener right around it. Closed,
          // the key is left alone for whatever encloses the bar.
          builder: (context) => DismissShortcut(
            isActive: () => _panel.isOpen,
            onDismiss: _dismiss,
            child: _Panel(
              query: _controller.text,
              onPick: _pick,
              onSeeAll: _openPage,
              callbacks: searchCallbacksFor(this.context, before: _leave),
            ),
          ),
          child: DismissShortcut(
            isActive: () => _panel.isOpen,
            onDismiss: _dismiss,
            child: field,
          ),
        ),
      ),
    );
  }
}

/// What is on the surface under the field: suggestions, live results or
/// "no results".
class _Panel extends StatelessWidget {
  const _Panel({
    required this.query,
    required this.onPick,
    required this.onSeeAll,
    required this.callbacks,
  });

  final String query;
  final ValueChanged<String> onPick;
  final VoidCallback onSeeAll;
  final SearchCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.demo;
    final results = SearchData.search(query);
    final typed = query.trim().isNotEmpty;
    // Leave room for the app bar above and a margin below.
    final maxHeight = (MediaQuery.sizeOf(context).height - 120).clamp(
      200.0,
      560.0,
    );

    final Widget content;
    if (!typed) {
      content = SearchSuggestions(
        history: session.search,
        onPick: onPick,
        compact: true,
      );
    } else if (results.isEmpty) {
      content = SearchNoResults(query: query, onPick: onPick, compact: true);
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: session.network,
            builder: (context, _) => SearchResultsView(
              query: query,
              results: results,
              callbacks: callbacks,
              network: session.network,
              compact: true,
            ),
          ),
          const Divider(margin: EdgeInsets.symmetric(vertical: 4)),
          Button.ghost(
            style: ButtonTheme(
              width: double.infinity,
              gap: theme.gap(GapSize.xs),
              textStyle: theme.textTheme.small,
              foregroundColor: theme.colorScheme.tint,
            ),
            trailing: const PhosphorIcon(PhosphorIconsRegular.arrowRight),
            onPressed: onSeeAll,
            child: Flexible(
              child: Text(
                results.total == 1
                    ? 'See the result'
                    : 'See all ${results.total} results',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      container: true,
      label: 'Search suggestions',
      // The popover is the surface; this is what is on it.
      child: SizedBox(
        // The panel's width is the surface's, padding and all.
        width: DemoSearchBar.panelWidth - DemoSearchBar._inset(theme) * 2,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(child: content),
        ),
      ),
    );
  }
}
