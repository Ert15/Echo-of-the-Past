// Весь пиксельный арт рисуется кодом (внутренний экран 320x180).
import 'dart:math' as math;
import 'dart:ui';

import 'platformer_sim.dart';

class C {
  static const bg = Color(0xFF100E1C);
  static const star = Color(0xFF2A2747);
  static const frame = Color(0xFF58547A);
  static const frameDot = Color(0xFF43405F);
  static const platTop = Color(0xFF9692BC);
  static const plat = Color(0xFF625E88);
  static const platDark = Color(0xFF38355A);
  static const sil = Color(0xFF1C1A31);
  static const silEdge = Color(0xFF2B2848);
  static const debris = Color(0xFF3B3858);
  static const debris2 = Color(0xFF4C486B);
  static const skyTop = Color(0xFF1B1A3D);
  static const skyBot = Color(0xFF312E63);
  static const light = Color(0xFFFFC857);
  static const lightCore = Color(0xFFFFF1B8);
  static const player = Color(0xFFF2EEE6);
  static const playerShade = Color(0xFFB4AFC6);
  static const eye = Color(0xFF16142A);
  static const echo = Color(0xFF3F78B5);
  static const echoShade = Color(0xFF2F5F96);
  static const hint = Color(0xFF8E8AB5);
}

final Paint _p = Paint()..isAntiAlias = false;

void box(Canvas c, double x, double y, double w, double h, Color col) {
  _p.color = col;
  c.drawRect(Rect.fromLTWH(x, y, w, h), _p);
}

// ---------- динамика ----------

final List<List<double>> _amb = List.generate(70, (i) {
  final r = math.Random(i * 31 + 5);
  return [
    r.nextDouble() * 300 + 10,
    r.nextDouble() * 160 + 12,
    10 + r.nextDouble() * 40,
    i % 4 == 0 ? 1.0 : 0.0,
    r.nextDouble() * 6.28,
  ];
});

void drawAmbient(Canvas c, double t) {
  for (final a in _amb) {
    final y = 12 + (a[1] - 12 + t * a[2]) % 160;
    final x = a[0] + math.sin(t * 0.6 + a[4]) * 4;
    if (a[3] == 1.0) {
      box(c, x, y, 2, 2, const Color(0x994C486B));
    } else {
      box(c, x, y, 1, 3, const Color(0x994A78B8));
    }
  }
}

void drawWindowRain(Canvas c, double t) {
  c.save();
  c.clipRect(const Rect.fromLTWH(190, 17, 80, 103));
  for (var i = 0; i < 28; i++) {
    final x = 190 + (i * 7 + t * 18) % 80;
    final y = 17 + (i * 13 + t * 70) % 103;
    box(c, x, y, 1, 3, const Color(0x8890B8E8));
    box(c, x - 1, y + 3, 1, 1, const Color(0x6690B8E8));
  }
  c.restore();
}

void drawGoal(Canvas c, Rc g, double t) {
  final cx = g.x + g.w / 2, cy = g.y + g.h * 0.6;
  final rad = 58 + math.sin(t * 3) * 3;
  c.drawCircle(
    Offset(cx, cy),
    rad,
    Paint()
      ..isAntiAlias = false
      ..shader = Gradient.radial(
          Offset(cx, cy), rad, const [Color(0x66FFC857), Color(0x00FFC857)]),
  );
  box(c, g.x, g.y, g.w, g.h, C.light);
  box(c, g.x + 1, g.y, g.w - 2, g.h, C.lightCore);
  final f = (t * 12).floor() % 3;
  box(c, g.x - 1, g.y + g.h - 3 - f, g.w + 2, 3.0 + f, C.light);
  for (var i = 0; i < 6; i++) {
    final yy = g.y + g.h - ((t * 14 + i * 5) % 18);
    box(c, g.x + 1 + math.sin(t * 2 + i) * 2, yy, 1, 1, C.lightCore);
  }
}

// ---------- спрайты 8x12 ----------

const _bodyOpen = [
  '...WW...',
  '..WWWW..',
  '.WWWWWW.',
  '.WKWWKW.',
  '.WWWWWW.',
  '..WWWW..',
  '.SWWWWS.',
  '.WWWWWW.',
  '.WWWWWW.',
];
const _bodyBlink = [
  '...WW...',
  '..WWWW..',
  '.WWWWWW.',
  '.WSWWSW.',
  '.WWWWWW.',
  '..WWWW..',
  '.SWWWWS.',
  '.WWWWWW.',
  '.WWWWWW.',
];
const legsStand = ['..W..W..', '..W..W..', '..W..W..'];
const _legsRun = [
  ['..W..W..', '..W..W..', '..W...W.'],
  legsStand,
  ['..W..W..', '..W..W..', '.W...W..'],
  legsStand,
];
const _legsJump = ['..WWWW..', '..W..W..', '........'];
const _legsFall = ['..W..W..', '.W....W.', '........'];

List<String> spriteFrame(Body b, int tick) {
  final body = (tick % 170) < 6 ? _bodyBlink : _bodyOpen;
  List<String> legs;
  if (!b.g) {
    legs = b.vy < 0 ? _legsJump : _legsFall;
  } else if (b.vx.abs() > 0.3) {
    legs = _legsRun[(b.anim ~/ 5) % 4];
  } else {
    legs = legsStand;
  }
  return [...body, ...legs];
}

List<String> standFrame() => [..._bodyOpen, ...legsStand];

void drawSprite(Canvas c, double x, double y, List<String> rows, bool flip,
    Color main, Color shade, Color eye) {
  for (var r = 0; r < rows.length; r++) {
    final row = rows[r];
    for (var k = 0; k < row.length; k++) {
      final ch = row[flip ? row.length - 1 - k : k];
      if (ch == '.') continue;
      box(c, x + k, y + r, 1, 1, ch == 'W' ? main : (ch == 'S' ? shade : eye));
    }
  }
}
