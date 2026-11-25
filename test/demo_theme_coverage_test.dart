import 'dart:io';

import 'package:finesse_demo/screens/home_screen.dart';
import 'package:finesse_demo/screens/jobs_screen.dart';
import 'package:finesse_demo/screens/network_screen.dart';
import 'package:finesse_demo/screens/notifications_screen.dart';
import 'package:finesse_demo/screens/profile_screen.dart';
import 'package:finesse_demo/screens/search_screen.dart';
import 'package:finesse_demo/screens/settings_screen.dart';
import 'package:finesse_demo/widgets/person_avatar.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_support.dart';
import 'support.dart';

// Demo follows the theme.
//
// Every screen is built twice, under the default theme and under one whose
// type scale, gap scale, radius and avatar and glyph sizes are all
// deliberately different, and every size a Demo source file hands to a
// widget is compared between the two. A size that is the same in both was
// not read from the theme: it is a literal, and a preset or a custom theme
// cannot move it. The few that are meant to be — a photograph's height, the
// logo, a rule — are listed in [_exempt] with the reason; anything else
// fails the test, with the file and line that set it.
//
// Widgets are attributed to source files through the creation locations
// `flutter test` records (`--track-widget-creation`, on by default), so
// what a package component sizes for itself is not the screens' doing and
// is not looked at.

/// What is measured.
enum _Kind {
  /// The font size a `Text` renders at.
  font,

  /// A `Padding`'s, `Container`'s or `Card`'s insets.
  inset,

  /// The spacing of a row, a column or a wrap, and an off-scale `Gap`.
  gap,

  /// The size an `Icon` is drawn at.
  icon,

  /// The size of an `Avatar`.
  avatar,

  /// A corner radius.
  radius,

  /// A fixed height.
  height,
}

/// The literals Demo keeps, by source file and kind, with the reason.
///
/// Adding an entry is a decision that a size should *not* follow the theme.
const _exempt = <(String, _Kind), String>{
  // Pictures: a photograph is cropped to the height the layout was drawn
  // for. These are sizes of images, not of type or spacing.
  ('home_post_media.dart', _Kind.height): 'photograph and thumbnail heights',
  ('home_profile_card.dart', _Kind.height): 'the cover photograph',
  ('profile_about_cards.dart', _Kind.height): 'a featured item’s photograph',
  ('profile_header_card.dart', _Kind.height): 'the cover photograph',
  ('profile_header_card.dart', _Kind.avatar): 'the profile’s own portrait',
  ('profile_header_card.dart', _Kind.inset): 'where the portrait meets it',
  ('profile_mobile_header.dart', _Kind.height): 'the cover photograph',
  ('profile_mobile_header.dart', _Kind.avatar): 'the profile’s own portrait',
  ('profile_mobile_header.dart', _Kind.inset): 'where the portrait meets it',
  ('profile_tab_content.dart', _Kind.height): 'the media grid’s squares',

  // The story rail is a picture component: a card's proportions, its
  // portrait and the type of its label are fitted to the photograph.
  ('home_stories.dart', _Kind.font): 'story labels, fitted to the card',
  ('home_stories.dart', _Kind.height): 'story card proportions',
  ('home_stories.dart', _Kind.inset): 'story card proportions',
  ('home_stories.dart', _Kind.gap): 'story card proportions',
  ('home_stories.dart', _Kind.icon): 'story card proportions',
  ('home_stories.dart', _Kind.avatar): 'story card proportions',

  // The brand mark is drawn at its own sizes.
  ('demo_logo.dart', _Kind.font): 'the wordmark',
  ('demo_logo.dart', _Kind.gap): 'the wordmark',
  ('demo_logo.dart', _Kind.radius): 'the mark’s tile',
  ('demo_logo.dart', _Kind.height): 'the mark’s tile',

  // Drawn details: rings and rules, not gaps.
  ('person_avatar.dart', _Kind.inset): 'the story ring’s width',
  ('person_avatar.dart', _Kind.font): 'initials, fitted to the portrait',
  ('home_post_comments.dart', _Kind.radius): 'the thread rule’s round ends',
  ('notifications_list.dart', _Kind.gap): 'the hairline between rows',

  // Menus: the rule between two groups of a menu sits on the menu's own
  // 4-point rhythm, as the package's menus do.
  ('user_menu.dart', _Kind.inset): 'a menu divider’s margin',
  ('jobs_board.dart', _Kind.inset): 'a menu divider’s margin',
  ('search_bar.dart', _Kind.inset): 'a menu divider’s margin',
};

/// One measured size and where it was set.
typedef _Sample = ({String file, int line, _Kind kind, double value});

/// The Demo source file and line that created [element]'s widget, or
/// null when something else did.
(String, int)? _demoLocation(Element element) {
  final json = element.toDiagnosticsNode().toJsonMap(
    InspectorSerializationDelegate(service: WidgetInspectorService.instance),
  );
  final location = json['creationLocation'];
  if (location is! Map) return null;
  final file = location['file'] as String? ?? '';
  // This package's own sources: tests run from the package root.
  if (!file.contains('${Directory.current.path}/lib/')) return null;
  final name = file.split('/').last;
  // The Messages screen is covered by its own tests.
  if (name.startsWith('messages_')) return null;
  return (name, location['line'] as int? ?? 0);
}

Iterable<double> _insets(EdgeInsetsGeometry? padding) {
  if (padding == null) return const [];
  final resolved = padding.resolve(TextDirection.ltr);
  return [resolved.left, resolved.top, resolved.right, resolved.bottom];
}

Iterable<double> _radii(BorderRadiusGeometry? radius) {
  if (radius == null) return const [];
  final resolved = radius.resolve(TextDirection.ltr);
  return [
    for (final corner in [
      resolved.topLeft,
      resolved.topRight,
      resolved.bottomLeft,
      resolved.bottomRight,
    ])
      // A pill is not a step of the radius scale.
      if (corner.x < 500) corner.x,
  ];
}

/// Every size the Demo sources set in what is on screen.
List<_Sample> _measure(WidgetTester tester) {
  final samples = <_Sample>[];

  void visit(Element element) {
    final widget = element.widget;
    final Map<_Kind, Iterable<double?>> found = switch (widget) {
      Text() => {
        _Kind.font: [
          tester
              .widgetList<RichText>(
                find.descendant(
                  of: find.byElementPredicate((e) => e == element),
                  matching: find.byType(RichText),
                ),
              )
              .firstOrNull
              ?.text
              .style
              ?.fontSize,
        ],
      },
      // A size the screen states. One an icon inherits is its button's,
      // chip's or tile's, and that component's own business.
      Icon() => {
        _Kind.icon: [widget.size],
      },
      Button() => {
        _Kind.icon: [widget.style?.iconSize],
        _Kind.height: [widget.style?.height],
        _Kind.inset: _insets(widget.style?.padding),
        _Kind.gap: [widget.style?.gap],
      },
      IconButton() => {
        _Kind.icon: [widget.style?.iconSize],
        _Kind.height: [widget.style?.height, widget.style?.width],
        _Kind.inset: _insets(widget.style?.padding),
      },
      Chip() => {
        _Kind.height: [widget.height],
        _Kind.inset: _insets(widget.padding),
      },
      Padding() => {_Kind.inset: _insets(widget.padding)},
      Container() => {
        _Kind.inset: [..._insets(widget.padding), ..._insets(widget.margin)],
        _Kind.height: [
          if (widget.constraints case final constraints?)
            if (constraints.hasTightHeight) constraints.maxHeight,
        ],
        _Kind.radius: [
          if (widget.decoration case final BoxDecoration decoration)
            ..._radii(decoration.borderRadius),
        ],
      },
      Card(:final style) => {
        _Kind.inset: _insets(style?.padding),
        _Kind.radius: _radii(style?.borderRadius),
        _Kind.gap: [style?.gap, style?.sectionGap],
      },
      SizedBox() => {
        _Kind.height: [widget.height],
      },
      Image() => {
        _Kind.height: [widget.height],
      },
      Gap() => {
        // A named gap is the theme's by construction.
        if (widget.size == null)
          _Kind.gap: [(element.renderObject! as RenderBox).size.longestSide],
      },
      Flex() => {
        _Kind.gap: [widget.spacing],
      },
      Wrap() => {
        _Kind.gap: [widget.spacing, widget.runSpacing],
      },
      // Where the screen asks for a portrait, not where `PersonAvatar`
      // builds it.
      PersonAvatar() => {
        _Kind.avatar: [widget.size],
      },
      Avatar() => {
        if (element.findAncestorWidgetOfExactType<PersonAvatar>() == null)
          _Kind.avatar: [widget.size?.shortestSide],
      },
      ClipRRect() => {_Kind.radius: _radii(widget.borderRadius)},
      DecoratedBox() => {
        _Kind.radius: [
          if (widget.decoration case final BoxDecoration decoration)
            ..._radii(decoration.borderRadius),
        ],
      },
      _ => const {},
    };
    if (found.isNotEmpty) {
      final location = _demoLocation(element);
      if (location != null) {
        for (final MapEntry(key: kind, value: values) in found.entries) {
          for (final value in values) {
            if (value == null || value == 0 || !value.isFinite) continue;
            samples.add((
              file: location.$1,
              line: location.$2,
              kind: kind,
              // Layout arithmetic leaves noise in the last places.
              value: (value * 100).roundToDouble() / 100,
            ));
          }
        }
      }
    }
    element.visitChildren(visit);
  }

  tester.binding.rootElement!.visitChildren(visit);
  return samples;
}

/// The default style with every metric a screen reads moved: type up by
/// three and a half points (so that no theme size is a whole number, and a
/// literal one cannot pass for it), gaps and card and page insets a
/// quarter larger, larger avatars and glyphs. [_theme] also widens the
/// spacing step by a tenth, which moves every metric the theme derives from
/// it — a button's padding, a bubble's, a timeline's gap — so that between
/// the two no step lands on another step's old value.
const _spread = 1.25;

StyleTokens _exaggerated(StyleTokens style) {
  TextRole up(TextRole role) => role.copyWith(fontSize: role.fontSize + 3.5);
  return style.copyWith(
    display: up(style.display!),
    headline: up(style.headline!),
    title: up(style.title),
    subtitle: up(style.subtitle!),
    body: up(style.body),
    label: up(style.label),
    small: up(style.small!),
    caption: up(style.caption),
    overline: up(style.overline),
    field: up(style.field),
    gapXs: style.gapXs * _spread,
    gapSm: style.gapSm * _spread,
    gapMd: style.gapMd * _spread,
    gapLg: style.gapLg * _spread,
    gapXl: style.gapXl * _spread,
    cardPadding: style.cardPadding * _spread,
    pagePaddingX: style.pagePaddingX * _spread,
    pagePaddingY: style.pagePaddingY * _spread,
    avatarSize: style.avatarSize * 1.3,
    buttonIconSize: style.buttonIconSize + 3,
    iconButtonIconSize: style.iconButtonIconSize + 3,
    buttonHeightLg: style.buttonHeightLg + 6,
  );
}

ThemeData _theme({required bool exaggerated}) {
  const base = StyleTokens.finesse;
  return ThemeData(
    textTheme: TextTheme(family: demoTestFont),
    style: exaggerated
        ? _exaggerated(base).copyWith(mobile: _exaggerated(base.mobile!))
        : base,
    radius: exaggerated
        ? BorderRadius.all(Radius.circular(base.radius * 2))
        : null,
    spacing: exaggerated ? const Spacing(step: 4.4) : null,
  );
}

Future<List<_Sample>> _pumpAndMeasure(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  required bool exaggerated,
  required bool appBar,
}) async {
  await pumpDemoScreen(
    tester,
    screen,
    size: size,
    appBar: appBar,
    theme: _theme(exaggerated: exaggerated),
  );
  // Everything on the page, not just the first screenful.
  if (find.byType(SingleChildScrollView).evaluate().isNotEmpty) {
    await scrollThrough(tester);
  }
  final samples = _measure(tester);
  // Empty the tree, so the next pump builds its states afresh.
  await tester.pumpWidget(const SizedBox.shrink());
  await dismissToasts(tester);
  return samples;
}

void main() {
  setUpAll(() async {
    await loadDemoTestFont();
    await setUpFonts();
  });

  final screens = <(String, Widget Function(), {bool appBar})>[
    ('Home', HomeScreen.new, appBar: true),
    ('Network', NetworkScreen.new, appBar: true),
    ('Jobs', JobsScreen.new, appBar: true),
    ('Notifications', NotificationsScreen.new, appBar: true),
    ('Profile', ProfileScreen.new, appBar: true),
    ('Search', () => const SearchScreen(initialQuery: 'design'), appBar: false),
    ('Settings', SettingsScreen.new, appBar: false),
  ];

  for (final (name, build, :appBar) in screens) {
    for (final size in [demoDesktop, demoPhone]) {
      final form = size == demoPhone ? 'phone' : 'desktop';
      testWidgets('$name on a $form takes its sizes from the theme', (
        tester,
      ) async {
        final plain = await _pumpAndMeasure(
          tester,
          build(),
          size: size,
          exaggerated: false,
          appBar: appBar,
        );
        expect(tester.takeException(), isNull, reason: 'default theme');

        final moved = await _pumpAndMeasure(
          tester,
          build(),
          size: size,
          exaggerated: true,
          appBar: appBar,
        );
        // Larger type and wider gaps still fit: nothing overflowed.
        expect(tester.takeException(), isNull, reason: 'exaggerated theme');

        // The comparison is not vacuous: the screen has text, spacing and
        // icons of its own to compare.
        int count(List<_Sample> samples, _Kind kind) =>
            samples.where((s) => s.kind == kind).length;
        expect(count(plain, _Kind.font), greaterThan(8));
        expect(
          count(plain, _Kind.gap) + count(plain, _Kind.inset),
          greaterThan(4),
        );

        // Every font size the screen sets is one of the theme's: the
        // exaggerated scale has no whole-number size, so one that is whole
        // was written into the screen.
        final wholeSizes = {
          for (final sample in moved)
            if (sample.kind == _Kind.font &&
                sample.value == sample.value.roundToDouble() &&
                !_exempt.containsKey((sample.file, sample.kind)))
              '${sample.file}:${sample.line} ${sample.value}',
        };
        expect(wholeSizes, isEmpty, reason: 'literal font sizes');

        // A size set on the same line in both themes did not come from the
        // theme.
        final literals = <String>{};
        for (final sample in moved) {
          if (_exempt.containsKey((sample.file, sample.kind))) continue;
          final unchanged = plain.any(
            (other) =>
                other.file == sample.file &&
                other.line == sample.line &&
                other.kind == sample.kind &&
                other.value == sample.value,
          );
          if (unchanged) {
            literals.add(
              '${sample.file}:${sample.line} ${sample.kind.name} '
              '${sample.value}',
            );
          }
        }
        expect(
          literals,
          isEmpty,
          reason:
              'sizes that are the same under both themes — read them from '
              'the theme, or list them in _exempt with the reason',
        );
      });
    }
  }
}
