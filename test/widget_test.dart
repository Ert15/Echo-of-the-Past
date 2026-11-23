import 'package:echo_of_the_past/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('показывает HUD игры', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GamePage()),
    );
    await tester.pump();
    expect(find.byType(GamePage), findsOneWidget);
  });
}
