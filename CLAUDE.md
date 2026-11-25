# Working notes for `finesse_demo`

Things that are true about this repo and are expensive to rediscover.
Written for whoever (or whatever) picks the work up next.

## What this is

**Demo** is a fictional professional network built entirely from
[`finesse`](https://github.com/vlidholt/finesse) widgets. It replicates the
designs that `finesse`'s default look (`StyleTokens.finesse` on
`TealColorScheme`, set in Geist) was measured from: four screens (Home,
Jobs, Messages, Profile), each in desktop and mobile, light and dark. It
lived in `finesse`'s `example/` as "Strand" until it was split out; the
component library and the theme editor stayed there. This repo's history
starts at the split. What came before is in `finesse`'s history under
`example/lib/strand/`.

It deploys to <https://vlidholt.github.io/finesse_demo/> on every push to
`main` (`.github/workflows/deploy-pages.yaml`).

`finesse`'s own `CLAUDE.md` is the reference for the package: its theme
architecture, motion, glass, overlays, Flutter gotchas and test habits all
apply here. Read it before changing anything that looks like a workaround.

## Depending on finesse

- `pubspec.yaml` takes `finesse` from git, `main` of `vlidholt/finesse`,
  and `pubspec.lock` pins the commit. Move it with
  `flutter pub upgrade finesse`, and commit the lock.
- For local work against a checkout beside this one, a **gitignored**
  `pubspec_overrides.yaml` points it at `../finesse`:

  ```yaml
  dependency_overrides:
    finesse:
      path: ../finesse
  ```

  With the override in place, `pubspec.lock` records a path. Do not commit
  that lock (`git checkout pubspec.lock`, or move the override aside and
  run `flutter pub get`). CI has no override, so a change that needs an
  unreleased `finesse` change waits until that lands on `finesse`'s `main`.
- The app uses `finesse`'s public barrel only (`package:finesse/finesse.dart`)
  and no Material, so there is no `FinesseMaterial` here.

## The app

- `lib/main.dart` builds two `ThemeData`s once: the package default in
  light and dark, with text in Geist
  (`TextTheme.fromGoogleFont(GoogleFonts.geist)`, a static tear-off, so the
  theme compares equal). It awaits Geist before `runApp`. `FinesseApp`'s
  `home` is `DemoShell`.
- App-wide settings are solidart signals behind disco providers in
  `lib/app_state.dart`: `themeModeProvider`, and `textScaleProvider`, which
  is applied as the `MediaQuery` text scaler in `FinesseApp.builder` rather
  than through the theme, so the Settings slider builds no theme.
  `demoProviders` in `main.dart` adds the shell's destination, the session
  and the Jobs view. A test that pumps part of the app provides
  `appProviders` and whatever else it needs.
- There is no theme editor here; it is in `finesse`'s example. To see a
  screen under another style, a test themes it (the theme-coverage test
  does), or `main.dart` is changed locally.
- `google_fonts` is the only font source. **Never
  `GoogleFonts.getFont(name)` or `asMap()`**: either keeps all 1,700
  families in the web build. Name the method.

## Rules the screens follow

- `demo_shell.dart` is a `NavigationScaffold` over a `DestinationStack`;
  on a desktop narrower than 1024 (`DemoShell.topBarFrom`) the
  destinations leave the top bar for a `NavigationRail`, and choosing the
  destination already showing scrolls it to the top. Pushed pages use the
  app bar's implied `BackButton`. `navigation.dart` has
  `DemoDestination`, `context.goTo(...)` and
  `context.pushFullScreen(builder)`. `data.dart` and `assets.dart` hold the
  people, companies and image paths shared by the screens (images are in
  `assets/images/`, taken from the design files; see its README).
- One screen per destination: `screens/<x>_screen.dart`, its pieces in
  `widgets/<x>_*.dart`, its content in `data/<x>_data.dart`, its tests in
  `test/demo_<x>_screen_test.dart`. Home, Jobs, Messages and
  Profile come from the designs. Network, Notifications, Search and Settings
  were never drawn; they are built from the designed screens' pieces and
  rules (`widgets/demo_pieces.dart` has the shared page header, section
  heading, pill button, mark and date tile). Settings and Search are pushed
  routes. Jobs has a second view, "My applications", a `Board`
  (`widgets/jobs_board*.dart`, `jobsViewProvider`,
  `context.openApplications()`), and Easy Apply is a three-step `Stepper`
  in a dialog. Messages is a `ListDetailLayout`; a thread is a `ChatList`;
  the conversation pinned first, "Demo Assistant", streams its replies
  into a `StreamingText`, and the send button is a stop button while one
  arrives. The screens use the package's own widgets for what the designs
  imply (`RefreshIndicator`, `SwipeActions` with the same actions in a
  context menu for a mouse, `Carousel`, `HoverCard`, `showActionSheet`,
  `SegmentedControl`, `TagField`, picker sheets and wheels on a phone,
  `ListSection` rows, `Button(loading:)`, toast variants).
- **State more than one place shows is in the `DemoSession`**
  (`session.dart`, `context.demo`, provided beside
  `demoDestinationProvider`): `notifications`, `messages`, `network`,
  `search` (recent searches), `settings`, and `jobs` with `applications` —
  the Jobs screen's two sides, its summary tiles and the "Saved items" sheet
  count the same saved jobs. A screen's own state stays in the screen
  (`HomeFeedModel`).
  - `session.messages` is the one `MessagesController`: a reply goes on
    arriving after the user has left the Messages screen. The shell's badge
    is its `unreadCount` (a `ValueListenable`; requests are not counted),
    a reply landing in a thread nobody is looking at (`threadVisible`) is
    unread, and `session.badges` announces a change in either badge number
    and nothing else. How the other side answers is injected
    (`MessagesReplies`, `widgets/messages_assistant.dart`).
  - The session reports every listing to `ApplicationsController.track`
    whenever anything about the Jobs screen changes, so `track` acts only
    on a listing whose saved or applied state *changed*. Re-syncing from
    the full state undid whatever the user had done on the board since.
  - A test that pumps a screen alone adds `demoSessionProvider` to its
    providers, or wraps it in `DemoSessionHost`
    (`test/demo_support.dart`) to decide who answers a message and when;
    disco disposes an overridden value with the provider's own `dispose`,
    so the session's timers die with the test's tree.
- **What the user typed must not live in a `State` that a layout change
  rebuilds.** The desktop and phone feeds are different widgets, and a
  resize swaps one for the other: a half-written
  comment is in `HomeFeedModel.draftFor(post)`; the selected settings page
  is held by a `GlobalKey` and moves between the two arrangements with its
  state; and its field grid is one `Wrap` either way (`_FieldGrid`), so the
  field being typed in keeps its focus when the column count changes.
- **A control named by a visible label is one semantic node**
  (`MergeSemantics`, or `ExcludeSemantics` on the label the control
  repeats). `announced(tester, text)` in `test/demo_support.dart` returns
  what a screen reader stops on; a labelled control must come out of it
  once.
- **Nothing in Demo is a dead end.** A control with no designed
  destination gets the lightest real response from
  `widgets/demo_actions.dart` / `demo_previews.dart`: a preview dialog,
  a toast with Undo, or a trip to the screen that owns the subject.
  `grep "onPressed: () {}"` under `lib/` should stay empty.
- **From a pushed page, navigate with `context.leaveTo(destination)`**,
  which pops the page first; `goTo` would switch the shell underneath it.
  Call it with the page's context, not a dialog's.
- **A panel with no barrier lives and dies with the focus.** The desktop
  search panel (`widgets/search_bar.dart`) is a `Popover(requestFocus:
  false)`, not a route, so nothing but the focus says whether it is in use.
  Field and panel sit under a `Focus` that cannot take the focus itself and
  whose `onFocusChange(false)` closes the panel — Tab away, a click
  elsewhere, a result opening a dialog. The popover makes them one
  traversal group, and the field takes the popover's `groupId`, so a click
  on the panel neither closes it nor takes the caret. It opens from `onTap`
  as well as on a focus gain: after a tap outside on a touch screen the
  field still has the focus.
- **A global shortcut asks the package's `isInTopRoute(context)`, not
  `ModalRoute.isCurrent`** (the search bar). A page's own route stays
  current under a dialog in another navigator, and the package's check
  looks at every navigator up; a
  `HardwareKeyboard` handler hears keys wherever the focus is and would
  reach through the barrier. The search shortcut is one modifier per
  platform and no other with it (`SearchField.isSearchShortcut`): ⌘K on
  Apple platforms, Ctrl+K elsewhere — Ctrl+K deletes to the end of the line
  in every macOS text field, and AltGr reports itself as Ctrl+Alt on
  Windows.
- Search wants every word of the query; a canned query (a trending topic)
  is mapped to words the data contains, and
  `demo_search_screen_test.dart` checks every suggested search finds
  something.
- A test finder for a tappable row's inner `Semantics` label finds nothing:
  `Pressable` merges it into the row's node. Find the widget instead. To
  focus a chip of a `ChipGroup`, go through `Chip.focusNode`: `Focus.of`
  finds the group's non-focusable wrapper. `completeEasyApply` in
  `test/demo_support.dart` walks the application stepper.
- **A screen is built inside the shell's `Scaffold`**, so its `MediaQuery`
  padding already includes the bars; a `PageContainer(scrollable: true)`
  clears them and lets content scroll underneath. A view that needs
  the whole phone screen (a conversation, a job's detail) is a *pushed route*
  with its own `Scaffold` + `AppBar`, pushed on the app's navigator over the
  shell.
- **The form factor follows the window.** `FinesseApp` picks it from the
  width, below the theme's `breakpoints.md`; nothing in the app overrides
  it.
- **Layout rules the screens follow** (keep to them when adding one): sizes
  come from the theme, never from `if (mobile)`; branch on the form factor
  only where the design *rearranges*; decide how many columns fit from a
  `LayoutBuilder`'s width so 800–1200px windows degrade gracefully.
- **Demo takes every size from the theme, and a test holds it to that.**
  Text is a `Theme.of(context).textTheme` style (`h1`, `h3`, `h4`, `large`,
  `p`, `small`, `muted`, `caption`), copied for a weight or colour, never
  given a `fontSize`; gaps are `Gap.md()` / `GapSize` / `theme.gap(...)`;
  radii are `theme.radii`; and the sizes the package has no token for come
  from `widgets/demo_metrics.dart`, an extension on `ThemeData` that
  derives them from one — avatar steps `avatarXs`…`avatarXl` from the
  theme's avatar, `iconBeside(style)` for a glyph set in a line of text,
  `cardInsets` for a surface laid out like a card. A design value between
  two steps was snapped to the nearer one on purpose (gaps of 6, 10, 14 and
  18 became 4, 8, 12 and 16); do not reintroduce named off-scale constants
  (the old `*_metrics.dart` files are gone).
  `test/demo_theme_coverage_test.dart` builds every screen but
  Messages under the default theme and under one whose type, gap, radius,
  avatar and glyph sizes all differ, and fails — with file and line — on
  any size a Demo source file hands to a widget that is the same in
  both. A size that is meant to be a literal (a photograph's height, the
  logo, the story rail) goes in its `_exempt` map with the reason. A
  `Divider` between sections of a card passes `margin: EdgeInsets.zero`:
  the shadcn styles give dividers a 16-point margin of their own. A tab
  strip that fills a phone's width uses `DemoTabLabel`, which shrinks the
  label to fit where a `Tab`'s own text would end in an ellipsis.
- **Text and icons drawn straight on a surface use `scheme.tint`**, never
  `accentForeground`. The two are the same teal in the default scheme, but
  `accentForeground` is the ink *on an accent fill* (a selected chip, a
  highlighted menu row) and need not read on a card.
- **Reading the designs.** In the design HTML, `<span>`/`<div>` are
  content-box and `<button>` is border-box: a `h:30` span with a 1px border
  renders 32 tall, which is why skill chips are 32. A header of `h:64` with
  a bottom border is 65 — `AppBar` and `TabBar` add their hairline to their
  height for the same reason.
- **A label on a photograph is a plain scrim, not glass.** A backdrop
  filter samples everything behind it within the blur radius, so a frosted
  label on a dark photo picks up the pale page around the card and turns
  grey (CSS samples only under the element), and isolating each card with
  `Clip.antiAliasWithSaveLayer` cost a save layer and a filter per card.
  A story's name sits on a scrim with no filter (`home_stories.dart`).
- **A row of chips choosing one of several** is a
  `ChipGroup(value:, allowDeselection: false, wrap: false)`, which
  fades at the edge it scrolls beyond; an action held at the start or end
  of the row ("All filters", "Filters") is `ChipGroup.leading`/`trailing`,
  outside the choices and the scroll view, with Tab stops of its own (it
  needs a bounded width). A bar that scrolls out to the screen edge (Jobs
  and Home on the phone) needs the page to keep only its vertical margins,
  every other child taking the side margins itself.
- **A toast's action that navigates captures a `NavigatorState` and the
  signals at show time** (`applicationsOpener`), never a `BuildContext`:
  the page that showed it may be gone by the time it is tapped.
- **Verifying a screen without running the app:** render it to PNG from a
  test (`RepaintBoundary.toImage` inside `tester.runAsync`, Phosphor fonts
  loaded from `fonts/phosphor/` as `packages/finesse/PhosphorRegular` etc.,
  a system TTF as the body font, `debugDisableShadows = false`, every
  `AssetImage` precached) and compare with the design. flutter_test's own
  font is an em-wide box per glyph and overflows labels that fit any real
  font, so screen tests load the JetBrains Mono in `fonts/` (tests only;
  the app does not bundle it).

## Performance

What a frame costs on the web is counted by `test/perf_structure_test.dart`
(backdrop filters, save layers, builds and paints per scroll frame, at rest
and across a theme switch, per screen at both sizes). It is timed in a
browser with `flutter build web --release -t test_driver/perf.dart` and
`await finessePerf.scroll(1200, 2)` in the console;
`finessePerf.goTo('jobs')` switches the destination and
`finessePerf.toggleTheme()` the brightness. The browser must be *showing*:
a hidden pane runs animation at 1 Hz. `FrameTiming.raster` on the web ends
when commands reach the GPU, so GPU-bound work does not show in it. The
package's own performance rules (cards do not blur, a scrolling page is a
layer, something that never stops is painted, not built) are in
`finesse`'s `CLAUDE.md`.

**Timing on an iPhone needs the JIT.** iOS 27 Safari runs a page served
over plain http without it (WebKit bug 324968, intended): JavaScript and
WebAssembly are interpreted, and a build served from a Mac on the LAN
measures five to twenty times too slow. Time a phone over https (the
Pages deploy), or on the LAN with Safari's Enhanced Security Heuristics
feature flag off. With the JIT on, Home scrolled at 59 fps in every top
bar variant tried; the differences were in late frames (over 17.5 ms): an
opaque top bar about 5 %, six blur strips about 10 %, a one-pass shader
blur about 20 %. On the web the glass top bar is therefore finesse's
solid bar (`finesse`'s `CLAUDE.md`, "Liquid Glass").

## Testing

- `test/support.dart` has `setUpFonts` (google_fonts fetching off, so Geist
  falls back to the test font), `settle` (fixed frames: `pumpAndSettle`
  hangs on the typing indicator, skeletons and spinners), `pumpApp`, and
  `appContext`. That is the shell's context, found with
  `skipOffstage: false`, so it is there under any pushed route.
- `test/demo_support.dart` has `pumpDemoScreen` (one screen outside the
  shell, in the JetBrains Mono test font), the window sizes every screen is
  built in, `DemoSessionHost`, `announced` and `completeEasyApply`.
- A test that checks "nothing overflows" at several sizes pumps a fresh
  tree for each: an overflow is reported once per render object.
- The `finesse` test notes apply: an overlay needs about 12 × 50 ms before
  a tap, an overlay's element hangs under its anchor
  (`skipOffstage: false`), tests run as Android, and `tester.tap` is a
  touch unless given a mouse.
- Shortening the wordmark changes where the desktop bar's search field
  collapses to its magnifier: `demo_search_bar_test.dart` picks a window
  width for that case, so check it when the logo or the bar changes.

## Build and CI

- Verify with `flutter analyze`, `flutter test --timeout 120s` and
  `dart format --set-exit-if-changed lib test test_driver`.
  `.github/workflows/flutter-test.yaml` runs the same on every push and
  pull request.
- `web/` is committed (title, manifest). The other platform folders are
  gitignored and regenerated with `flutter create . --platforms <name>`. On
  macOS the app needs the `com.apple.security.network.client` entitlement
  for `google_fonts`.
- The Pages deploy uses no retry wrapper action: `Wandalen/wretry.action`
  passes the whole event to node on the command line, and a large push
  failed with "Argument list too long". The deploy step instead runs once
  more by itself if the first attempt fails.
- `test_driver/app.dart` wraps `main()` in `enableFlutterDriverExtension()`
  (`flutter run -t test_driver/app.dart`). Driver commands hang until
  `set_frame_sync: false`.
