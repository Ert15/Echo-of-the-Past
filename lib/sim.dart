// Чистая детерминированная симуляция (без Flutter/Flame).
// Игрок и Эхо двигаются ОДНИМ И ТЕМ ЖЕ кодом (Body.step).
// Эхо берёт ввод игрока из истории со сдвигом echoDelay тиков.
import 'dart:math' as math;

const int inL = 1, inR = 2, inJ = 4;
const double tickDt = 1 / 60;

class Rc {
  final double x, y, w, h;
  const Rc(this.x, this.y, this.w, this.h);
  bool overlaps(Rc o) =>
      x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y;
  Rc shrink(double d) => Rc(x + d, y + d, w - 2 * d, h - 2 * d);
}

class Level {
  final String name;
  final int echoDelay; // в тиках (60 тиков = 1 секунда)
  final double spawnX, spawnY;
  final List<Rc> solids; // первые frameCount - рамка комнаты, дальше платформы
  final int frameCount;
  final Rc goal;
  const Level({
    required this.name,
    required this.echoDelay,
    required this.spawnX,
    required this.spawnY,
    required this.solids,
    required this.frameCount,
    required this.goal,
  });
}

// Задержка измеряется в тиках: 60 тиков = 1 секунда. Первые уровни
// дают игроку 3-5 секунд на самостоятельное прохождение.
const level1 = Level(
  name: '1. ПЕРВОЕ ЭХО',
  echoDelay: 180,
  spawnX: 52,
  spawnY: 160,
  frameCount: 4,
  solids: [
    Rc(0, 172, 320, 8), // пол
    Rc(0, 0, 320, 12), // потолок
    Rc(0, 12, 7, 160), // левая стена
    Rc(313, 12, 7, 160), // правая стена
    Rc(88, 165, 26, 7),
    Rc(118, 157, 26, 7),
    Rc(148, 149, 26, 7),
    Rc(178, 141, 26, 7),
    Rc(236, 133, 77, 6), // площадка со светом
  ],
  goal: Rc(281, 116, 4, 17),
);

const levels = <Level>[
  level1,
  Level(
    name: '2. ЯМА',
    echoDelay: 180,
    spawnX: 34,
    spawnY: 160,
    frameCount: 4,
    solids: [
      Rc(0, 172, 320, 8),
      Rc(0, 0, 320, 12),
      Rc(0, 12, 7, 160),
      Rc(313, 12, 7, 160),
      Rc(70, 154, 28, 7),
      Rc(112, 137, 28, 7),
      Rc(154, 154, 28, 7),
      Rc(196, 128, 28, 7),
      Rc(236, 112, 77, 7),
    ],
    goal: Rc(281, 95, 4, 17),
  ),
  Level(
    name: '3. ОКНО',
    echoDelay: 210,
    spawnX: 28,
    spawnY: 160,
    frameCount: 4,
    solids: [
      Rc(0, 172, 320, 8),
      Rc(0, 0, 320, 12),
      Rc(0, 12, 7, 160),
      Rc(313, 12, 7, 160),
      Rc(48, 150, 42, 7),
      Rc(98, 132, 42, 7),
      Rc(148, 114, 42, 7),
      Rc(198, 96, 42, 7),
      Rc(242, 78, 71, 7),
    ],
    goal: Rc(281, 61, 4, 17),
  ),
  Level(
    name: '4. МОСТ',
    echoDelay: 210,
    spawnX: 28,
    spawnY: 160,
    frameCount: 4,
    solids: [
      Rc(0, 172, 320, 8),
      Rc(0, 0, 320, 12),
      Rc(0, 12, 7, 160),
      Rc(313, 12, 7, 160),
      Rc(56, 156, 35, 7),
      Rc(104, 140, 35, 7),
      Rc(152, 156, 35, 7),
      Rc(200, 124, 35, 7),
      Rc(242, 108, 71, 7),
    ],
    goal: Rc(281, 91, 4, 17),
  ),
  Level(
    name: '5. ПРЕДАТЕЛЬ',
    echoDelay: 240,
    spawnX: 24,
    spawnY: 160,
    frameCount: 4,
    solids: [
      Rc(0, 172, 320, 8),
      Rc(0, 0, 320, 12),
      Rc(0, 12, 7, 160),
      Rc(313, 12, 7, 160),
      Rc(62, 148, 32, 7),
      Rc(108, 121, 32, 7),
      Rc(154, 148, 32, 7),
      Rc(200, 112, 32, 7),
      Rc(242, 84, 71, 7),
    ],
    goal: Rc(281, 67, 4, 17),
  ),
  Level(
    name: '6. ЯЩИК',
    echoDelay: 270,
    spawnX: 26,
    spawnY: 160,
    frameCount: 4,
    solids: [
      Rc(0, 172, 320, 8),
      Rc(0, 0, 320, 12),
      Rc(0, 12, 7, 160),
      Rc(313, 12, 7, 160),
      Rc(72, 152, 30, 7),
      Rc(116, 126, 30, 7),
      Rc(160, 152, 30, 7),
      Rc(204, 126, 30, 7),
      Rc(248, 100, 65, 7),
    ],
    goal: Rc(281, 83, 4, 17),
  ),
  Level(
    name: '7. ЧАСЫ',
    echoDelay: 270,
    spawnX: 22,
    spawnY: 160,
    frameCount: 4,
    solids: [
      Rc(0, 172, 320, 8),
      Rc(0, 0, 320, 12),
      Rc(0, 12, 7, 160),
      Rc(313, 12, 7, 160),
      Rc(48, 150, 28, 7),
      Rc(92, 130, 28, 7),
      Rc(136, 110, 28, 7),
      Rc(180, 130, 28, 7),
      Rc(224, 96, 28, 7),
      Rc(252, 72, 61, 7),
    ],
    goal: Rc(281, 55, 4, 17),
  ),
  Level(
    name: '8. КОМБО',
    echoDelay: 270,
    spawnX: 20,
    spawnY: 160,
    frameCount: 4,
    solids: [
      Rc(0, 172, 320, 8),
      Rc(0, 0, 320, 12),
      Rc(0, 12, 7, 160),
      Rc(313, 12, 7, 160),
      Rc(45, 154, 30, 7),
      Rc(88, 136, 30, 7),
      Rc(131, 118, 30, 7),
      Rc(174, 100, 30, 7),
      Rc(217, 82, 30, 7),
      Rc(250, 62, 63, 7),
    ],
    goal: Rc(281, 45, 4, 17),
  ),
  Level(
    name: '9. ТУМАН',
    echoDelay: 300,
    spawnX: 24,
    spawnY: 160,
    frameCount: 4,
    solids: [
      Rc(0, 172, 320, 8),
      Rc(0, 0, 320, 12),
      Rc(0, 12, 7, 160),
      Rc(313, 12, 7, 160),
      Rc(48, 154, 34, 7),
      Rc(96, 142, 34, 7),
      Rc(144, 130, 34, 7),
      Rc(192, 118, 34, 7),
      Rc(240, 106, 73, 7),
    ],
    goal: Rc(281, 89, 4, 17),
  ),
  Level(
    name: '10. ЭХО-СТУПЕНЬ',
    echoDelay: 330,
    spawnX: 22,
    spawnY: 160,
    frameCount: 4,
    solids: [
      Rc(0, 172, 320, 8),
      Rc(0, 0, 320, 12),
      Rc(0, 12, 7, 160),
      Rc(313, 12, 7, 160),
      Rc(62, 154, 34, 7),
      Rc(108, 154, 34, 7),
      Rc(154, 154, 34, 7),
      Rc(204, 124, 109, 7),
      Rc(248, 96, 65, 7),
    ],
    goal: Rc(281, 79, 4, 17),
  ),
  Level(
    name: '11. ФИНАЛ',
    echoDelay: 360,
    spawnX: 20,
    spawnY: 160,
    frameCount: 4,
    solids: [
      Rc(0, 172, 320, 8),
      Rc(0, 0, 320, 12),
      Rc(0, 12, 7, 160),
      Rc(313, 12, 7, 160),
      Rc(42, 154, 30, 7),
      Rc(82, 136, 30, 7),
      Rc(122, 118, 30, 7),
      Rc(162, 136, 30, 7),
      Rc(202, 110, 30, 7),
      Rc(242, 84, 71, 7),
    ],
    goal: Rc(281, 67, 4, 17),
  ),
];

class Body {
  static const double w = 6, h = 12, maxRun = 1.6;
  double x, y, vx = 0, vy = 0;
  bool onGround = false, faceRight = true;
  int coyote = 0, buffer = 0, prevInput = 0, anim = 0;
  Body(this.x, this.y);

  Rc get rect => Rc(x, y, w, h);

  void step(int input, Level lv) {
    final left = (input & inL) != 0;
    final right = (input & inR) != 0;
    final jump = (input & inJ) != 0;
    final pressed = jump && (prevInput & inJ) == 0;
    prevInput = input;

    if (left == right) {
      final f = onGround ? 0.22 : 0.05;
      if (vx.abs() <= f) {
        vx = 0;
      } else {
        vx -= f * vx.sign;
      }
    } else if (right) {
      vx = math.min(vx + (onGround ? 0.28 : 0.16), maxRun);
      faceRight = true;
    } else {
      vx = math.max(vx - (onGround ? 0.28 : 0.16), -maxRun);
      faceRight = false;
    }

    if (onGround) {
      coyote = 6;
    } else if (coyote > 0) {
      coyote--;
    }
    if (pressed) {
      buffer = 6;
    } else if (buffer > 0) {
      buffer--;
    }
    if (buffer > 0 && coyote > 0) {
      vy = -3.2;
      buffer = 0;
      coyote = 0;
      onGround = false;
    }
    if (!jump && vy < -1.2) vy = -1.2; // короткий прыжок, если отпустил
    vy = math.min(vy + 0.25, 5.0);

    x += vx;
    for (final s in lv.solids) {
      if (rect.overlaps(s)) {
        if (vx > 0) {
          x = s.x - w;
        } else if (vx < 0) {
          x = s.x + s.w;
        }
        vx = 0;
      }
    }
    y += vy;
    onGround = false;
    for (final s in lv.solids) {
      if (rect.overlaps(s)) {
        if (vy > 0) {
          y = s.y - h;
          onGround = true;
        } else if (vy < 0) {
          y = s.y + s.h;
        }

        x = x.clamp(7.0, 313.0).toDouble();
        if (y > 190) {
          y = 160;
          vy = 0;
          x = lv.spawnX;
        }
        vy = 0;
      }
    }

    if (onGround && vx.abs() > 0.3) {
      anim++;
    } else if (onGround) {
      anim = 0;
    }
  }
}

enum Status { playing, dead, won }

class Sim {
  final Level lv;
  late Body player;
  Body? echo;
  final List<int> history = [];
  final List<Rc> trail = []; // последние позиции Эха для шлейфа
  int tick = 0;
  int endTimer = 0;
  Status status = Status.playing;

  Sim(this.lv) {
    reset();
  }

  void reset() {
    player = Body(lv.spawnX, lv.spawnY);
    echo = null;
    history.clear();
    trail.clear();
    tick = 0;
    endTimer = 0;
    status = Status.playing;
  }

  void step(int input) {
    if (status != Status.playing) {
      endTimer++;
      return;
    }
    history.add(input);
    player.step(input, lv);
    if (tick == lv.echoDelay) echo = Body(lv.spawnX, lv.spawnY);
    final e = echo;
    if (e != null) {
      e.step(history[tick - lv.echoDelay], lv);
      trail.add(e.rect);
      if (trail.length > 14) trail.removeAt(0);
    }
    tick++;
    if (e != null && player.rect.shrink(1).overlaps(e.rect.shrink(1))) {
      status = Status.dead;
      endTimer = 0;
      return;
    }
    if (player.rect.overlaps(lv.goal)) {
      status = Status.won;
      endTimer = 0;
    }
  }
}
