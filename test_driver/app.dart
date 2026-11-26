import 'package:flutter_driver/driver_extension.dart';
import 'package:una_demo/main.dart' as app;

/// Entrypoint used by tooling (e.g. the Dart MCP server) to drive the app:
/// `flutter run -t test_driver/app.dart`.
void main() {
  enableFlutterDriverExtension();
  app.main();
}
