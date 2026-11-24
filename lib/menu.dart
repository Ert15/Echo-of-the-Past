// Echo of the Past — только меню (без игры). Один файл, зависит только от flutter.
// Положи в lib/menu.dart. Подключение — см. пример в конце файла.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';

// ---------- палитра (как в игре) ----------
class MC {
  static const bg = Color(0xFF100E1C);
  static const panel = Color(0xFF1B1A3D);
  static const panelHi = Color(0xFF312E63);
  static const frame = Color(0xFF58547A);
  static const text = Color(0xFFF2EEE6);
  static const hint = Color(0xFF8E8AB5);
  static const light = Color(0xFFFFC857);
  static const echo = Color(0xFF3F78B5);
}

// ---------- настройки и прогресс (меняй/сохраняй как хочешь) ----------
class MenuState extends ChangeNotifier {
  MenuState(
      {this.unlocked = 1,
      this.music = true,
      this.sfx = true,
      this.hints = true});

  int unlocked; // сколько уровней открыто (1 = только первый)
  bool music, sfx, hints;

  void unlockUpTo(int levelCount) {
    if (levelCount > unlocked) {
      unlocked = levelCount;
      notifyListeners(); // TODO: сохранить (shared_preferences)
    }
  }

  Future<void> toggleMusic() async {
    music = !music;
    notifyListeners();
    await Sfx.setMusicEnabled(music);
  }

  Future<void> toggleSfx() async {
    sfx = !sfx;
    notifyListeners();
    await Sfx.setEffectsEnabled(sfx);
  }

  void toggleHints() {
    hints = !hints;
    notifyListeners();
  }
}

// ---------- пиксельные кнопка и панель ----------
class PixelButton extends StatefulWidget {
  const PixelButton(this.label,
      {super.key,
      required this.onTap,
      this.width = 220,
      this.enabled = true,
      this.accent = false});
  final String label;
  final FutureOr<void> Function() onTap;
  final double width;
  final bool enabled, accent;
  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false, _hover = false;
  Future<void> _handleTap() async {
    Sfx.click();
    final musicStart = Sfx.startMusic();
    await widget.onTap();
    await musicStart;
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    final hi = on && (_hover || _down);
    final border = !on
        ? MC.panelHi
        : (widget.accent ? MC.light : (hi ? MC.text : MC.frame));
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hover = true);
        Sfx.hover();
      },
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: on ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: on ? _handleTap : null,
        child: Transform.translate(
          offset: Offset(0, _down ? 2 : 0),
          child: Container(
            width: widget.width,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: hi ? MC.panelHi : MC.panel,
              border: Border.all(color: border, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .5),
                  offset: Offset(0, _down ? 1 : 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(widget.label,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 2,
                    color: !on
                        ? MC.hint.withValues(alpha: .4)
                        : (widget.accent ? MC.light : MC.text))),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.t, {this.size = 30});
  final String t;
  final double size;
  @override
  Widget build(BuildContext context) => Text(t,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: size,
          letterSpacing: 4,
          color: MC.text,
          shadows: const [Shadow(color: MC.echo, offset: Offset(3, 3))]));
}

/// Фон меню: тёмная комната, падающий «дождь» и золотой столб света.
class MenuBackground extends StatefulWidget {
  const MenuBackground({super.key, required this.child});
  final Widget child;
  @override
  State<MenuBackground> createState() => _MenuBackgroundState();
}

class _MenuBackgroundState extends State<MenuBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 10))
        ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: MC.bg),
        AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(painter: _BgPainter(_c.value))),
        widget.child,
      ]);
}

class _BgPainter extends CustomPainter {
  _BgPainter(this.t);
  final double t;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..isAntiAlias = false;
    p.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [MC.panel, MC.bg]).createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, p);
    p.shader = null;
    // столб света
    final lx = s.width * .82;
    p.color = const Color(0x22FFC857);
    c.drawRect(Rect.fromLTWH(lx - 18, 0, 36, s.height), p);
    p.color = MC.light;
    c.drawRect(Rect.fromLTWH(lx - 3, 0, 6, s.height), p);
    // дождь / пылинки
    for (var i = 0; i < 60; i++) {
      final x = (i * 53.0) % s.width;
      final y = ((i * 97.0) + t * s.height * (1 + i % 3)) % s.height;
      p.color = i % 4 == 0 ? const Color(0x99C0BCE0) : const Color(0x884A78B8);
      c.drawRect(Rect.fromLTWH(x, y, 2, i % 4 == 0 ? 2 : 6), p);
    }
    // пол
    p.color = const Color(0xFF38355A);
    c.drawRect(Rect.fromLTWH(0, s.height - 24, s.width, 24), p);
    p.color = const Color(0xFF9692BC);
    c.drawRect(Rect.fromLTWH(0, s.height - 24, s.width, 3), p);
  }

  @override
  bool shouldRepaint(_BgPainter o) => o.t != t;
}

// ---------- экраны ----------

/// Главное меню. Всё, что нужно игре, приходит колбэками.
class MainMenu extends StatelessWidget {
  const MainMenu(
      {super.key,
      required this.state,
      required this.levelNames,
      required this.onPlay});
  final MenuState state;
  final List<String> levelNames;
  final void Function(int levelIndex) onPlay; // запусти игру с этого уровня

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MC.bg,
      body: MenuBackground(
        child: Center(
          child: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: state,
              builder: (_, __) =>
                  Column(mainAxisSize: MainAxisSize.min, children: [
                const _Title('ECHO OF\nTHE PAST'),
                const SizedBox(height: 6),
                const Text('иди на свет. не встреть своё эхо',
                    style: TextStyle(
                        fontFamily: 'monospace', color: MC.hint, fontSize: 12)),
                const SizedBox(height: 22),
                PixelButton(state.unlocked > 1 ? 'ПРОДОЛЖИТЬ' : 'ИГРАТЬ',
                    accent: true,
                    onTap: () =>
                        onPlay(state.unlocked.clamp(1, levelNames.length) - 1)),
                const SizedBox(height: 10),
                PixelButton('УРОВНИ',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LevelSelect(
                                state: state,
                                levelNames: levelNames,
                                onPlay: onPlay)))),
                const SizedBox(height: 10),
                PixelButton('НАСТРОЙКИ',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SettingsScreen(state: state)))),
                const SizedBox(height: 10),
                PixelButton('ВЫХОД', onTap: () => SystemNavigator.pop()),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Выбор уровня: сетка плиток, закрытые — с замком.
class LevelSelect extends StatelessWidget {
  const LevelSelect(
      {super.key,
      required this.state,
      required this.levelNames,
      required this.onPlay});
  final MenuState state;
  final List<String> levelNames;
  final void Function(int levelIndex) onPlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MC.bg,
      body: MenuBackground(
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 12),
            const _Title('УРОВНИ', size: 22),
            Expanded(
              child: Center(
                child: ListenableBuilder(
                  listenable: state,
                  builder: (_, __) => Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var i = 0; i < levelNames.length; i++)
                          _tile(context, i),
                      ]),
                ),
              ),
            ),
            PixelButton('НАЗАД', width: 160, onTap: () {
              Sfx.back();
              Navigator.pop(context);
            }),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, int i) {
    final open = i < state.unlocked;
    final navigator = Navigator.of(context);
    return GestureDetector(
      onTap: open
          ? () async {
              Sfx.click();
              final musicStart = Sfx.startMusic();
              navigator.popUntil((r) => r.isFirst);
              onPlay(i);
              await musicStart;
            }
          : null,
      child: Container(
        width: 84,
        height: 70,
        decoration: BoxDecoration(
          color: open ? MC.panel : MC.bg,
          border: Border.all(
              color: open
                  ? (i == state.unlocked - 1 ? MC.light : MC.frame)
                  : MC.panelHi,
              width: 3),
        ),
        alignment: Alignment.center,
        child: open
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${i + 1}',
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: MC.text)),
                Text(levelNames[i].replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 9, color: MC.hint)),
              ])
            : const Icon(Icons.lock, color: MC.panelHi, size: 26),
      ),
    );
  }
}

/// Настройки: переключатели. Логику звука подключи в MenuState.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final MenuState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MC.bg,
      body: MenuBackground(
        child: Center(
          child: ListenableBuilder(
            listenable: state,
            builder: (_, __) =>
                Column(mainAxisSize: MainAxisSize.min, children: [
              const _Title('НАСТРОЙКИ', size: 22),
              const SizedBox(height: 18),
              PixelButton('МУЗЫКА: ${state.music ? "ВКЛ" : "ВЫКЛ"}',
                  width: 260, onTap: state.toggleMusic),
              const SizedBox(height: 10),
              PixelButton('ЗВУКИ: ${state.sfx ? "ВКЛ" : "ВЫКЛ"}',
                  width: 260, onTap: state.toggleSfx),
              const SizedBox(height: 10),
              PixelButton('ПОДСКАЗКИ: ${state.hints ? "ВКЛ" : "ВЫКЛ"}',
                  width: 260, onTap: state.toggleHints),
              const SizedBox(height: 18),
              PixelButton('НАЗАД', width: 160, onTap: () {
                Sfx.back();
                Navigator.pop(context);
              }),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Пауза поверх игры: положи в Stack над GameWidget, когда paused == true.
class PauseMenu extends StatelessWidget {
  const PauseMenu(
      {super.key,
      required this.onResume,
      required this.onRestart,
      required this.onMenu});
  final VoidCallback onResume, onRestart, onMenu;
  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xCC100E1C),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const _Title('ПАУЗА', size: 22),
            const SizedBox(height: 16),
            PixelButton('ПРОДОЛЖИТЬ', accent: true, onTap: onResume),
            const SizedBox(height: 10),
            PixelButton('ЗАНОВО', onTap: onRestart),
            const SizedBox(height: 10),
            PixelButton('В МЕНЮ', onTap: onMenu),
          ]),
        ),
      );
}

// ---------- ПРИМЕР ПОДКЛЮЧЕНИЯ (в main.dart) ----------
// final menuState = MenuState();
// runApp(MaterialApp(
//   debugShowCheckedModeBanner: false,
//   home: MainMenu(
//     state: menuState,
//     levelNames: levels.map((l) => l.name).toList(),
//     onPlay: (i) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => GamePage(startLevel: i))),
//   ),
// ));
// При победе на уровне n:  menuState.unlockUpTo(n + 2);   // n — индекс с нуля
// Кнопка паузы в игре:     setState(() => paused = true);  и показать PauseMenu(...) в Stack.
