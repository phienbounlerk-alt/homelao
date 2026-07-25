import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:home_lao/main.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // EmptyLocalStorage avoids touching the filesystem/Hive so this stays a
    // pure widget test; no real network call happens on initialize itself.
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  testWidgets('boots to the login screen when signed out', (tester) async {
    await tester.pumpWidget(const HomeLaoApp());
    await tester.pump();

    expect(find.text('ເຂົ້າສູ່ລະບົບ'), findsOneWidget);
  });
}
