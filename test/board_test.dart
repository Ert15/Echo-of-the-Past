import 'package:echo_of_the_past/board.dart';
import 'package:echo_of_the_past/levels.dart';
import 'package:flutter_test/flutter_test.dart';

const L = Move.left, R = Move.right, U = Move.up, W = Move.wait;

Board play(int level, List<Move> moves) {
  final b = Board(levels[level]);
  for (final m in moves) {
    b.act(m);
  }
  return b;
}

void main() {
  test('уровень 1: простой проход', () {
    expect(play(0, List.filled(6, R)).status, Status.won);
  });

  test('уровень 1: стоять на старте, пока появится Эхо = проигрыш', () {
    expect(play(0, List.filled(4, W)).status, Status.lost);
  });

  test('уровень 2: лестница и возврат', () {
    final moves = [...List.filled(8, R), U, U, ...List.filled(8, L)];
    expect(play(1, moves).status, Status.won);
  });

  test('уровень 3: Эхо держит плиту, дверь открыта', () {
    expect(play(2, [R, R, W, W, R, W, R, R, R]).status, Status.won);
  });

  test('уровень 3: без Эха дверь не пройти', () {
    final b = play(2, [R, R, R, R, R, R]);
    expect(b.status, isNot(Status.won));
  });

  test('уровень 4: платформа держится, пока Эхо на плите', () {
    final moves = [R, R, ...List.filled(5, W), ...List.filled(6, R)];
    expect(play(3, moves).status, Status.won);
  });

  test('отмена хода восстанавливает состояние', () {
    final b = play(2, [R, R]);
    b.undo();
    expect(b.turn, 1);
    expect(b.history.length, 1);
  });

  test('уровень 5: рычаг открывает дверь', () {
    expect(play(4, List.filled(7, R)).status, Status.won);
  });

  test('циклические ворота блокируют движение в закрытой фазе', () {
    final b = Board(levels[6]);
    for (var i = 0; i < 4; i++) {
      b.act(R);
    }
    expect(b.present.x, 4);
    b.act(W);
    b.act(R);
    expect(b.present.x, 5);
  });

  test('шаг, начатый в тумане, записывается как ожидание', () {
    const level = LevelData(
      name: 'Туман',
      hint: '',
      delay: 2,
      rows: ['########', '#S.F..B#', '########'],
    );
    final b = Board(level);
    b.act(R);
    b.act(R);
    b.act(R);
    expect(b.history[2], Move.wait);
  });

  test('вторая плита распознаётся картой уровня', () {
    final b = Board(levels[7]);
    expect(b.tileAt(7, 1), Tile.plate2);
  });
}
