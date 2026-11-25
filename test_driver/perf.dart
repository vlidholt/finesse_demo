import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui';

import 'package:finesse_demo/demo_shell.dart';
import 'package:finesse_demo/main.dart' as app;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Entrypoint for measuring frame times of a web build from the browser:
///
/// ```sh
/// flutter build web --release -t test_driver/perf.dart
/// ```
///
/// It runs the app unchanged and puts a `finessePerf` object on `window`:
///
/// * `await finessePerf.scroll(pixelsPerSecond, seconds)` scrolls the page
///   on screen down and back up and returns the frame statistics as JSON;
/// * `finessePerf.start()` … `await finessePerf.stop()` brackets anything
///   else — a tap, a menu, typing;
/// * `finessePerf.goTo('jobs')` switches the Demo destination and
///   `finessePerf.toggleTheme()` the brightness.
///
/// The numbers are the engine's own frame timings (`FrameTiming`): the
/// time spent building, the time spent rasterising, and the interval
/// between frames. On the web the rasteriser's time ends when the frame's
/// commands have been handed to the GPU, not when the GPU has finished
/// them, so a GPU-bound frame shows up in the interval and not in `raster`.
Future<void> main() async {
  await app.main();
  SchedulerBinding.instance.addTimingsCallback((timings) {
    if (_recording) _timings.addAll(timings);
  });
  globalContext['finessePerf'] = JSObject()
    ..['start'] = _start.toJS
    ..['stop'] = (() => _stop().then((stats) => stats.toJS).toJS).toJS
    ..['scroll'] = ((JSNumber speed, JSNumber seconds) => _scroll(
      speed.toDartDouble,
      seconds.toDartDouble,
    ).then((stats) => stats.toJS).toJS).toJS
    ..['goTo'] = ((JSString name) => _goTo(name.toDart)).toJS
    ..['toggleTheme'] = _toggleTheme.toJS;
}

final _timings = <FrameTiming>[];
bool _recording = false;

void _start() {
  _timings.clear();
  _recording = true;
}

Future<String> _stop() async {
  // Timings are reported in batches, with the frame after the batch.
  for (var i = 0; i < 3; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    SchedulerBinding.instance.scheduleFrame();
  }
  await Future<void>.delayed(const Duration(milliseconds: 150));
  _recording = false;

  Map<String, Object> stats(List<double> values) {
    if (values.isEmpty) return const {};
    final sorted = [...values]..sort();
    double at(double q) => sorted[((sorted.length - 1) * q).round()];
    double round(double v) => (v * 100).round() / 100;
    return {
      'mean': round(values.reduce((a, b) => a + b) / values.length),
      'p50': round(at(.5)),
      'p95': round(at(.95)),
      'max': round(sorted.last),
    };
  }

  double ms(Duration duration) => duration.inMicroseconds / 1000;
  final intervals = <double>[
    for (var i = 1; i < _timings.length; i++)
      (_timings[i].timestampInMicroseconds(FramePhase.vsyncStart) -
              _timings[i - 1].timestampInMicroseconds(FramePhase.vsyncStart)) /
          1000,
  ];
  return jsonEncode({
    'frames': _timings.length,
    'build': stats([for (final t in _timings) ms(t.buildDuration)]),
    'raster': stats([for (final t in _timings) ms(t.rasterDuration)]),
    'total': stats([for (final t in _timings) ms(t.totalSpan)]),
    // A gap of more than 100 ms is the app idling between two animations,
    // not a slow frame; a slow frame that long shows in `total`.
    'interval': stats([...intervals.where((i) => i <= 100)]),
    'over16': intervals.where((i) => i > 17.5 && i <= 100).length,
    'over33': intervals.where((i) => i > 34 && i <= 100).length,
    'gaps': intervals.where((i) => i > 100).length,
    // A short recording in full: when each frame started, and how long it
    // took to build and to rasterise.
    if (_timings.length <= 60)
      'each': [
        for (final t in _timings)
          [
            ((t.timestampInMicroseconds(FramePhase.vsyncStart) -
                        _timings.first.timestampInMicroseconds(
                          FramePhase.vsyncStart,
                        )) /
                    1000)
                .round(),
            ms(t.buildDuration).round(),
            ms(t.rasterDuration).round(),
          ],
      ],
  });
}

Element? _find(bool Function(Element) test) {
  Element? found;
  void visit(Element element) {
    if (found != null) return;
    if (test(element)) {
      found = element;
      return;
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return found;
}

/// The largest vertical scrollable that is showing.
ScrollPosition? _pagePosition() {
  ScrollPosition? best;
  var bestArea = 0.0;
  void visit(Element element) {
    if (element case StatefulElement(:final ScrollableState state)) {
      final position = state.position;
      final box = element.renderObject;
      final route = ModalRoute.of(element);
      if (axisDirectionToAxis(state.axisDirection) == Axis.vertical &&
          position.hasContentDimensions &&
          position.maxScrollExtent > 0 &&
          box is RenderBox &&
          box.hasSize &&
          TickerMode.valuesOf(element).enabled &&
          (route == null || route.isCurrent)) {
        final area = box.size.width * box.size.height;
        if (area > bestArea) {
          bestArea = area;
          best = position;
        }
      }
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return best;
}

Future<String> _scroll(double speed, double seconds) async {
  final position = _pagePosition();
  if (position == null) return jsonEncode({'error': 'nothing to scroll'});
  final start = position.pixels;
  final end = (start + speed * seconds)
      .clamp(0, position.maxScrollExtent)
      .toDouble();
  final duration = Duration(
    milliseconds: ((end - start).abs() / speed * 1000).round().clamp(1, 60000),
  );
  _start();
  await position.animateTo(end, duration: duration, curve: Curves.linear);
  await position.animateTo(start, duration: duration, curve: Curves.linear);
  final stats = jsonDecode(await _stop()) as Map<String, dynamic>;
  return jsonEncode({'distance': (end - start).round(), ...stats});
}

void _goTo(String name) {
  final context = _find((element) => element.widget is DemoShell);
  if (context == null) return;
  demoDestinationProvider.of(context).value = DemoDestination.values.byName(
    name,
  );
}

void _toggleTheme() {
  final context = _find((element) => element.widget is DemoShell);
  if (context != null) app.toggleThemeMode(context);
}
