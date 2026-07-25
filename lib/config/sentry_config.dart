/// ⚠️ PLACEHOLDER — not a real Sentry project. Errors won't go anywhere
/// until this is replaced with a real DSN from https://sentry.io.
/// Firebase Crashlytics doesn't support Flutter Web, which is why this app
/// uses Sentry instead.
class SentryConfig {
  SentryConfig._();

  static const dsn =
      'https://978402fc62a3db74ea4fbbd12856be69@o4511796222689280.ingest.us.sentry.io/4511796239663104';

  static bool get isConfigured => !dsn.startsWith('TODO_');
}
