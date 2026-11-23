import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'board.dart';
import 'levels.dart';

class EchoGame extends FlameGame with KeyboardEvents {
  static const _campfireGradient = RadialGradient(
    colors: [Color(0x55FFB347), Color(0x1AFF7A18), Color(0x00000000)],
  );

  int levelIndex = 0;
  Board board = Board(levels[0]);

  /// Дёргаем, чтобы HUD перерисовался.
  final ValueNotifier<int> ui = ValueNotifier<int>(0);
  Pos? _previousPresent;
  Pos? _previousEcho;
  double _animation = 1;
  void _changed() => ui.value++;

  LevelData get level => levels[levelIndex];
  bool get hasNext => levelIndex < levels.length - 1;

  void move(Move m) {
    _previousPresent = board.present;
    _previousEcho = board.echo;
    board.act(m);
    _animation = 0;
    _changed();
  }

  void undo() {
    _previousPresent = board.present;
    _previousEcho = board.echo;
    board.undo();
    _animation = 0;
    _changed();
  }

  void restart() {
    board = Board(levels[levelIndex]);
    _previousPresent = null;
    _previousEcho = null;
    _animation = 1;
    _changed();
  }

  void next() {
    levelIndex = hasNext ? levelIndex + 1 : 0;
    restart();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_animation < 1) {
      _animation = math.min(1, _animation + dt / 0.2);
    }
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      move(Move.left);
    } else if (k == LogicalKeyboardKey.arrowRight ||
        k == LogicalKeyboardKey.keyD) {
      move(Move.right);
    } else if (k == LogicalKeyboardKey.arrowUp ||
        k == LogicalKeyboardKey.keyW) {
      move(Move.up);
    } else if (k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.keyS) {
      move(Move.down);
    } else if (k == LogicalKeyboardKey.space) {
      move(Move.wait);
    } else if (k == LogicalKeyboardKey.keyJ) {
      move(Move.jump);
    } else if (k == LogicalKeyboardKey.keyZ) {
      undo();
    } else if (k == LogicalKeyboardKey.keyR) {
      restart();
    } else if (k == LogicalKeyboardKey.enter && board.status == Status.won) {
      next();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ---------- Отрисовка ----------

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final b = board;
    _drawBackground(canvas);
    const top = 76.0, bottom = 8.0, side = 150.0;
    final availW = math.max(40.0, size.x - 2 * side);
    final availH = math.max(40.0, size.y - top - bottom);
    final cell = math.max(
        10.0,
        math
            .min(math.min(availW / b.width, availH / b.height), 64.0)
            .floorToDouble());
    final w = cell * b.width, h = cell * b.height;
    final ox = (size.x - w) / 2;
    final oy = top + (availH - h) / 2;

    final boardRect = Rect.fromLTWH(ox, oy, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.inflate(8), const Radius.circular(16)),
      Paint()
        ..color = const Color(0x55201D3B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(10)),
      Paint()..color = const Color(0xCC14121F),
    );

    Rect cellRect(int x, int y) =>
        Rect.fromLTWH(ox + x * cell, oy + y * cell, cell, cell);

    for (var y = 0; y < b.height; y++) {
      for (var x = 0; x < b.width; x++) {
        if (b.tileAt(x, y) == Tile.bonfire) {
          _drawCampfireGlow(canvas, cellRect(x, y));
        }
        _drawTile(canvas, b.tileAt(x, y), cellRect(x, y), b.plateActive);
      }
    }
    for (final crate in b.crates) {
      final r = cellRect(crate.x, crate.y).deflate(cell * 0.06);
      _drawClayCrate(canvas, r);
    }

    _drawEchoPreview(canvas, b, cellRect);
    final e = b.echo;
    if (e != null) {
      final old = _previousEcho;
      _drawSpirit(canvas, _animatedRect(cellRect, old, e), ghost: true);
    }
    _drawSpirit(canvas, _animatedRect(cellRect, _previousPresent, b.present),
        ghost: false);
  }

  void _drawBackground(Canvas canvas) {
    final bounds = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()..isAntiAlias = false;
    canvas.drawRect(bounds, paint..color = const Color(0xFF171522));
    paint.color = const Color(0xFF242334);
    for (var i = 0; i < 12; i++) {
      final x = i * size.x / 11 - 18;
      final h = 35.0 + (i % 4) * 25;
      canvas.drawRect(Rect.fromLTWH(x, size.y * .72 - h, 38, h), paint);
      canvas.drawRect(
          Rect.fromLTWH(x + 7, size.y * .72 - h - 9, 24, 9), paint);
    }
    paint.color = const Color(0xFF302E40);
    for (var i = 0; i < 30; i++) {
      final x = (i * 71.0 + 13) % math.max(size.x, 1);
      final y = (i * 37.0 + 11) % math.max(size.y * .64, 1);
      canvas.drawRect(Rect.fromLTWH(x, y, i.isEven ? 4 : 2, 3), paint);
    }
    paint.color = const Color(0xFF3D394C);
    for (var i = 0; i < 5; i++) {
      final x = i * size.x / 4 - 20;
      canvas.drawRect(Rect.fromLTWH(x, size.y * .84, 74, 7), paint);
      canvas.drawRect(Rect.fromLTWH(x + 15, size.y * .84 + 7, 42, 8), paint);
    }
  }

  void _drawCampfireGlow(Canvas canvas, Rect r) {
    final center = Offset(r.center.dx, r.bottom - r.height * 0.3);
    final glow = Rect.fromCircle(center: center, radius: r.width * 2.7);
    canvas.drawCircle(
      center,
      r.width * 2.7,
      Paint()
        ..shader = _campfireGradient.createShader(glow),
    );
  }

  void _drawClayCrate(Canvas c, Rect r) {
    final shape = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.14));
    c.drawRRect(
        shape,
        Paint()
          ..color = const Color(0xFFC98B5A)
          ..isAntiAlias = false);
    c.drawRRect(
      shape,
      Paint()
        ..color = const Color(0x663B3A52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final grain = Paint()
      ..color = const Color(0x445C342A)
      ..strokeWidth = 1.4;
    c.drawLine(r.topLeft + Offset(r.width * .15, r.height * .25),
        r.bottomRight - Offset(r.width * .15, r.height * .25), grain);
    c.drawLine(r.topRight + Offset(-r.width * .15, r.height * .25),
        r.bottomLeft + Offset(r.width * .15, -r.height * .25), grain);
  }

  Rect _animatedRect(Rect Function(int, int) cellRect, Pos? old, Pos current) {
    if (old == null || _animation >= 1) return cellRect(current.x, current.y);
    final x = old.x + (current.x - old.x) * _animation;
    final y = old.y + (current.y - old.y) * _animation;
    return cellRect(0, 0).shift(Offset(
      x * cellRect(1, 0).width,
      y * cellRect(0, 1).height,
    ));
  }

  void _drawEchoPreview(
      Canvas canvas, Board b, Rect Function(int, int) cellRect) {
    final paint = Paint()
      ..color = const Color(0x887B9CFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final preview = b.echoPreview();
    for (var i = 0; i < preview.length; i++) {
      final p = preview[i];
      final r = cellRect(p.x, p.y).deflate(cellRect(p.x, p.y).width * 0.22);
      canvas.drawRect(r, paint);
      final text = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Color(0xCCB7C7FF),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, r.topLeft + const Offset(3, 2));
    }
  }

  void _drawTile(Canvas c, Tile t, Rect r, bool active) {
    final p = Paint();
    switch (t) {
      case Tile.air:
        break;
      case Tile.wall:
        final wall = r.deflate(1);
        c.drawRect(
          wall,
          Paint()
            ..color = const Color(0xFF3B3A52)
            ..isAntiAlias = false,
        );
        c.drawRect(
          Rect.fromLTWH(wall.left + 2, wall.top + 2, wall.width - 4, 3),
          Paint()
            ..color = const Color(0x554F4E68),
        );
      case Tile.ladder:
        p
          ..color = const Color(0xFF9C6B3C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2, r.width * 0.08);
        final l = r.left + r.width * 0.28, rr = r.left + r.width * 0.72;
        c.drawLine(Offset(l, r.top), Offset(l, r.bottom), p);
        c.drawLine(Offset(rr, r.top), Offset(rr, r.bottom), p);
        for (var i = 1; i <= 3; i++) {
          final y = r.top + r.height * i / 4;
          c.drawLine(Offset(l, y), Offset(rr, y), p);
        }
      case Tile.plate:
        p.color = active ? const Color(0xFFFFB02E) : const Color(0xFF7A5A1A);
        c.drawRect(
            Rect.fromLTWH(r.left + r.width * 0.1, r.bottom - r.height * 0.14,
                r.width * 0.8, r.height * 0.14),
            p);
      case Tile.plate2:
        p.color = active ? const Color(0xFFFFB02E) : const Color(0xFF7A5A1A);
        c.drawCircle(r.center, r.width * 0.25, p);
      case Tile.door:
        final d = Rect.fromLTRB(
            r.left + r.width * 0.2, r.top, r.right - r.width * 0.2, r.bottom);
        if (!active) {
          p.color = const Color(0xFFB04BD8);
          c.drawRect(d, p);
        } else {
          p
            ..color = const Color(0x66B04BD8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          c.drawRect(d, p);
        }
      case Tile.gate:
        p
          ..color =
              board.clockOpen
                  ? const Color(0xFFB04BD8)
                  : const Color(0x664B3A66)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        c.drawLine(r.topLeft, r.bottomLeft, p);
        c.drawLine(r.topRight, r.bottomRight, p);
      case Tile.fog:
        c.drawRRect(
          RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(8)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0x995B4B8A), Color(0x445B4B8A)],
            ).createShader(r),
        );
      case Tile.platform:
        if (active) {
          p.color = const Color(0xFF4BD8D0);
          c.drawRect(r.deflate(0.5), p);
        } else {
          p
            ..color = const Color(0x444BD8D0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          c.drawRect(r.deflate(2), p);
        }
      case Tile.bonfire:
        final center = Offset(r.center.dx, r.bottom - r.height * 0.32);
        p
          ..color = const Color(0xFFFF7A18)
          ..isAntiAlias = false;
        c.drawRect(
            Rect.fromCenter(
                center: center,
                width: r.width * .42,
                height: r.height * .4),
            p);
        p.color = const Color(0xFFFFE066);
        c.drawRect(
            Rect.fromCenter(
                center: center.translate(0, r.height * .02),
                width: r.width * .18,
                height: r.height * .22),
            p);
      case Tile.lever:
        p.color = const Color(0xFFFF6B8B);
        c.drawCircle(
            Offset(r.center.dx, r.bottom - r.height * 0.2), r.width * 0.18, p);
        c.drawLine(Offset(r.center.dx, r.bottom - r.height * 0.2),
            Offset(r.center.dx + r.width * 0.2, r.top + r.height * 0.25), p);
      case Tile.crate:
        p.color = const Color(0xFFC98B5A);
        c.drawRRect(
            RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(5)), p);
        p
          ..color = const Color(0x663B3A52)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        c.drawLine(r.topLeft, r.bottomRight, p);
        c.drawLine(r.topRight, r.bottomLeft, p);
    }
  }

  void _drawSpirit(Canvas c, Rect r, {required bool ghost}) {
    final body = r.deflate(r.width * 0.15);
    final glow = Rect.fromCircle(center: body.center, radius: body.width * .7);
    c.drawCircle(
      body.center,
      body.width * .7,
      Paint()
        ..shader = RadialGradient(
          colors: ghost
              ? const [Color(0x447B9CFF), Color(0x007B9CFF)]
              : const [Color(0x55FFB347), Color(0x00FFB347)],
        ).createShader(glow),
    );
    final pixelBody = Rect.fromLTWH(
        body.left + body.width * .08,
        body.top + body.height * .1,
        body.width * .84,
        body.height * .82);
    final bodyPaint = Paint()
      ..color = ghost ? const Color(0x997B9CFF) : const Color(0xFFFFF1D6)
      ..isAntiAlias = false;
    c.drawRect(pixelBody, bodyPaint);
    c.drawRect(
      Rect.fromLTWH(
          pixelBody.left + 4, pixelBody.top - 3, pixelBody.width - 8, 4),
      bodyPaint,
    );
    final eye = Paint()..color = const Color(0xFF14121F);
    final ey = pixelBody.top + pixelBody.height * 0.38;
    final eyeSize = math.max(2.0, body.width * 0.09);
    c.drawRect(
        Rect.fromLTWH(pixelBody.left + pixelBody.width * .28, ey, eyeSize,
            eyeSize),
        eye);
    c.drawRect(
        Rect.fromLTWH(pixelBody.left + pixelBody.width * .64, ey, eyeSize,
            eyeSize),
        eye);
  }
}
