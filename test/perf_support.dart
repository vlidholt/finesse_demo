import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// What a frame costs the rasteriser cannot be timed in a widget test, but
// what it is *made of* can be counted: the backdrop filters, the offscreen
// layers, the blurred shadows, the oversized images, and how much of the
// tree is rebuilt and repainted when something moves. `perf_structure_test`
// holds those counts to upper bounds.

/// What the frame on screen is made of.
class FrameStructure {
  FrameStructure._();

  /// Backdrop filters in the painted tree: each one reads back and blurs
  /// what is behind it on every frame it is part of.
  int backdropFilters = 0;

  /// The backdrop filters whose box overlaps the window.
  int backdropFiltersOnScreen = 0;

  /// The area the on-screen backdrop filters cover, in window areas.
  double backdropArea = 0;

  /// Offscreen layers: opacity, shader mask, colour filter and image
  /// filter layers, save-layer clips, and `Canvas.saveLayer` calls inside
  /// pictures.
  int saveLayers = 0;

  /// The save layers that are composited layers (not inside a picture).
  int saveLayerLayers = 0;

  /// Clips by a path or a rounded rectangle, on the canvas or as a layer.
  int shapeClips = 0;

  /// Draw calls with a blur mask: outer shadows.
  int blurredDraws = 0;

  /// The largest blur sigma among [blurredDraws].
  double maxBlurSigma = 0;

  /// Composited layers in the tree, pictures included.
  int layers = 0;

  /// Picture layers.
  int pictures = 0;

  /// Repaint boundaries in the painted tree.
  int repaintBoundaries = 0;

  /// Render objects in the painted tree.
  int renderObjects = 0;

  /// Paragraphs in the painted tree.
  int paragraphs = 0;

  /// Images drawn.
  int images = 0;

  /// Images decoded at more than twice the pixels they are shown at, as
  /// `decoded -> shown` descriptions.
  final oversizedImages = <String>[];

  /// The canvas calls of one full paint, by method.
  final canvasCalls = <String, int>{};

  /// Which widget each backdrop filter belongs to, with `*` when it is on
  /// screen: the nearest ancestor that is not one of the framework's or
  /// `Backdrop` itself.
  final backdropOwners = <String, int>{};

  /// Where each `Canvas.saveLayer` inside a picture comes from.
  final saveLayerSources = <String, int>{};

  /// The table row for this structure.
  Map<String, Object> toJson() => {
    'backdrop': backdropFilters,
    'backdropOnScreen': backdropFiltersOnScreen,
    'backdropArea': double.parse(backdropArea.toStringAsFixed(2)),
    'saveLayers': saveLayers,
    'saveLayerLayers': saveLayerLayers,
    'shapeClips': shapeClips,
    'blurredDraws': blurredDraws,
    'maxBlurSigma': maxBlurSigma,
    'layers': layers,
    'pictures': pictures,
    'repaintBoundaries': repaintBoundaries,
    'renderObjects': renderObjects,
    'paragraphs': paragraphs,
    'images': images,
    'oversizedImages': oversizedImages.length,
  };
}

/// Counts what the current frame is made of: the layer tree as composited,
/// the render tree as painted (offstage branches left out), and the canvas
/// calls of one full paint of it.
FrameStructure measureStructure(WidgetTester tester) {
  final result = FrameStructure._();
  final view = tester.binding.renderViews.single;
  final window = Offset.zero & view.size;

  void visitLayer(Layer layer) {
    result.layers++;
    if (layer is PictureLayer) result.pictures++;
    final savesLayer = switch (layer) {
      OpacityLayer(:final alpha) => alpha != 0 && alpha != 255,
      ShaderMaskLayer() || ColorFilterLayer() || ImageFilterLayer() => true,
      ClipRectLayer(:final clipBehavior) ||
      ClipRRectLayer(:final clipBehavior) ||
      ClipPathLayer(
        :final clipBehavior,
      ) => clipBehavior == Clip.antiAliasWithSaveLayer,
      _ => false,
    };
    if (savesLayer) {
      result
        ..saveLayers += 1
        ..saveLayerLayers += 1;
    }
    if (layer is ClipRRectLayer || layer is ClipPathLayer) result.shapeClips++;
    if (layer is ContainerLayer) {
      for (var child = layer.firstChild; child != null;) {
        visitLayer(child);
        child = child.nextSibling;
      }
    }
  }

  visitLayer(view.debugLayer!);

  void visitRenderObject(RenderObject object) {
    result.renderObjects++;
    if (object.isRepaintBoundary) result.repaintBoundaries++;
    if (object is RenderParagraph) result.paragraphs++;
    if (object is RenderBackdropFilter && object.enabled) {
      result.backdropFilters++;
      final rect = MatrixUtils.transformRect(
        object.getTransformTo(null),
        Offset.zero & object.size,
      ).intersect(window);
      final onScreen = rect.width > 0 && rect.height > 0;
      if (onScreen) {
        result
          ..backdropFiltersOnScreen += 1
          ..backdropArea +=
              rect.width * rect.height / (window.width * window.height);
      }
      final owner = _ownerOf(object);
      result.backdropOwners.update(
        onScreen ? '$owner*' : owner,
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }
    if (object is RenderImage) {
      final image = object.image;
      if (image != null && object.hasSize && !object.size.isEmpty) {
        result.images++;
        final ratio = tester.view.devicePixelRatio;
        // The decoded pixels against the pixels of the box at a phone's 3x.
        final shown = object.size.width * object.size.height * 9;
        final decoded = image.width * image.height * ratio * ratio;
        if (decoded > shown * 2) {
          result.oversizedImages.add(
            '${image.width}x${image.height} -> '
            '${object.size.width.round()}x${object.size.height.round()}'
            ' (${object.debugImageLabel ?? '?'})',
          );
        }
      }
    }
    _visitPainted(object, visitRenderObject);
  }

  visitRenderObject(view);

  final canvas = _CountingCanvas(result);
  final context = TestRecordingPaintingContext(canvas);
  final child = view.child;
  if (child != null) {
    final previous = debugOnProfilePaint;
    debugOnProfilePaint = null;
    child.paint(context, Offset.zero);
    debugOnProfilePaint = previous;
  }
  return result;
}

/// The widget [object] was made for: the nearest ancestor of its element
/// that is not plumbing.
String _ownerOf(RenderObject object) {
  const plumbing = {
    'BackdropFilter',
    'Backdrop',
    'BackdropSurface',
    'ClipRRect',
    'ClipPath',
    'DecoratedBox',
    'Stack',
    'Positioned',
    'IgnorePointer',
    'BackdropFade',
    'AnimatedBuilder',
    'FadeTransition',
    'CustomPaint',
    'RepaintBoundary',
    'Padding',
    'Align',
    'KeyedSubtree',
  };
  final creator = object.debugCreator;
  if (creator is! DebugCreator) return '?';
  String? found;
  creator.element.visitAncestorElements((ancestor) {
    final type = '${ancestor.widget.runtimeType}';
    if (plumbing.contains(type) || type.startsWith('_')) return true;
    found = type;
    return false;
  });
  return found ?? '?';
}

/// Visits the children of [object] that are painted: an `IndexedStack`
/// shows one child, an overlay skips the routes under an opaque one, a
/// viewport lays out only the slivers in its cache, and an `Offstage` or a
/// fully transparent `Opacity` paints nothing.
void _visitPainted(RenderObject object, RenderObjectVisitor visitor) {
  final culls =
      object is RenderIndexedStack ||
      object is RenderOffstage ||
      object is RenderOpacity ||
      object is RenderAnimatedOpacity ||
      object is RenderViewportBase ||
      object is RenderSliver ||
      '${object.runtimeType}' == '_RenderTheater';
  if (culls) {
    object.visitChildrenForSemantics(visitor);
  } else {
    object.visitChildren(visitor);
  }
}

class _CountingCanvas extends TestRecordingCanvas {
  _CountingCanvas(this._result);

  final FrameStructure _result;

  void _count(String name) =>
      _result.canvasCalls.update(name, (n) => n + 1, ifAbsent: () => 1);

  void _paint(Paint paint) {
    final filter = paint.maskFilter;
    if (filter == null) return;
    _result.blurredDraws++;
    // `MaskFilter.blur(BlurStyle.normal, 12.0)`
    final match = RegExp(r', ([0-9.]+)\)').firstMatch('$filter');
    final sigma = double.tryParse(match?.group(1) ?? '') ?? 0;
    if (sigma > _result.maxBlurSigma) _result.maxBlurSigma = sigma;
  }

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    _result.saveLayers++;
    _count('saveLayer');
    final frames = StackTrace.current.toString().split('\n');
    // The first frame outside the canvas and the painting context.
    final source = frames
        .skip(1)
        .map((line) => line.replaceFirst(RegExp(r'^#\d+\s+'), ''))
        .firstWhere(
          (line) =>
              !line.contains('recording_canvas.dart') &&
              !line.contains('perf_support.dart') &&
              !line.contains('PaintingContext.'),
          orElse: () => '?',
        )
        .split(' (')
        .first;
    _result.saveLayerSources.update(source, (n) => n + 1, ifAbsent: () => 1);
    super.saveLayer(bounds, paint);
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    _count('drawRect');
    _paint(paint);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    _count('drawRRect');
    _paint(paint);
  }

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {
    _count('drawDRRect');
    _paint(paint);
  }

  @override
  void drawPath(Path path, Paint paint) {
    _count('drawPath');
    _paint(paint);
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    _count('drawCircle');
    _paint(paint);
  }

  @override
  void drawOval(Rect rect, Paint paint) {
    _count('drawOval');
    _paint(paint);
  }

  @override
  void noSuchMethod(Invocation invocation) {
    final name = '${invocation.memberName}'
        .replaceFirst('Symbol("', '')
        .replaceFirst('")', '');
    _count(name);
    if (name == 'clipPath' || name == 'clipRRect') _result.shapeClips++;
    if (name == 'drawShadow') _result.blurredDraws++;
  }
}

/// What the framework did over some frames.
class FrameWork {
  FrameWork._();

  /// Frames pumped.
  int frames = 0;

  /// Widgets built or rebuilt.
  int builds = 0;

  /// Render objects painted (a repaint boundary that is only composited
  /// again does not count).
  int paints = 0;

  /// The builds, by widget type.
  final buildsByType = <String, int>{};

  /// The paints, by render object type.
  final paintsByType = <String, int>{};

  /// Wall time spent in `pump`, in microseconds. A debug-mode VM number:
  /// good for comparing one run with another, not for a frame budget.
  int microseconds = 0;

  /// Builds per frame.
  double get buildsPerFrame => frames == 0 ? 0 : builds / frames;

  /// Paints per frame.
  double get paintsPerFrame => frames == 0 ? 0 : paints / frames;

  /// Microseconds per frame.
  double get microsecondsPerFrame => frames == 0 ? 0 : microseconds / frames;

  /// The [count] types built most often.
  String topBuilds([int count = 8]) => _top(buildsByType, count);

  /// The [count] types painted most often.
  String topPaints([int count = 8]) => _top(paintsByType, count);

  static String _top(Map<String, int> counts, int count) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(count).map((e) => '${e.key}:${e.value}').join(' ');
  }

  /// The table row for this work.
  Map<String, Object> toJson() => {
    'frames': frames,
    'buildsPerFrame': double.parse(buildsPerFrame.toStringAsFixed(1)),
    'paintsPerFrame': double.parse(paintsPerFrame.toStringAsFixed(1)),
    'usPerFrame': microsecondsPerFrame.round(),
  };
}

/// Counts the builds and paints of the frames [body] pumps.
///
/// [body] gets a `pump` to call once per frame; frames pumped any other way
/// are counted as work but not as frames.
Future<FrameWork> measureWork(
  WidgetTester tester,
  Future<void> Function(Future<void> Function([Duration]) pump) body,
) async {
  final work = FrameWork._();
  final previousBuild = debugOnRebuildDirtyWidget;
  final previousPaint = debugOnProfilePaint;
  debugOnRebuildDirtyWidget = (element, builtOnce) {
    work.builds++;
    final type = '${element.widget.runtimeType}';
    work.buildsByType.update(type, (n) => n + 1, ifAbsent: () => 1);
  };
  debugOnProfilePaint = (object) {
    // A clean repaint boundary is composited, not painted.
    if (object.isRepaintBoundary && !object.debugNeedsPaint) return;
    work.paints++;
    final type = '${object.runtimeType}';
    work.paintsByType.update(type, (n) => n + 1, ifAbsent: () => 1);
  };
  try {
    await body(([duration = const Duration(milliseconds: 16)]) async {
      final watch = Stopwatch()..start();
      await tester.pump(duration);
      work
        ..microseconds += watch.elapsedMicroseconds
        ..frames += 1;
    });
  } finally {
    debugOnRebuildDirtyWidget = previousBuild;
    debugOnProfilePaint = previousPaint;
  }
  return work;
}

/// The scroll position of the largest vertical scrollable on screen: a
/// screen's own page, not a list inside one of its cards.
ScrollPosition? pageScrollPosition(WidgetTester tester) {
  ScrollPosition? best;
  var bestArea = 0.0;
  for (final element in find.byType(Scrollable).evaluate()) {
    final state = (element as StatefulElement).state as ScrollableState;
    if (axisDirectionToAxis(state.axisDirection) != Axis.vertical) continue;
    final position = state.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      continue;
    }
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize) continue;
    final area = box.size.width * box.size.height;
    if (area > bestArea) {
      bestArea = area;
      best = position;
    }
  }
  return best;
}

/// Scrolls the page [step] logical pixels a frame for [frames] frames and
/// counts the work.
Future<FrameWork> measureScroll(
  WidgetTester tester, {
  int frames = 20,
  double step = 9,
}) async {
  final position = pageScrollPosition(tester);
  if (position == null) return FrameWork._();
  final start = position.pixels;
  final work = await measureWork(tester, (pump) async {
    for (var i = 1; i <= frames; i++) {
      position.jumpTo(
        (start + i * step).clamp(0, position.maxScrollExtent).toDouble(),
      );
      await pump();
    }
  });
  position.jumpTo(start);
  await tester.pump();
  return work;
}

/// Whether [image] has pixels; for tests that precache.
bool hasPixels(ui.Image? image) => image != null && image.width > 0;

/// Prints [rows] as a table, one line a row.
void printTable(String title, Map<String, Map<String, Object>> rows) {
  debugPrint('== $title');
  rows.forEach((name, row) {
    debugPrint(
      '${name.padRight(28)} '
      '${row.entries.map((e) => '${e.key}=${e.value}').join(' ')}',
    );
  });
}
