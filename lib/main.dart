import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game.dart';
import 'sim.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Echo of the Past',
    home: GamePage(),
  ));
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final EchoGame game = EchoGame();

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
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    final k = HardwareKeyboard.instance.logicalKeysPressed;
    var b = 0;
    if (k.contains(LogicalKeyboardKey.arrowLeft) ||
        k.contains(LogicalKeyboardKey.keyA)) {
      b |= inL;
    }
    if (k.contains(LogicalKeyboardKey.arrowRight) ||
        k.contains(LogicalKeyboardKey.keyD)) {
      b |= inR;
    }
    if (k.contains(LogicalKeyboardKey.space) ||
        k.contains(LogicalKeyboardKey.arrowUp) ||
        k.contains(LogicalKeyboardKey.keyW)) {
      b |= inJ;
    }
    game.keys = b;
    if (e is KeyDownEvent &&
        (e.logicalKey == LogicalKeyboardKey.keyR ||
            (e.logicalKey == LogicalKeyboardKey.enter &&
                game.sim.status != Status.won))) {
      game.restart();
    } else if (e is KeyDownEvent &&
        e.logicalKey == LogicalKeyboardKey.enter &&
        game.sim.status == Status.won) {
      game.nextLevel();
    }
    return _gameKeys.contains(e.logicalKey)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100E1C),
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          children: [GameWidget<EchoGame>(game: game, autofocus: false)],
        ),
      ),
    );
  }
}
