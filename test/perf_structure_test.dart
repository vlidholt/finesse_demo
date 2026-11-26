import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart' show TypingIndicator;
import 'package:una_demo/app_state.dart';
import 'package:una_demo/demo_shell.dart';

import 'perf_support.dart';
import 'support.dart';

// What each Demo screen costs to draw, counted and held to upper bounds:
// see `perf_support.dart` for what is counted and why.
//
// The bounds are what the screens need today with a little room. A failure
// here means a change made every frame of a screen more expensive — a
// backdrop filter per list item, a page that repaints as it scrolls, an
// animation that rebuilds while nothing happens. If that is what the change
// is for, raise the bound in the same commit and say why.
//
// Run with `--dart-define=PERF_OUT=/some/dir` to also write the table as
// JSON (`structure.json`), for comparing before and after a change.

const _out = String.fromEnvironment('PERF_OUT');

const _phone = Size(390, 844);
const _desktop = Size(1440, 1000);

Future<void> _precacheImages(WidgetTester tester) async {
  final keys = [
    for (final file in Directory('assets/images').listSync())
      if (!file.path.endsWith('.md')) file.path,
  ];
  final element = tester.element(find.byType(DemoShell));
  await tester.runAsync(() async {
    for (final key in keys) {
      await precacheImage(AssetImage(key), element);
    }
  });
}

BuildContext _shell(WidgetTester tester) =>
    tester.element(find.byType(DemoShell));

Future<void> _goTo(WidgetTester tester, DemoDestination destination) async {
  demoDestinationProvider.of(_shell(tester)).value = destination;
  await settle(tester, frames: 16);
}

/// The backdrop filters each screen may have: the bars, and the glass that
/// floats over a photograph or over scrolling content.
int _backdropBound(DemoDestination destination, {required bool phone}) =>
    switch (destination) {
      // The cover's buttons, over the photograph.
      DemoDestination.profile => phone ? 4 : 2,
      // The composer, over the thread.
      DemoDestination.messages => 2,
      // On a phone the app bar and the bottom bar; on a desktop the bar.
      _ => phone ? 2 : 1,
    };

void main() {
  setUpAll(setUpFonts);

  final table = <String, Map<String, Object>>{};

  tearDownAll(() {
    printTable('structure', table);
    if (_out.isNotEmpty) {
      File('$_out/structure.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(const JsonEncoder.withIndent(' ').convert(table));
    }
  });

  for (final (form, size) in [('phone', _phone), ('desktop', _desktop)]) {
    final phone = form == 'phone';

    for (final destination in DemoDestination.values) {
      testWidgets('${destination.name} on a $form', (tester) async {
        final name = '${destination.name}/$form';
        await pumpApp(tester, size: size);
        await _precacheImages(tester);
        await _goTo(tester, destination);
        await settle(tester, frames: 30);

        // Shadows as they are painted in a release build.
        debugDisableShadows = false;
        addTearDown(() => debugDisableShadows = true);
        await tester.pump();
        final structure = measureStructure(tester);
        // The phone's profile is under a large app bar that collapses as
        // the page scrolls. The bar follows the scroll in paint, so the
        // frames of its collapse paint its own few boxes — and nothing
        // else: its buttons are layers and so is the page. That stretch
        // is measured by itself, and the page from where the bar has
        // settled, like every other page.
        FrameWork? collapse;
        if (phone && destination == DemoDestination.profile) {
          collapse = await measureScroll(tester);
          pageScrollPosition(tester)!.jumpTo(400);
          await tester.pump();
        }
        final scroll = await measureScroll(tester);
        if (collapse != null) {
          pageScrollPosition(tester)!.jumpTo(0);
          await tester.pump();
          expect(collapse.buildsPerFrame, 0, reason: collapse.topBuilds());
          // An average over a fixed distance of scroll: with the cover at
          // 220, every frame of it is still collapsing (at 132 the bar
          // had settled for the last few), so the budget is higher than
          // the work per collapsing frame, which did not change.
          expect(
            collapse.paintsPerFrame,
            lessThan(44),
            reason: collapse.topPaints(),
          );
          // Nothing of the page is among them.
          expect(
            collapse.paintsByType.keys.where(
              (type) => type == 'RenderParagraph',
            ),
            hasLength(lessThanOrEqualTo(1)),
          );
        }
        final idle = await measureWork(tester, (pump) async {
          for (var i = 0; i < 30; i++) {
            await pump();
          }
        });
        final scheduled = tester.binding.hasScheduledFrame;

        table[name] = {
          ...structure.toJson(),
          'scrollBuilds': scroll.buildsPerFrame.round(),
          'scrollPaints': scroll.paintsPerFrame.round(),
          'scrollUs': scroll.microsecondsPerFrame.round(),
          'idleBuilds': idle.builds,
          'idlePaints': idle.paints,
          'idleFrame': scheduled,
        };
        final details =
            'backdrops ${structure.backdropOwners}\n'
            'saveLayers ${structure.saveLayerSources}\n'
            'scroll builds ${scroll.topBuilds()}\n'
            'scroll paints ${scroll.topPaints()}\n'
            'idle builds ${idle.topBuilds()}\n'
            'idle paints ${idle.topPaints()}';

        // Backdrop filters: the bars and the few surfaces that float. Not
        // one per card — a card lies on the flat page — and none that
        // comes back for every item of a list.
        expect(
          structure.backdropFilters,
          lessThanOrEqualTo(_backdropBound(destination, phone: phone)),
          reason: '$name\n$details',
        );
        expect(
          structure.backdropOwners.keys.where((o) => o.startsWith('Card')),
          isEmpty,
          reason: '$name: a card blurs its backdrop\n$details',
        );
        // The filters on screen cover the bars, not the page.
        expect(structure.backdropArea, lessThan(.2), reason: name);

        // Offscreen layers: none, but for one paragraph that fades out at
        // its end on the desktop home.
        expect(
          structure.saveLayers,
          lessThanOrEqualTo(1),
          reason: '$name\n$details',
        );

        // Shadows are clipped by the bounding rectangle and by corner
        // slivers; `test/src/utils/shadow_test.dart` in the package holds
        // the size of those clips. Here: that there are not suddenly many
        // more of them.
        expect(structure.blurredDraws, lessThan(200), reason: name);

        // A scroll moves a layer. It builds nothing, and it paints nothing
        // but the thread of a conversation, whose list is lazy. A collapsed
        // `SliverAppBar` is a layer of its own and is not painted again.
        expect(scroll.buildsPerFrame, lessThan(6), reason: '$name\n$details');
        expect(
          scroll.paintsPerFrame,
          lessThan(destination == DemoDestination.messages ? 80 : 4),
          reason: '$name\n$details',
        );
        if (collapse != null) {
          expect(
            scroll.paintsByType.keys,
            isNot(contains('RenderImage')),
            reason: 'the page is painted with the bar: $details',
          );
        }

        // At rest nothing is built, and nothing is painted or even
        // scheduled — except the three dots of somebody typing, which are
        // one render object in a layer of their own.
        expect(idle.builds, 0, reason: '$name\n$details');
        final typing =
            destination == DemoDestination.messages &&
            find.byType(TypingIndicator).evaluate().isNotEmpty;
        expect(
          idle.paints,
          typing ? lessThanOrEqualTo(idle.frames) : 0,
          reason: '$name\n$details',
        );
        expect(scheduled, typing, reason: '$name\n$details');

        // Font loads requested by the default face never finish here.
        await tester.pump(const Duration(seconds: 6));
      });
    }

    testWidgets('switching destination on a $form', (tester) async {
      await pumpApp(tester, size: size);
      await _precacheImages(tester);
      // Both built once, so the switch is a switch and not a first build.
      await _goTo(tester, DemoDestination.jobs);
      await _goTo(tester, DemoDestination.home);
      await settle(tester, frames: 30);

      final work = await measureWork(tester, (pump) async {
        demoDestinationProvider.of(_shell(tester)).value = DemoDestination.jobs;
        for (var i = 0; i < 40; i++) {
          await pump();
        }
      });
      table['switch/$form'] = work.toJson();
      // The shell and the bars rebuild once; the pages only slide.
      expect(
        work.builds,
        lessThan(phone ? 1100 : 1400),
        reason: work.topBuilds(12),
      );
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('switching between light and dark on a $form', (tester) async {
      await pumpApp(tester, size: size);
      await _precacheImages(tester);
      await settle(tester, frames: 30);

      late FrameWork first;
      final rest = await measureWork(tester, (pump) async {
        first = await measureWork(tester, (pump) async {
          toggleThemeMode(_shell(tester));
          await pump();
        });
        // `measureWork` restores the hooks of the outer call.
        for (var i = 0; i < 15; i++) {
          await pump();
        }
      });
      table['theme/$form'] = {
        'firstFrameBuilds': first.builds,
        'laterBuilds': rest.builds,
        'laterPaints': rest.paints,
        'usPerFrame': rest.microsecondsPerFrame.round(),
      };
      // The new theme is one build of the app, and what follows is a
      // picture fading (`CrossFadeTheme`) — not a dozen builds of the app
      // with themes in between, and no fills fading on their own.
      expect(first.builds, greaterThan(500));
      expect(
        rest.builds,
        lessThan(first.builds * .15),
        reason: rest.topBuilds(12),
      );
      expect(
        rest.paints,
        lessThan(first.paints * .5),
        reason: rest.topPaints(12),
      );
      await tester.pump(const Duration(seconds: 6));
    });
  }
}
