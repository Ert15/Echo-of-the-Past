import 'package:echo_of_the_past/platformer_levels.dart';
import 'package:echo_of_the_past/platformer_sim.dart';
import 'package:flutter_test/flutter_test.dart';

import 'platformer_solutions.dart';

void main() {
  test('уровней столько же, сколько решений', () {
    expect(levels.length, solutions.length);
  });
  test('уровень 2: падение в яму убивает игрока', () {
    final sim = Sim(levels[1]);
    for (var t = 0; t < 120 && sim.status == Status.playing; t++) {
      sim.step(inR);
    }

    expect(sim.status, Status.dead);
    expect(sim.player.y, greaterThan(190));
  });
  for (var i = 0; i < levels.length; i++) {
    test('уровень ${i + 1} проходится по записи', () {
      final sim = Sim(levels[i]);
      for (final r in solutions[i]) {
        for (var k = 0; k < r[1]; k++) {
          sim.step(r[0]);
        }
      }
      expect(sim.status, Status.won);
    });
    test('уровень ${i + 1}: стоять на месте нельзя', () {
      final sim = Sim(levels[i]);
      for (var t = 0; t < 1500 && sim.status == Status.playing; t++) {
        sim.step(0);
      }
      expect(sim.status, isNot(Status.won));
    });
  }
}
