# Demo images

The pictures the app shows. They were exported from the design files —
the Home feed, Jobs, Messages and Profile screens, each in desktop and
mobile, light and dark — and renamed after what they show. Identical files that appeared in several of the eight
design bundles were deduplicated by content hash.

Paths are declared as constants in `lib/assets.dart` (`DemoAssets`); use
those rather than string literals.

| Prefix | What | Source in the designs |
| --- | --- | --- |
| `avatar_<person>.jpg` | 160×160 portraits of the people in `lib/data.dart` | `<img alt="<name>">` in every screen |
| `avatar_connection_{a,b}.jpg` | Unnamed faces in "mutual connections" stacks | Home feed suggestions, Jobs cards |
| `logo_<company or group>.png` | 256×256 company, school and group marks | Jobs, Profile experience, "Your groups" |
| `photo_*.jpg` | Post media, link previews, the profile cover and featured items | Home feed posts, Profile |
| `story_*.jpg` | Story backgrounds | Home feed story rail |

The directory is flat on purpose: Flutter asset directories are not
recursive, and `pubspec.yaml` declares this one directory.
