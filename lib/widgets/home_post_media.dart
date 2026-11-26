import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/widgets/demo_actions.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/demo_pieces.dart';

/// What a post carries under its text: photographs, a link preview or an
/// event. Null-returning for a text-only post.
class HomePostMedia extends StatelessWidget {
  const HomePostMedia(this.post, {required this.compact, super.key});

  final FeedPost post;

  /// Whether this is the phone's card: one photograph at a time, shorter.
  final bool compact;

  /// Whether [post] has anything for this widget to show.
  static bool has(FeedPost post) =>
      post.images.isNotEmpty || post.link != null || post.event != null;

  /// The corner radius of every kind of media: a tile nested in a card.
  static BorderRadius radiusOf(ThemeData theme) => theme.radii.lg;

  @override
  Widget build(BuildContext context) {
    if (post.event case final event?) {
      return _EventMedia(event, compact: compact);
    }
    if (post.link case final link?) {
      return _LinkPreview(link, compact: compact);
    }
    if (post.images.isEmpty) return const SizedBox.shrink();
    return compact ? _ImagePager(post.images) : _ImageGrid(post.images);
  }
}

/// The desktop card's photographs, side by side under one rounded clip.
class _ImageGrid extends StatelessWidget {
  const _ImageGrid(this.images);

  final List<FeedImage> images;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: HomePostMedia.radiusOf(theme),
      child: Row(
        spacing: theme.gap(GapSize.xs),
        children: [
          for (final image in images)
            Expanded(
              child: Image.asset(
                image.asset,
                height: 280,
                fit: BoxFit.cover,
                semanticLabel: image.alt,
              ),
            ),
        ],
      ),
    );
  }
}

/// The phone card's photographs: one at a time in a `Carousel`, with a
/// "1 / 2" counter. A swipe turns the page, and so does a tap on the
/// photograph.
class _ImagePager extends StatefulWidget {
  const _ImagePager(this.images);

  final List<FeedImage> images;

  @override
  State<_ImagePager> createState() => _ImagePagerState();
}

class _ImagePagerState extends State<_ImagePager> {
  final _controller = CarouselController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = widget.images;
    final several = images.length > 1;
    return Stack(
      children: [
        Carousel(
          controller: _controller,
          height: 220,
          // Round and round: the tap that turns the last page shows the
          // first again.
          loop: several,
          showIndicator: several,
          borderRadius: HomePostMedia.radiusOf(theme),
          semanticLabel: 'Photos',
          onPageChanged: (index) => setState(() => _index = index),
          children: [
            for (final image in images)
              GestureDetector(
                onTap: several ? _controller.nextPage : null,
                child: Image.asset(
                  image.asset,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel: image.alt,
                ),
              ),
          ],
        ),
        if (several)
          PositionedDirectional(
            top: theme.gap(GapSize.sm),
            end: theme.gap(GapSize.sm),
            // The count is read with the carousel ("Page 1 of 2").
            child: ExcludeSemantics(
              child: Glass(
                frosted: false,
                color: _scrim,
                border: const Border.fromBorderSide(BorderSide.none),
                borderRadius: theme.radii.full,
                padding: EdgeInsets.symmetric(
                  horizontal: theme.gap(GapSize.sm),
                  vertical: theme.gap(GapSize.xs),
                ),
                child: Text(
                  '${_index + 1} / ${images.length}',
                  style: theme.textTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _onPhoto,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The article a post links to: thumbnail, source line, title.
class _LinkPreview extends StatelessWidget {
  const _LinkPreview(this.link, {required this.compact});

  final FeedLink link;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final layout = theme.layoutTheme;
    final overline = theme.style.overline;
    return Pressable(
      onPressed: () => showArticlePreview(
        context,
        image: link.image,
        source: link.source,
        title: link.title,
      ),
      builder: (context, states) => FocusRing(
        visible: states.contains(WidgetState.focused),
        borderRadius: HomePostMedia.radiusOf(theme),
        child: Container(
          // A 120-point thumbnail inside the hairline.
          height: 122,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: states.contains(WidgetState.hovered)
                ? scheme.secondary
                : scheme.muted,
            borderRadius: HomePostMedia.radiusOf(theme),
            border: Border.all(color: scheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                link.image,
                // The design gives the desktop thumbnail 168; the phone
                // card is too narrow for that and the title together.
                width: compact ? 104 : 168,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    // 16 on a desktop and 12 on a phone, as the theme's
                    // `lg` gap is.
                    horizontal: layout.gap(GapSize.lg),
                    vertical: compact
                        ? layout.gap(GapSize.md)
                        : theme.gap(GapSize.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        overline.applyCase(link.source),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: overline
                            .apply(theme.textTheme.small)
                            .copyWith(color: scheme.mutedForeground),
                      ),
                      const Gap.xs(),
                      Flexible(
                        child: Text(
                          link.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.large.copyWith(
                            color: scheme.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A post's event: the photograph with the event's date, name and an
/// "Interested" toggle on a glass strip along its bottom edge.
///
/// Everything on the strip sits on a photograph, so its colours are the
/// design's literals and do not follow the theme.
class _EventMedia extends StatefulWidget {
  const _EventMedia(this.event, {required this.compact});

  final FeedEvent event;
  final bool compact;

  @override
  State<_EventMedia> createState() => _EventMediaState();
}

class _EventMediaState extends State<_EventMedia> {
  bool _interested = false;

  void _toggle() => setState(() => _interested = !_interested);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inset = theme.gap(GapSize.md);
    final event = widget.event;
    final compact = widget.compact;
    final star = PhosphorIcon(
      _interested ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
    );

    return ClipRRect(
      borderRadius: HomePostMedia.radiusOf(theme),
      child: Stack(
        children: [
          Image.asset(
            event.image.asset,
            height: compact ? 220 : 320,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: event.image.alt,
          ),
          Positioned(
            left: inset,
            right: inset,
            bottom: inset,
            child: Glass(
              frosted: false,
              color: _scrim,
              border: Border.all(color: const Color(0x2EFFFFFF)),
              borderRadius: HomePostMedia.radiusOf(theme),
              padding: EdgeInsets.symmetric(
                horizontal: theme.gap(GapSize.md),
                vertical: inset,
              ),
              child: UnaRow(
                gap: GapSize.md,
                children: [
                  // The same tile as on a card, in the photograph's fixed
                  // colours.
                  DemoDateTile(
                    month: event.month,
                    day: event.day,
                    color: const Color(0xEBFFFFFF),
                    monthColor: const Color(0xFF176B83),
                    dayColor: _ink,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.large.copyWith(
                            color: _onPhoto,
                          ),
                        ),
                        Text(
                          event.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.muted.copyWith(
                            color: _onPhoto.withValues(alpha: .86),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (compact)
                    // No room for the label beside the event's name.
                    IconButton(
                      size: ButtonSize.sm,
                      style: ButtonTheme(
                        backgroundColor: _onPhoto,
                        hoverBackgroundColor: _onPhotoHover,
                        foregroundColor: _ink,
                        hoverForegroundColor: _ink,
                      ),
                      icon: star,
                      semanticLabel: 'Interested',
                      onPressed: _toggle,
                    )
                  else
                    Button(
                      style: ButtonTheme(
                        gap: theme.gap(GapSize.xs),
                        backgroundColor: _onPhoto,
                        hoverBackgroundColor: _onPhotoHover,
                        foregroundColor: _ink,
                        hoverForegroundColor: _ink,
                        textStyle: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      leading: star,
                      onPressed: _toggle,
                      child: const Text('Interested'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The scrim under text on a photograph. The designs have 36% of near-black
/// over a blur of the photograph; without the blur the photograph's detail
/// is still there under the text, so the scrim is half again as dense.
const _scrim = Color(0x8A09090B);
const _onPhoto = Color(0xFFFFFFFF);
const _onPhotoHover = Color(0xE6FFFFFF);
const _ink = Color(0xFF09090B);
