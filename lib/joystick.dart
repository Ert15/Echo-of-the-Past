import 'dart:async';

import 'package:flutter/material.dart';

import 'board.dart';

/// Виртуальный джойстик. Игра пошаговая, поэтому:
/// наклон в сторону = один ход, удержание = ход каждые ~0.26 сек.
class Joystick extends StatefulWidget {
  const Joystick({super.key, required this.onMove, this.size = 140});
  final void Function(Move) onMove;
  final double size;

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  static const _repeat = Duration(milliseconds: 260);
  Offset _knob = Offset.zero;
  Move? _dir;
  Timer? _timer;

  void _update(Offset local) {
    final r = widget.size / 2;
    var d = local - Offset(r, r);
    final maxLen = r * 0.6;
    if (d.distance > maxLen) d = d / d.distance * maxLen;

    Move? dir;
    if (d.distance > maxLen * 0.55) {
      dir = d.dx.abs() > d.dy.abs()
          ? (d.dx > 0 ? Move.right : Move.left)
          : (d.dy > 0 ? Move.down : Move.up);
    }
    setState(() => _knob = d);

    if (dir != _dir) {
      _dir = dir;
      _timer?.cancel();
      if (dir != null) {
        widget.onMove(dir);
        _timer = Timer.periodic(_repeat, (_) {
          final cur = _dir;
          if (cur != null) widget.onMove(cur);
        });
      }
    }
  }

  void _end() {
    _timer?.cancel();
    _dir = null;
    setState(() => _knob = Offset.zero);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _update(e.localPosition),
      onPointerMove: (e) => _update(e.localPosition),
      onPointerUp: (_) => _end(),
      onPointerCancel: (_) => _end(),
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white30, width: 2),
              ),
            ),
            Transform.translate(
              offset: _knob,
              child: Container(
                width: s * 0.42,
                height: s * 0.42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _dir == null ? Colors.white38 : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
