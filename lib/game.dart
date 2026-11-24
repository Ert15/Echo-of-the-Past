import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'art.dart';
import 'audio.dart';
import 'platformer_levels.dart';
import 'scene.dart';
import 'platformer_sim.dart';

class EchoGame extends FlameGame {
  EchoGame({int startLevel = 0})
      : levelIndex = startLevel,
        sim = Sim(levels[startLevel]) {
    _fx.reset(sim);
  }

  int levelIndex;
  Sim sim;
  int keys = 0; // клавиатура
  int touch = 0; // экранные кнопки
  @override
  bool paused = false;
  bool showHints = true;
  void Function(int levelIndex)? onLevelWon;
  final GameSfx _fx = GameSfx();
  double _acc = 0, _t = 0;
  late Picture _bg;
  final List<List<Offset>> _trail = [[], []];

  @override
  Future<void> onLoad() async {
    _bg = buildBackground(sim.lv, levelIndex);
    _fx.reset(sim);
    Sfx.levelStart();
  }

  void restart() {
    sim.reset();
    _fx.reset(sim);
    Sfx.levelStart();
    for (final trail in _trail) {
      trail.clear();
    }
  }

  void goTo(int i) {
    levelIndex = i.clamp(0, levels.length - 1);
    sim = Sim(levels[levelIndex]);
    _fx.reset(sim);
    Sfx.levelStart();
    _bg = buildBackground(sim.lv, levelIndex);
    for (final trail in _trail) {
      trail.clear();
    }
  }

  /// Enter/кнопка: после победы — дальше, иначе заново.
  void confirm() {
    if (sim.status == Status.won && levelIndex < levels.length - 1) {
      goTo(levelIndex + 1);
    } else if (sim.status == Status.won) {
      goTo(0);
    } else {
      restart();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (paused) return;
    _t += dt;
    _acc = math.min(_acc + dt, 0.1);
    while (_acc >= tickDt) {
      _acc -= tickDt;
      final previousStatus = sim.status;
      sim.step(keys | touch);
      _fx.observe(sim);
      for (var i = 0; i < sim.echoes.length && i < 2; i++) {
        final e = sim.echoes[i];
        if (e != null) {
          _trail[i].add(Offset(e.x, e.y));
          if (_trail[i].length > 12) _trail[i].removeAt(0);
        }
      }
      if (previousStatus != Status.won && sim.status == Status.won) {
        onLevelWon?.call(levelIndex);
      }
      if (sim.status == Status.dead && sim.endTimer > 40) restart();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = C.bg);
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
    drawDynamic(canvas, sim, _t);
    _drawEchoes(canvas);
    _drawBody(canvas, sim.player, false);
    drawFog(canvas, sim.lv, _t);
    _drawHud(canvas);
    canvas.restore();
  }

  void _drawBody(Canvas c, Body b, bool isEcho) {
    drawSprite(
      c,
      b.x.roundToDouble() - 1,
      b.y.roundToDouble(),
      spriteFrame(b, sim.tick),
      !b.face,
      isEcho ? C.echo : C.player,
      isEcho ? C.echoShade : C.playerShade,
      isEcho ? C.echo : C.eye,
    );
  }

  void _drawEchoes(Canvas c) {
    final lv = sim.lv;
    for (var i = 0; i < lv.delays.length; i++) {
      final since = sim.tick - lv.delays[i];
      if (since >= 0 && since < 24) {
        c.drawCircle(
          Offset(lv.spawnX + 3, lv.spawnY + 6),
          4 + since * 0.6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..isAntiAlias = false
            ..color = Color.fromARGB(200 - since * 8, 63, 120, 181),
        );
      }
      if (i < 2) {
        const faint = [Color(0x333F78B5), Color(0x223F78B5)];
        var n = 0;
        for (final k in [4, 9]) {
          final idx = _trail[i].length - 1 - k;
          if (idx >= 0 && sim.echoes[i] != null) {
            drawSprite(
                c,
                _trail[i][idx].dx.roundToDouble() - 1,
                _trail[i][idx].dy.roundToDouble(),
                standFrame(),
                false,
                faint[n],
                faint[n],
                faint[n]);
          }
          n++;
        }
      }
      final e = sim.echoes[i];
      if (e != null && !e.fallen) _drawBody(c, e, true);
    }
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
    final first = sim.lv.delays.first;
    final left = first - sim.tick;
    _text(
        c,
        left > 0
            ? 'ЭХО ЧЕРЕЗ ${(left / 60).toStringAsFixed(1)}'
            : (sim.lv.delays.length > 1
                ? 'ЭХО ИДУТ ЗА ТОБОЙ'
                : 'ЭХО ИДЁТ ЗА ТОБОЙ'),
        10,
        3,
        color: left > 0 ? C.player : const Color(0xFF7FB2F0));
    _text(c, sim.lv.name, 310, 3, right: true);
    if (showHints) {
      _text(c, sim.lv.hint, 160, 15, size: 6, color: C.hint, center: true);
    }
    _text(c, 'R — заново   A/D — идти   Пробел — прыжок', 160, 173,
        size: 6, color: C.hint, center: true);

    if (sim.status == Status.dead) {
      final a = math.max(0.0, 1 - sim.endTimer / 40);
      c.drawRect(const Rect.fromLTWH(0, 0, 320, 180),
          Paint()..color = Color.fromARGB((a * 130).toInt(), 255, 70, 70));
      _text(c, 'ЭХО ТЕБЯ НАШЛО', 160, 84, center: true, size: 9);
    } else if (sim.status == Status.won) {
      c.drawRect(const Rect.fromLTWH(60, 70, 200, 40),
          Paint()..color = const Color(0xCC100E1C));
      final last = levelIndex == levels.length - 1;
      _text(c, last ? 'ВСЕ СВЕТЫ ЗАЖЖЕНЫ' : 'СВЕТ ЗАЖЖЁН', 160, 78,
          center: true, size: 10, color: C.light);
      _text(c, last ? 'Enter — сначала' : 'Enter — дальше', 160, 94,
          center: true, size: 7, color: C.hint);
    }
  }
}
