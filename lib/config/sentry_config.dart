/// ⚠️ PLACEHOLDER — not a real Sentry project. Errors won't go anywhere
/// until this is replaced with a real DSN from https://sentry.io.
/// Firebase Crashlytics doesn't support Flutter Web, which is why this app
/// uses Sentry instead.
class SentryConfig {
  SentryConfig._();

  static const dsn = 'TODO_REPLACE_WITH_REAL_SENTRY_DSN';

  static bool get isConfigured => !dsn.startsWith('TODO_');
}
