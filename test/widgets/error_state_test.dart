import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_lao/widgets/error_state.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the default message and a retry button', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ErrorState(onRetry: () {})));

    expect(find.text('ໂຫລດຂໍ້ມູນບໍ່ສຳເລັດ, ກະລຸນາລອງໃໝ່'), findsOneWidget);
    expect(find.text('ລອງໃໝ່'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });

  testWidgets('shows a custom message when given one', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorState(onRetry: () {}, message: 'ອັບໂຫລດຮູບບໍ່ສຳເລັດ'),
      ),
    );

    expect(find.text('ອັບໂຫລດຮູບບໍ່ສຳເລັດ'), findsOneWidget);
  });

  testWidgets('calls onRetry when the retry button is tapped', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(home: ErrorState(onRetry: () => retried = true)),
    );

    await tester.tap(find.text('ລອງໃໝ່'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
