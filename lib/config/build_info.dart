/// The commit this build was compiled from, injected by CI via
/// `--dart-define=BUILD_SHA=...`. Stays 'dev' for a local `flutter run`,
/// which has nothing meaningful to compare against.
class BuildInfo {
  BuildInfo._();

  static const String buildSha = String.fromEnvironment(
    'BUILD_SHA',
    defaultValue: 'dev',
  );
}
