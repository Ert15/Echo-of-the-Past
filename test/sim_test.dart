import 'package:echo_of_the_past/sim.dart';
import 'package:flutter_test/flutter_test.dart';

// Записанное прохождение уровня 1: [ввод, сколько тиков]. 2 = вправо, 6 = вправо + прыжок.
const solution = [
  [2, 16], [6, 13], [2, 10], [6, 13], [2, 9],
  [6, 13], [2, 9], [6, 13], [2, 10], [6, 13], [2, 36],
];

List<int> expand() => [
      for (final r in solution) ...List.filled(r[1], r[0]),
    ];

void main() {
  test('кампания содержит 11 уровней с нарастающей задержкой', () {
    expect(levels, hasLength(11));
    for (var i = 1; i < levels.length; i++) {
      expect(levels[i].echoDelay, greaterThanOrEqualTo(levels[i - 1].echoDelay));
    }
  });

  test('уровень 1 проходится по записи', () {
    final sim = Sim(level1);
    for (final i in expand()) {
      sim.step(i);
    }
    expect(sim.status, Status.won);
    expect(sim.tick, lessThanOrEqualTo(155));
  });

  test('стоять на старте нельзя: Эхо появляется и сталкивается', () {
    final sim = Sim(level1);
    for (var i = 0; i <= level1.echoDelay; i++) {
      sim.step(0);
    }
    expect(sim.status, Status.dead);
  });

  test('Эхо повторяет путь игрока ровно с задержкой', () {
    final sim = Sim(level1);
    final xs = <double>[], ys = <double>[];
    for (var i = 0; i < level1.echoDelay + 1; i++) {
      sim.step(0);
      xs.add(sim.player.x);
      ys.add(sim.player.y);
    }
    expect(sim.echo, isNotNull);
    final j = level1.echoDelay - level1.echoDelay;
    expect(sim.echo!.x, xs[j]);
    expect(sim.echo!.y, ys[j]);
  });
}
