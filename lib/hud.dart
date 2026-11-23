import 'package:flutter/material.dart';

import 'board.dart';
import 'echo_game.dart';
import 'joystick.dart';

/// Горизонтальный интерфейс: джойстик слева, кнопки справа, подсказка сверху.
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});
  final EchoGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.ui,
      builder: (context, _, __) {
        final b = game.board;
        final playing = b.status == Status.playing;
        final echoText = b.echo == null
            ? 'Эхо через ${b.level.delay - b.turn} ход.'
            : 'Эхо идёт за тобой (${b.level.delay} ход. позади)';
        return SafeArea(
          child: Stack(
            children: [
              // Верх: название, подсказка, счётчик
              Positioned(
                top: 4,
                left: 150,
                right: 150,
                child: Column(
                  children: [
                    Text('${game.level.name}  ·  ход ${b.turn}  ·  $echoText',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(game.level.hint,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              // Низ слева: джойстик
              Positioned(
                left: 12,
                bottom: 12,
                child: Opacity(
                  opacity: playing ? 1 : 0.4,
                  child: IgnorePointer(
                    ignoring: !playing,
                    child: Joystick(onMove: game.move, size: 140),
                  ),
                ),
              ),
              // Низ справа: Ждать + Отмена + Заново
              Positioned(
                right: 12,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Отмена хода (Z)',
                          onPressed: b.canUndo ? game.undo : null,
                          icon: const Icon(Icons.undo),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Заново (R)',
                          onPressed: game.restart,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          icon: Icons.hourglass_empty,
                          label: 'Ждать',
                          onPressed:
                              playing ? () => game.move(Move.wait) : null,
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.keyboard_double_arrow_up,
                          label: 'Прыжок',
                          onPressed:
                              playing ? () => game.move(Move.jump) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Центр: результат
              if (!playing)
                Align(
                  alignment: const Alignment(0, 0.25),
                  child: b.status == Status.lost
                      ? const _Banner(
                          'Столкновение с Эхом! Нажми «Отмена» или «Заново».',
                          Colors.redAccent)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Banner(
                                game.hasNext
                                    ? 'Костёр зажжён!'
                                    : 'Бета пройдена! Спасибо за игру.',
                                Colors.orangeAccent),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: game.next,
                              child: Text(game.hasNext ? 'Дальше' : 'Сначала'),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 84,
        height: 84,
        child: FilledButton(
          style: FilledButton.styleFrom(
              shape: const CircleBorder(), padding: EdgeInsets.zero),
          onPressed: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
}

class _Banner extends StatelessWidget {
  const _Banner(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: TextStyle(color: color)),
      );
}
