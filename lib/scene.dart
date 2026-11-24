// Фон уровня (рисуется один раз) и динамические объекты (каждый кадр).
import 'dart:math' as math;
import 'dart:ui';

import 'art.dart';
import 'platformer_sim.dart';

/// Оттенок комнаты: (низ неба, верх неба, плита, плита-верх) на каждый уровень.
const _themes = <List<Color>>[
  [Color(0xFF1B1A3D), Color(0xFF312E63)],
  [Color(0xFF1A1F3D), Color(0xFF2B3A63)],
  [Color(0xFF241A3D), Color(0xFF42305F)],
  [Color(0xFF162B3A), Color(0xFF24506A)],
  [Color(0xFF2E1A3A), Color(0xFF5A2E63)],
  [Color(0xFF2A2236), Color(0xFF55425F)],
  [Color(0xFF14283A), Color(0xFF1F4F6F)],
  [Color(0xFF2B1F3D), Color(0xFF50306F)],
  [Color(0xFF1C2230), Color(0xFF3A4660)],
  [Color(0xFF1A1740), Color(0xFF2F2A78)],
  [Color(0xFF2A1A30), Color(0xFF6A3A55)],
];

Picture buildBackground(Level lv, int index) {
  final rec = PictureRecorder();
  final c = Canvas(rec, const Rect.fromLTWH(0, 0, 320, 180));
  final th = _themes[index % _themes.length];
  box(c, 0, 0, 320, 180, C.bg);
  // ступенчатый градиент комнаты
  for (var i = 0; i < 20; i++) {
    final col = Color.lerp(th[0], th[1], i / 19)!;
    box(c, 8, 12 + i * 8, 304, 8, col);
  }
  final rnd = math.Random(index * 97 + 3);
  // звёздочки
  for (var i = 0; i < 50; i++) {
    box(c, 10 + rnd.nextInt(300).toDouble(), 14 + rnd.nextInt(150).toDouble(),
        1, 1, C.star);
  }
  // силуэты арок/колонн на дальнем плане
  for (var i = 0; i < 6; i++) {
    final x = 20 + i * 52 + rnd.nextInt(12).toDouble();
    final h = 40 + rnd.nextInt(40).toDouble();
    box(c, x, 172 - h, 10, h, C.sil);
    box(c, x - 2, 172 - h, 14, 3, C.silEdge);
    box(c, x + 3, 172 - h + 8, 4, 8, th[0]);
  }
  // окно с дождём (рамка), как в референсе
  final wx = 190.0 + (index % 3) * 6;
  box(c, wx - 2, 15, 84, 107, C.silEdge);
  box(c, wx, 17, 80, 103, const Color(0xFF0E0D22));
  box(c, wx + 39, 17, 2, 103, C.silEdge);
  box(c, wx, 66, 80, 2, C.silEdge);
  // тайлы-стены
  for (final k in lv.solid) {
    final cc = k ~/ 100, r = k % 100;
    final x = cc * 8.0, y = yOff + r * 8.0;
    final top = !lv.solid.contains(Level.key(cc, r - 1));
    box(c, x, y, 8, 8, C.plat);
    if ((cc + r) % 2 == 0) box(c, x + 3, y + 3, 2, 2, C.platDark);
    if (top) box(c, x, y, 8, 2, C.platTop);
    box(c, x, y + 7, 8, 1, C.platDark);
  }
  // рамка комнаты
  box(c, 0, 0, 320, 12, C.frame);
  box(c, 0, 12, 8, 168, C.frame);
  box(c, 312, 12, 8, 168, C.frame);
  for (var x = 2.0; x < 320; x += 8) {
    box(c, x, 5, 2, 2, C.frameDot);
  }
  box(c, 0, 172, 320, 8, C.bg);
  return rec.endRecording();
}

const _doorA = Color(0xFFD2603C); // дверь плиты 1
const _doorB = Color(0xFF3CB4A0); // дверь плиты 2
const _lever = Color(0xFFE0B040);

Color _plateCol(int g) => g == 1 ? _doorA : _doorB;

void drawDynamic(Canvas c, Sim s, double t) {
  final lv = s.lv;
  // плиты
  for (final e in lv.plates.entries) {
    for (final p in e.value) {
      final down = s.pressed[e.key]!;
      box(c, p.x, p.y + (down ? 2 : 0), 8, down ? 1 : 3, _plateCol(e.key));
      box(c, p.x - 1, p.y + 3, 10, 1, C.platDark);
    }
  }
  // мосты
  for (final e in lv.bridges.entries) {
    final cc = e.key ~/ 100, r = e.key % 100;
    final x = cc * 8.0, y = yOff + r * 8.0;
    if (s.pressed[e.value]!) {
      box(c, x, y, 8, 3, _plateCol(e.value));
      box(c, x, y + 3, 8, 1, C.platDark);
    } else {
      box(c, x, y, 1, 1, _plateCol(e.value));
      box(c, x + 7, y, 1, 1, _plateCol(e.value));
      if ((t * 4).floor() % 2 == 0) {
        box(c, x + 3, y, 2, 1, const Color(0x88FFFFFF));
      }
    }
  }
  // двери
  for (final e in lv.doors.entries) {
    final cc = e.key ~/ 100, r = e.key % 100;
    final x = cc * 8.0, y = yOff + r * 8.0;
    final col = switch (e.value) {
      'D' => _doorA,
      'E' => _doorB,
      _ => _lever,
    };
    if (s.doorClosed(cc, r, e.value)) {
      box(c, x, y, 8, 8, col);
      box(c, x + 1, y, 1, 8, const Color(0x44FFFFFF));
      box(c, x + 6, y, 2, 8, const Color(0x55000000));
    } else {
      box(c, x, y, 1, 8, col);
      box(c, x + 7, y, 1, 8, col);
    }
  }
  // рычаг
  for (final l in lv.lever) {
    box(c, l.x + 1, l.y + 6, 6, 2, C.platDark);
    final lx = s.leverOn ? l.x + 5 : l.x + 1;
    for (var i = 0; i < 5; i++) {
      box(c, s.leverOn ? lx - i * 0.6 + 2 : lx + i * 0.6, l.y + 6 - i, 1, 1,
          _lever);
    }
    box(c, s.leverOn ? l.x + 1 : l.x + 5, l.y + 1, 2, 2, _lever);
  }
  // паромы
  for (final r in s.liftRects) {
    box(c, r.x, r.y, r.w, 4, C.platTop);
    box(c, r.x, r.y + 4, r.w, 2, C.platDark);
    box(c, r.x + 1, r.y + 6, 2, 2, _lever);
    box(c, r.x + r.w - 3, r.y + 6, 2, 2, _lever);
  }
  // ящики
  for (final cr in s.crates) {
    if (cr.fallen) continue;
    box(c, cr.x, cr.y, 16, 16, const Color(0xFF8A6A3A));
    box(c, cr.x + 1, cr.y + 1, 14, 14, const Color(0xFFA98450));
    for (var i = 0; i < 14; i++) {
      box(c, cr.x + 1 + i, cr.y + 1 + i, 1, 1, const Color(0xFF6B4F2A));
      box(c, cr.x + 14 - i, cr.y + 1 + i, 1, 1, const Color(0xFF6B4F2A));
    }
    box(c, cr.x, cr.y, 16, 1, const Color(0xFF6B4F2A));
  }
}

/// Туман: тёмная полоса поверх зоны, где шаги не записываются.
void drawFog(Canvas c, Level lv, double t) {
  if (lv.fogFrom < 0) return;
  final x0 = lv.fogFrom * 8.0, x1 = (lv.fogTo + 1) * 8.0;
  c.save();
  c.clipRect(Rect.fromLTRB(x0, 12, x1, 172));
  box(c, x0, 12, x1 - x0, 160, const Color(0x55B8B4D8));
  for (var i = 0; i < 26; i++) {
    final x = x0 + ((i * 37 + t * 9 * (i % 3 + 1)) % (x1 - x0));
    final y = 90 + (i * 53) % 80 + math.sin(t + i) * 3;
    box(c, x, y, 10 + (i % 4) * 4, 2, const Color(0x55E0DEF4));
  }
  c.restore();
}
