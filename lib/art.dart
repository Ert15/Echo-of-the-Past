// Весь пиксельный арт рисуется кодом (внутренний экран 320x180).
import 'dart:math' as math;
import 'dart:ui';

import 'sim.dart';

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

void _poly(Canvas c, List<Offset> pts, Color col) {
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final p in pts.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  path.close();
  c.drawPath(path, Paint()..color = col..isAntiAlias = false);
}

void _tiled(Canvas c, Rc r, Color base, Color dot) {
  box(c, r.x, r.y, r.w, r.h, base);
  for (var yy = 0.0; yy < r.h - 1; yy += 4) {
    for (var xx = (yy ~/ 4).isEven ? 0.0 : 2.0; xx < r.w; xx += 4) {
      box(c, r.x + xx, r.y + yy + 1, 1, 1, dot);
    }
  }
}

void _chair(Canvas c, double x, double y) {
  // y - верх спинки, стул высотой 22
  box(c, x, y, 2, 22, C.sil);
  box(c, x + 12, y, 2, 22, C.sil);
  box(c, x, y, 14, 2, C.sil);
  for (var i = 0; i < 3; i++) {
    box(c, x + 4 + i * 3, y + 2, 1, 9, C.sil);
  }
  box(c, x - 1, y + 12, 16, 2, C.sil);
}

void _table(Canvas c, double x, double yTop) {
  box(c, x, yTop, 14, 3, C.sil);
  box(c, x + 6, yTop + 3, 2, 6, C.sil);
  box(c, x + 2, yTop + 9, 10, 2, C.sil);
}

Picture buildBackground(Level lv) {
  final rec = PictureRecorder();
  final c = Canvas(rec, const Rect.fromLTWH(0, 0, 320, 180));
  box(c, 0, 0, 320, 180, C.bg);

  // обои со звёздочками
  final rnd = math.Random(7);
  for (var i = 0; i < 60; i++) {
    final x = 12 + rnd.nextInt(296).toDouble();
    final y = 16 + rnd.nextInt(150).toDouble();
    final col = i % 3 == 0 ? C.debris : C.star;
    box(c, x, y - 1, 1, 3, col);
    box(c, x - 1, y, 3, 1, col);
  }

  // клочки бумаги по краям (статичные)
  final rd = math.Random(11);
  for (var i = 0; i < 46; i++) {
    final cx = i.isEven ? 8 + rd.nextDouble() * 58 : 250 + rd.nextDouble() * 60;
    final cy = 14 + rd.nextDouble() * 150;
    final s = 3 + rd.nextDouble() * 5;
    final a = rd.nextDouble() * math.pi;
    final pts = <Offset>[];
    for (var k = 0; k < 4; k++) {
      final ang = a + k * math.pi / 2;
      final rr = s * (k.isEven ? 1.0 : 0.6);
      pts.add(Offset(cx + math.cos(ang) * rr, cy + math.sin(ang) * rr));
    }
    _poly(c, pts, i % 2 == 0 ? C.debris : C.debris2);
  }

  // окно с ночным небом
  box(c, 186, 13, 88, 111, C.silEdge);
  c.drawRect(
    const Rect.fromLTWH(190, 17, 80, 103),
    Paint()
      ..isAntiAlias = false
      ..shader = Gradient.linear(
          const Offset(0, 17), const Offset(0, 120), [C.skyTop, C.skyBot]),
  );
  box(c, 196, 38, 34, 3, C.skyTop);
  box(c, 238, 52, 26, 3, C.skyTop);
  box(c, 200, 86, 40, 3, C.skyTop);
  box(c, 228, 17, 3, 103, C.silEdge);
  box(c, 190, 66, 80, 3, C.silEdge);
  box(c, 182, 120, 96, 4, C.frame);

  // книжный шкаф слева
  box(c, 10, 96, 36, 76, C.sil);
  final rb = math.Random(5);
  for (final sy in [108.0, 124.0, 140.0, 156.0, 172.0]) {
    box(c, 10, sy - 1, 36, 1, C.silEdge);
    for (var xx = 12.0; xx < 44; xx += 3) {
      final h = 6 + rb.nextInt(6).toDouble();
      box(c, xx, sy - 1 - h, 2, h, C.debris);
    }
  }
  // рамки на стене
  for (final f in const [Offset(66, 28), Offset(160, 98), Offset(118, 40)]) {
    box(c, f.dx, f.dy, 12, 12, C.silEdge);
    box(c, f.dx + 2, f.dy + 2, 8, 8, C.sil);
    _poly(c, [Offset(f.dx + 3, f.dy + 9), Offset(f.dx + 6, f.dy + 4), Offset(f.dx + 9, f.dy + 9)], C.debris);
  }

  // люстра
  box(c, 291, 12, 1, 14, C.silEdge);
  _poly(c, const [Offset(284, 26), Offset(299, 26), Offset(306, 40), Offset(277, 40)], C.sil);
  for (var xx = 278.0; xx < 306; xx += 3) {
    box(c, xx, 41, 1, 2, C.silEdge);
  }

  // мебель
  _chair(c, 62, 150); // стул у старта
  _chair(c, 247, 111); // стул на площадке
  _poly(c, const [Offset(248, 113), Offset(262, 113), Offset(264, 128), Offset(256, 134), Offset(246, 126)], C.debris);
  _table(c, 152, 161); // столик под лесенкой
  _table(c, 184, 130); // столик на последней ступеньке
  // растение под площадкой
  box(c, 258, 160, 12, 12, C.sil);
  for (final a in [-1.0, -0.5, 0.0, 0.5, 1.0]) {
    final tx = 264 + math.sin(a) * 18, ty = 160 - math.cos(a) * 18;
    _poly(c, [Offset(263, 160), Offset(265, 160), Offset(tx + 2, ty), Offset(tx - 2, ty)], C.sil);
  }
  // табурет
  box(c, 298, 160, 14, 3, C.sil);
  box(c, 300, 163, 2, 9, C.sil);
  box(c, 308, 163, 2, 9, C.sil);

  // рамка комнаты и платформы
  for (var i = 0; i < lv.solids.length; i++) {
    final s = lv.solids[i];
    if (i < lv.frameCount) {
      _tiled(c, s, C.frame, C.frameDot);
    } else {
      _tiled(c, s, C.plat, C.platDark);
      box(c, s.x, s.y, s.w, 1, C.platTop);
      box(c, s.x, s.y + s.h - 1, s.w, 1, C.platDark);
    }
  }
  box(c, 7, 172, 306, 1, C.platTop);
  return rec.endRecording();
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
      ..shader = Gradient.radial(Offset(cx, cy), rad,
          const [Color(0x66FFC857), Color(0x00FFC857)]),
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
  if (!b.onGround) {
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
