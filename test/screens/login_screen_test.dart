import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_lao/screens/login_screen.dart';

/// [find.textContaining] doesn't match [RichText]'s combined plain text the
/// way [find.text] does, so the signup toggle link (built from two
/// [TextSpan]s) needs a predicate match instead.
Finder _richTextContaining(String pattern) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is RichText && widget.text.toPlainText().contains(pattern),
  );
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the login form by default', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('ເຂົ້າສູ່ລະບົບ'), findsOneWidget);
    expect(find.text('ອີເມວ'), findsOneWidget);
    expect(find.text('ຊື່ ແລະ ນາມສະກຸນ'), findsNothing);
  });

  testWidgets('switches to the signup form when tapped', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(_richTextContaining('ສະໝັກສະມາຊິກ'));
    await tester.pumpAndSettle();

    expect(find.text('ຊື່ ແລະ ນາມສະກຸນ'), findsOneWidget);
  });

  testWidgets('shows a validation error for an empty submit', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.text('ເຂົ້າສູ່ລະບົບ').first);
    await tester.pump();

    expect(find.text('ກະລຸນາປ້ອນອີເມວ'), findsOneWidget);
  });
}
