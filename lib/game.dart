import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'art.dart';
import 'sim.dart';

class EchoGame extends FlameGame {
  Sim sim = Sim(levels[0]);
  int levelIndex = 0;
  int keys = 0; // клавиатура
  int touch = 0; // экранные кнопки
  double _acc = 0, _t = 0;
  late final Picture _bg;

  @override
  Future<void> onLoad() async {
    _bg = buildBackground(level1);
  }

  void restart() => sim.reset();

  void nextLevel() {
    if (levelIndex >= levels.length - 1) {
      levelIndex = 0;
    } else {
      levelIndex++;
    }
    sim = Sim(levels[levelIndex]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _acc = math.min(_acc + dt, 0.1);
    while (_acc >= tickDt) {
      _acc -= tickDt;
      sim.step(keys | touch);
      if (sim.status == Status.dead && sim.endTimer > 40) sim.reset();
      if (sim.status == Status.won && sim.endTimer > 120) nextLevel();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = C.bg);
    var s = math.min(size.x / 320, size.y / 180);
    if (s >= 1) s = s.floorToDouble();
    canvas.save();
    canvas.translate(((size.x - 320 * s) / 2).floorToDouble(),
        ((size.y - 180 * s) / 2).floorToDouble());
    canvas.scale(s);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 320, 180));

    canvas.drawPicture(_bg);
    drawWindowRain(canvas, _t);
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(7, 12, 306, 160));
    drawAmbient(canvas, _t);
    canvas.restore();
    drawGoal(canvas, sim.lv.goal, _t);
    _drawEcho(canvas);
    _drawBody(canvas, sim.player, false);
    _drawHud(canvas);
    canvas.restore();
  }

  void _drawBody(Canvas c, Body b, bool isEcho) {
    drawSprite(
      c,
      b.x.roundToDouble() - 1,
      b.y.roundToDouble(),
      spriteFrame(b, sim.tick),
      !b.faceRight,
      isEcho ? C.echo : C.player,
      isEcho ? C.echoShade : C.playerShade,
      isEcho ? C.echo : C.eye,
    );
  }

  void _drawEcho(Canvas c) {
    // момент появления: расходящееся кольцо на старте
    final since = sim.tick - sim.lv.echoDelay;
    if (since >= 0 && since < 24) {
      c.drawCircle(
        Offset(sim.lv.spawnX + 3, sim.lv.spawnY + 6),
        4 + since * 0.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..isAntiAlias = false
          ..color = Color.fromARGB(200 - since * 8, 63, 120, 181),
      );
    }
    final tr = sim.trail;
    const faint = [Color(0x333F78B5), Color(0x223F78B5)];
    var n = 0;
    for (final k in [5, 10]) {
      final i = tr.length - 1 - k;
      if (i >= 0) {
        drawSprite(c, tr[i].x.roundToDouble() - 1, tr[i].y.roundToDouble(),
            standFrame(), false, faint[n], faint[n], faint[n]);
      }
      n++;
    }
    final e = sim.echo;
    if (e != null) _drawBody(c, e, true);
  }

  void _text(Canvas c, String s, double x, double y,
      {Color color = C.player,
      double size = 7,
      bool center = false,
      bool right = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
            color: color,
            fontSize: size,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            height: 1.0),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? x - tp.width / 2 : (right ? x - tp.width : x);
    tp.paint(c, Offset(dx, y));
  }

  void _drawHud(Canvas c) {
    final left = sim.lv.echoDelay - sim.tick;
    _text(
        c,
        left > 0
            ? 'ЭХО ЧЕРЕЗ ${(left / 60).toStringAsFixed(1)}'
            : 'ЭХО ИДЁТ ЗА ТОБОЙ',
        10,
        3,
        color: left > 0 ? C.player : const Color(0xFF7FB2F0));
    _text(c, sim.lv.name, 310, 3, right: true);
    _text(
        c,
        'A / ← назад    D / → вперёд    W / ↑ / ПРОБЕЛ — прыжок',
        160,
        15,
        size: 6,
        color: C.hint,
        center: true);

    if (sim.status == Status.dead) {
      final a = math.max(0.0, 1 - sim.endTimer / 40);
      c.drawRect(const Rect.fromLTWH(0, 0, 320, 180),
          Paint()..color = Color.fromARGB((a * 130).toInt(), 255, 70, 70));
      _text(c, 'СТОЛКНОВЕНИЕ С ЭХОМ', 160, 84, center: true, size: 9);
    } else if (sim.status == Status.won) {
      c.drawRect(const Rect.fromLTWH(60, 70, 200, 40),
          Paint()..color = const Color(0xCC100E1C));
      _text(c, 'СВЕТ ЗАЖЖЁН', 160, 78,
          center: true, size: 10, color: C.light);
      _text(c, 'R — ещё раз', 160, 94, center: true, size: 7, color: C.hint);
    }
  }
}
