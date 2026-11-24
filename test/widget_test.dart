import 'package:echo_of_the_past/main.dart';
import 'package:echo_of_the_past/menu.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('главное меню запускает игру и работает пауза', (tester) async {
    await tester.pumpWidget(const EchoOfThePastApp());
    await tester.pump();
    expect(find.byType(MainMenu), findsOneWidget);

    await tester.tap(find.text('ИГРАТЬ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(GamePage), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('ПАУЗА'), findsOneWidget);

    await tester.tap(find.text('ПРОДОЛЖИТЬ'));
    await tester.pump();
    expect(find.text('ПАУЗА'), findsNothing);
  });
}
