import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game.dart';
import 'audio.dart';
import 'menu.dart';
import 'platformer_levels.dart';
import 'platformer_sim.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Sfx.init();
  runApp(const EchoOfThePastApp());
}

class EchoOfThePastApp extends StatefulWidget {
  const EchoOfThePastApp({super.key});

  @override
  State<EchoOfThePastApp> createState() => _EchoOfThePastAppState();
}

class _EchoOfThePastAppState extends State<EchoOfThePastApp> {
  final MenuState _menuState = MenuState();

  @override
  void dispose() {
    _menuState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Echo of the Past',
      home: Builder(
        builder: (navigationContext) => MainMenu(
          state: _menuState,
          levelNames: levels.map((level) => level.name).toList(),
          onPlay: (levelIndex) {
            Navigator.of(navigationContext).push(
              MaterialPageRoute<void>(
                builder: (_) => GamePage(
                  startLevel: levelIndex,
                  menuState: _menuState,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.startLevel,
    required this.menuState,
  });

  final int startLevel;
  final MenuState menuState;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final EchoGame game;

  static final _gameKeys = {
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.keyR,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.keyN,
    LogicalKeyboardKey.keyP,
    LogicalKeyboardKey.escape,
  };

  @override
  void initState() {
    super.initState();
    game = EchoGame(startLevel: widget.startLevel)
      ..onLevelWon = _onLevelWon
      ..showHints = widget.menuState.hints;
  }

  void _onLevelWon(int levelIndex) {
    final unlocked = (levelIndex + 2).clamp(1, levels.length).toInt();
    widget.menuState.unlockUpTo(unlocked);
  }

  void _setPaused(bool paused) {
    setState(() {
      if (game.paused != paused) Sfx.duckMusic(paused);
      game.paused = paused;
      game.keys = 0;
      game.touch = 0;
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    var input = 0;
    if (pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      input |= inL;
    }
    if (pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
        pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      input |= inR;
    }
    if (pressedKeys.contains(LogicalKeyboardKey.space) ||
        pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
        pressedKeys.contains(LogicalKeyboardKey.keyW)) {
      input |= inJ;
    }
    game.keys = game.paused ? 0 : input;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _setPaused(!game.paused);
      } else if (!game.paused) {
        if (event.logicalKey == LogicalKeyboardKey.keyR) {
          game.restart();
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          game.confirm();
        } else if (event.logicalKey == LogicalKeyboardKey.keyN) {
          game.goTo(game.levelIndex + 1);
        } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
          game.goTo(game.levelIndex - 1);
        }
      }
    }

    return _gameKeys.contains(event.logicalKey)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  Widget _btn(IconData icon, int bit) {
    return Listener(
      onPointerDown: (_) => game.touch |= bit,
      onPointerUp: (_) => game.touch &= ~bit,
      onPointerCancel: (_) => game.touch &= ~bit,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white10,
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Icon(icon, color: Colors.white54, size: 36),
      ),
    );
  }

  void _returnToMenu() {
    Sfx.duckMusic(false);
    game.paused = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    game.onLevelWon = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return Scaffold(
      backgroundColor: const Color(0xFF100E1C),
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          children: [
            GameWidget<EchoGame>(game: game, autofocus: false),
            if (mobile)
              Positioned(
                left: 24,
                bottom: 24,
                child: Row(children: [
                  _btn(Icons.arrow_back, inL),
                  const SizedBox(width: 16),
                  _btn(Icons.arrow_forward, inR),
                ]),
              ),
            if (mobile)
              Positioned(
                right: 24,
                bottom: 24,
                child: _btn(Icons.arrow_upward, inJ),
              ),
            if (mobile)
              Positioned(
                right: 24,
                top: 16,
                child: Row(children: [
                  IconButton(
                    tooltip: 'Пауза',
                    onPressed: () {
                      Sfx.click();
                      _setPaused(true);
                    },
                    icon: const Icon(Icons.pause, color: Colors.white54),
                  ),
                  IconButton(
                    tooltip: 'Заново',
                    onPressed: () {
                      Sfx.click();
                      game.restart();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white54),
                  ),
                ]),
              ),
            if (game.paused)
              PauseMenu(
                onResume: () => _setPaused(false),
                onRestart: () {
                  game.restart();
                  _setPaused(false);
                },
                onMenu: _returnToMenu,
              ),
          ],
        ),
      ),
    );
  }
}
