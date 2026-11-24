// Звук для Echo of the Past: эффекты, фоновая музыка и авто-озвучка событий игры.
// Зависимость: flame_audio. Файлы лежат в assets/audio/ (см. README).
import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import 'platformer_sim.dart';

class Sfx {
  Sfx._();
  static bool sfxOn = true;
  static bool _musicOn = true;
  static bool _initialized = false;
  static Completer<void>? _musicLock;
  static final Map<String, Future<AudioPool>> _effectPools = {};
  static double sfxVolume = 0.7, musicVolume = 0.35;

  static const _files = [
    'click',
    'hover',
    'back',
    'jump',
    'land',
    'echo_spawn',
    'plate_on',
    'plate_off',
    'door_open',
    'door_close',
    'lever',
    'death',
    'win',
    'level_start',
    'music',
  ];

  /// Вызови один раз в main() после WidgetsFlutterBinding.ensureInitialized().
  static Future<void> init() async {
    if (_initialized) return;
    await FlameAudio.audioCache.loadAll([for (final f in _files) '$f.wav']);
    await FlameAudio.bgm
        .initialize(); // музыка сама ставится на паузу при сворачивании
    _initialized = true;
  }

  static void play(String name, {double? volume}) {
    if (!sfxOn || !_initialized) return;
    unawaited(_playEffect(name, volume ?? sfxVolume));
  }

  static Future<void> _playEffect(String name, double volume) async {
    final pool = await _effectPools.putIfAbsent(
      name,
      () => FlameAudio.createPool('$name.wav', minPlayers: 1, maxPlayers: 4),
    );
    if (!sfxOn) return;
    await pool.start(volume: volume);
  }

  static Future<void> setEffectsEnabled(bool enabled) async {
    sfxOn = enabled;
    if (enabled || !_initialized) return;

    final pools = _effectPools.values.toList();
    _effectPools.clear();
    final initializedPools = await Future.wait(pools);
    await Future.wait(initializedPools.map((pool) => pool.dispose()));
  }

  // --- меню ---
  static void click() => play('click');
  static void hover() => play('hover', volume: 0.3);
  static void back() => play('back');

  // --- музыка ---
  static bool get musicOn => _musicOn;
  static Future<void> setMusicEnabled(bool enabled) async {
    _musicOn = enabled;
    await _withMusicLock(_syncMusic);
  }

  static Future<void> startMusic() => _withMusicLock(_syncMusic);

  static Future<void> _withMusicLock(Future<void> Function() action) async {
    while (_musicLock != null) {
      await _musicLock!.future;
    }

    final lock = Completer<void>();
    _musicLock = lock;
    try {
      await action();
    } finally {
      _musicLock = null;
      lock.complete();
    }
  }

  static Future<void> _syncMusic() async {
    if (!_initialized) return;
    if (_musicOn) {
      if (!FlameAudio.bgm.isPlaying) {
        await FlameAudio.bgm.play('music.wav', volume: musicVolume);
      }
    } else if (FlameAudio.bgm.isPlaying) {
      await FlameAudio.bgm.stop();
    }
  }

  /// Тише на паузе, обычная громкость в игре (по желанию).
  static void duckMusic(bool duck) {
    if (!_initialized || !FlameAudio.bgm.isPlaying) return;
    FlameAudio.bgm.audioPlayer
        .setVolume(duck ? musicVolume * 0.4 : musicVolume);
  }

  // --- переходы между уровнями ---
  static void levelStart() => play('level_start');
}

/// Озвучивает события симуляции, не меняя её код: вызывай observe() после каждого sim.step().
class GameSfx {
  bool _wasGround = true, _wasLever = false, _wasDead = false, _wasWon = false;
  final _plates = {1: false, 2: false};
  int _closed = -1, _echoes = 0;
  int _lastJumpTick = -99;

  /// Сбрасывай при restart() и при смене уровня.
  void reset(Sim sim) {
    _wasGround = true;
    _wasLever = sim.leverOn;
    _wasDead = false;
    _wasWon = false;
    _lastJumpTick = -99;
    _plates[1] = sim.pressed[1]!;
    _plates[2] = sim.pressed[2]!;
    _closed = _closedDoors(sim);
    _echoes = 0;
  }

  int _closedDoors(Sim s) {
    var n = 0;
    s.lv.doors.forEach((k, v) {
      if (s.doorClosed(k ~/ 100, k % 100, v)) n++;
    });
    return n;
  }

  void observe(Sim sim) {
    final p = sim.player;
    // прыжок: был на земле, теперь летим вверх
    if (_wasGround && !p.g && p.vy < -2 && sim.tick - _lastJumpTick > 8) {
      Sfx.play('jump');
      _lastJumpTick = sim.tick;
    }
    // приземление
    if (!_wasGround && p.g) Sfx.play('land', volume: 0.35);
    _wasGround = p.g;

    // появление Эха
    final n = sim.echoes.where((e) => e != null).length;
    if (n > _echoes) Sfx.play('echo_spawn');
    _echoes = n;

    // плиты
    for (final g in const [1, 2]) {
      final now = sim.pressed[g]!;
      if (now != _plates[g]) Sfx.play(now ? 'plate_on' : 'plate_off');
      _plates[g] = now;
    }
    // двери (открылись/закрылись)
    final closed = _closedDoors(sim);
    if (_closed >= 0 && closed != _closed) {
      Sfx.play(closed < _closed ? 'door_open' : 'door_close', volume: 0.5);
    }
    _closed = closed;
    // рычаг
    if (sim.leverOn != _wasLever) Sfx.play('lever');
    _wasLever = sim.leverOn;

    // смерть / победа (один раз)
    final dead = sim.status == Status.dead, won = sim.status == Status.won;
    if (dead && !_wasDead) Sfx.play('death');
    if (won && !_wasWon) Sfx.play('win');
    _wasDead = dead;
    _wasWon = won;
  }
}
