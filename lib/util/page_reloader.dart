// Reloads the page on web. This app only ships on web, but `flutter
// test` runs on the Dart VM, which has no dart:html — the conditional
// export keeps that import out of main.dart's unconditional import
// graph so tests can still compile and run.
export 'page_reloader_stub.dart'
    if (dart.library.html) 'page_reloader_web.dart';
