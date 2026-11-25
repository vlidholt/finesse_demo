import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/screens/settings_screen.dart';
import 'package:finesse_demo/session.dart';
import 'package:finesse_demo/widgets/settings_controller.dart';
import 'package:flutter/widgets.dart';

/// Opens the Settings page over whatever Demo is showing, on [section]
/// if one is given and otherwise where it was left.
void openSettings(BuildContext context, [SettingsSection? section]) {
  if (section != null) {
    final settings = context.demo.settings;
    settings.update(() => settings.section = section);
  }
  context.pushFullScreen<void>((context) => const SettingsScreen());
}
