import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/screens/home_screen.dart';
import 'package:una_demo/widgets/compose_dialog.dart';
import 'package:una_demo/widgets/demo_actions.dart';
import 'package:una_demo/widgets/demo_previews.dart';
import 'package:una_demo/widgets/home_feed_scope.dart';
import 'package:una_demo/widgets/home_post_card.dart';

import 'demo_support.dart';

// What the home feed does with the widgets it took on after it was
// designed: pull to refresh, the post's action sheet, the composer that
// publishes, the hover card and the story carousel.

List<String> _postOrder(WidgetTester tester) => [
  for (final card in tester.widgetList<HomePostCard>(find.byType(HomePostCard)))
    card.post.id,
];

HomeFeedModel _feed(WidgetTester tester) => demoSession(tester).feed;

/// Pulls the feed down past the trigger and lets go.
Future<void> _pull(WidgetTester tester) async {
  await tester.drag(find.text('For you'), const Offset(0, 300));
  await tester.pump();
}

void main() {
  setUpAll(loadDemoTestFont);

  group('pull to refresh', () {
    for (final (name, size) in [
      ('phone', demoPhone),
      ('desktop', demoDesktop),
    ]) {
      testWidgets('on a $name a pull brings in a post, through the session', (
        tester,
      ) async {
        await pumpDemoScreen(tester, const HomeScreen(), size: size);
        expect(find.byType(RefreshIndicator), findsOneWidget);
        final before = _postOrder(tester);

        await _pull(tester);
        // The feed is asked, and has not answered yet.
        expect(_feed(tester).isRefreshing, isTrue);
        expect(_postOrder(tester), before);

        await tester.pump(HomeFeedModel.refreshDelay);
        await settleFrames(tester);
        expect(_feed(tester).isRefreshing, isFalse);
        expect(_feed(tester).posts.first, HomeData.freshPosts.first);
        expect(_postOrder(tester).first, HomeData.freshPosts.first.id);
        expect(find.text(HomeData.freshPosts.first.author.name), findsWidgets);
        expect(tester.takeException(), isNull);
        await dismissToasts(tester);
      });
    }

    testWidgets('a short pull refreshes nothing', (tester) async {
      await pumpDemoScreen(tester, const HomeScreen(), size: demoPhone);
      await tester.drag(find.text('For you'), const Offset(0, 30));
      await settleFrames(tester);
      expect(_feed(tester).isRefreshing, isFalse);
    });

    testWidgets('each refresh brings one post while there are any, then '
        'says the feed is up to date', (tester) async {
      await pumpDemoScreen(tester, const HomeScreen(), size: demoPhone);
      final feed = _feed(tester);
      for (final post in HomeData.freshPosts) {
        final arrived = feed.refresh();
        await tester.pump(HomeFeedModel.refreshDelay);
        expect(await arrived, 1);
        expect(feed.posts.first, post);
      }
      await settleFrames(tester);
      expect(find.text('You’re all caught up'), findsNothing);

      // Nothing is left: the pull is answered with a toast.
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      position.jumpTo(0);
      await tester.pump();
      await _pull(tester);
      await tester.pump(HomeFeedModel.refreshDelay);
      await settleFrames(tester);
      expect(find.text('You’re all caught up'), findsOneWidget);
      expect(feed.posts.take(3), HomeData.freshPosts.reversed);
      await dismissToasts(tester);
    });

    testWidgets('two refreshes at once are one', (tester) async {
      await pumpDemoScreen(tester, const HomeScreen(), size: demoPhone);
      final feed = _feed(tester);
      final first = feed.refresh();
      final second = feed.refresh();
      await tester.pump(HomeFeedModel.refreshDelay);
      expect(await first, 1);
      expect(await second, 1);
      expect(feed.posts.where(HomeData.freshPosts.contains), hasLength(1));
    });

    testWidgets('with a mouse, "Refresh feed" in the sort menu does the '
        'same and shows the indicator', (tester) async {
      await pumpDemoScreen(tester, const HomeScreen());
      await tester.tap(find.text('Sort by'));
      await settleFrames(tester);
      // The two orders are a radio group now.
      expect(find.byType(MenuRadioItem<FeedSort>), findsNWidgets(2));
      await tester.tap(find.text('Refresh feed'));
      await tester.pump();
      await tester.pump();
      expect(_feed(tester).isRefreshing, isTrue);
      await tester.pump(HomeFeedModel.refreshDelay);
      await settleFrames(tester);
      expect(_postOrder(tester).first, HomeData.freshPosts.first.id);
      expect(tester.takeException(), isNull);
    });
  });

  group('a post\'s "More options"', () {
    testWidgets('is an action sheet on a phone, with the menu\'s actions', (
      tester,
    ) async {
      await pumpDemoScreen(tester, const HomeScreen(), size: demoPhone);
      const post = HomeData.onboardingWorkshop;
      expect(find.byType(DropdownMenu), findsNothing);

      await tester.tap(find.bySemanticsLabel('More options').first);
      await settleFrames(tester);
      expect(find.byType(ActionSheet<void>), findsOneWidget);
      expect(find.text('Post by ${post.author.name}'), findsOneWidget);
      for (final label in [
        'Save post',
        'Copy link',
        'Follow ${post.author.firstName}',
        'Not interested',
        'Cancel',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      // An action closes the sheet and acts.
      expect(_feed(tester).isFollowing(post.author), isFalse);
      await tester.tap(find.text('Follow ${post.author.firstName}'));
      await settleFrames(tester);
      expect(find.byType(ActionSheet<void>), findsNothing);
      expect(_feed(tester).isFollowing(post.author), isTrue);

      // Cancel only closes it.
      await tester.tap(find.bySemanticsLabel('More options').first);
      await settleFrames(tester);
      expect(find.text('Unfollow ${post.author.firstName}'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settleFrames(tester);
      expect(find.byType(ActionSheet<void>), findsNothing);
      expect(_feed(tester).isFollowing(post.author), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays a menu on a desktop', (tester) async {
      await pumpDemoScreen(tester, const HomeScreen());
      await tester.tap(find.bySemanticsLabel('More options').first);
      await settleFrames(tester);
      expect(find.byType(ActionSheet<void>), findsNothing);
      expect(find.byType(MenuItem), findsNWidgets(4));
      expect(find.text('Save post'), findsOneWidget);
    });
  });

  group('the composer', () {
    for (final (name, size) in [
      ('phone', demoPhone),
      ('desktop', demoDesktop),
    ]) {
      testWidgets('on a $name "Post" publishes to the top of the feed, and '
          'the toast takes it back', (tester) async {
        await pumpDemoScreen(tester, const HomeScreen(), size: size);
        final feed = _feed(tester);
        showComposeDialog(demoContext(tester));
        await settleFrames(tester);

        // Nothing to post yet.
        Button post() => tester.widget<Button>(
          find.widgetWithText(Button, 'Post'),
        );
        expect(post().enabled, isFalse);

        await tester.enterText(find.byType(Textarea), 'Hello, Demo');
        await tester.pump();
        expect(post().enabled, isTrue);
        expect(post().loading, isFalse);

        await tester.tap(find.widgetWithText(Button, 'Post'));
        await tester.pump();
        // Sending: the button spins, and a second press does nothing.
        expect(post().loading, isTrue);
        expect(feed.posts.first.author, isNot(People.me));

        await tester.pump(const Duration(milliseconds: 700));
        await settleFrames(tester);
        expect(find.byType(Dialog), findsNothing);
        final published = feed.posts.first;
        expect(published.author, People.me);
        expect(published.body, 'Hello, Demo');
        expect(find.text('Hello, Demo'), findsOneWidget);
        expect(find.text('Be the first to react'), findsOneWidget);
        expect(feed.composeDraft.text, isEmpty);
        expect(find.text('Post published'), findsOneWidget);

        // Undo takes the post out and gives the words back.
        await tester.tap(find.text('Undo'));
        await settleFrames(tester);
        expect(feed.posts, isNot(contains(published)));
        expect(feed.composeDraft.text, 'Hello, Demo');
        expect(tester.takeException(), isNull);
        await dismissToasts(tester);
      });
    }

    testWidgets('a draft is still there when the composer is opened again', (
      tester,
    ) async {
      await pumpDemoScreen(tester, const HomeScreen());
      showComposeDialog(demoContext(tester));
      await settleFrames(tester);
      await tester.enterText(find.byType(Textarea), 'Half a thought');
      await tester.tap(find.text('Cancel'));
      await settleFrames(tester);
      expect(find.byType(Dialog), findsNothing);

      showComposeDialog(demoContext(tester));
      await settleFrames(tester);
      expect(find.text('Half a thought'), findsOneWidget);
    });

    testWidgets('a post of the user\'s own can be deleted, with Undo', (
      tester,
    ) async {
      await pumpDemoScreen(tester, const HomeScreen());
      final feed = _feed(tester);
      final post = feed.publish('Mine');
      await settleFrames(tester);
      expect(_postOrder(tester).first, post.id);

      await tester.tap(find.bySemanticsLabel('More options').first);
      await settleFrames(tester);
      await tester.tap(find.text('Delete post'));
      await settleFrames(tester);
      expect(_postOrder(tester), isNot(contains(post.id)));

      await tester.tap(find.text('Undo'));
      await settleFrames(tester);
      expect(_postOrder(tester).first, post.id);
      await dismissToasts(tester);
    });
  });

  group('the hover card', () {
    testWidgets('resting the pointer on an author\'s name shows who they '
        'are, on a desktop', (tester) async {
      await pumpDemoScreen(tester, const HomeScreen());
      const author = People.omar;
      final name = find.descendant(
        of: find.byType(PersonHoverCard),
        matching: find.text(author.name),
      );
      expect(name, findsWidgets);
      expect(find.text('1st · In your network'), findsNothing);
      expect(find.text('2nd · Not connected yet'), findsNothing);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(name.first));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await settleFrames(tester);
      // The headline a second time: once in the post, once in the card.
      expect(find.text(author.headline), findsNWidgets(2));

      // Moving away closes it.
      await mouse.moveTo(const Offset(5, 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await settleFrames(tester);
      expect(find.text(author.headline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a phone has none: the name is a plain link', (tester) async {
      await pumpDemoScreen(tester, const HomeScreen(), size: demoPhone);
      expect(find.byType(PersonHoverCard), findsWidgets);
      expect(find.byType(HoverCard), findsNothing);
    });
  });

  group('the story viewer', () {
    testWidgets('is a carousel of every story, opened on the one that was '
        'tapped', (tester) async {
      await pumpDemoScreen(tester, const HomeScreen(), size: demoPhone);
      final stories = HomeData.stories;
      showStoryViewer(demoContext(tester), stories[1]);
      await settleFrames(tester);

      Finder inViewer(Finder finder) =>
          find.descendant(of: find.byType(Dialog), matching: finder);
      final indicator = inViewer(find.byType(PageIndicator));
      final carousel = inViewer(find.byType(Carousel));
      expect(carousel, findsOneWidget);
      expect(tester.widget<PageIndicator>(indicator).count, stories.length);
      expect(tester.widget<PageIndicator>(indicator).index, 1);
      expect(
        find.text('Reply to ${stories[1].person.firstName}'),
        findsOneWidget,
      );

      // A swipe turns to the next person's story.
      await tester.fling(carousel, const Offset(-300, 0), 1500);
      await settleFrames(tester, frames: 20);
      expect(tester.widget<PageIndicator>(indicator).index, 2);
      expect(
        find.text('Reply to ${stories[2].person.firstName}').hitTestable(),
        findsOneWidget,
      );

      // Replying closes the viewer and says so.
      await tester.tap(
        find.text('Reply to ${stories[2].person.firstName}').hitTestable(),
      );
      await settleFrames(tester);
      expect(find.byType(Dialog), findsNothing);
      expect(
        find.text('Reply sent to ${stories[2].person.firstName}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await dismissToasts(tester);
    });
  });

  testWidgets('on a phone a post\'s photographs have page dots', (
    tester,
  ) async {
    await pumpDemoScreen(tester, const HomeScreen(), size: demoPhone);
    final pager = find.descendant(
      of: find.byKey(ValueKey(HomeData.onboardingWorkshop.id)),
      matching: find.byType(PageIndicator),
    );
    expect(pager, findsOneWidget);
    expect(tester.widget<PageIndicator>(pager).count, 2);
  });
}
