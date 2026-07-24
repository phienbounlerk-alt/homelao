import 'package:flutter_test/flutter_test.dart';

import 'package:home_lao/main.dart';

void main() {
  testWidgets('HomeLao home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const HomeLaoApp());
    expect(find.text('Find your perfect place to live'), findsOneWidget);
  });
}
