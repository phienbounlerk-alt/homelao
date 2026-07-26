// package:web's currently-published version (1.1.1, also the latest on
// pub.dev) fails to compile under this project's Dart SDK — its
// dart:js_interop extension members (.toJS/.jsify()) don't resolve. Until
// that's fixed upstream, dart:html is the only working way to call
// window.location.reload().
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

void reloadPage() => html.window.location.reload();
