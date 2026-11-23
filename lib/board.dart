// Чистая игровая логика без Flutter/Flame: легко тестировать.

enum Move { left, right, up, down, jump, wait }

enum Tile {
  air,
  wall,
  ladder,
  plate,
  plate2,
  door,
  gate,
  fog,
  platform,
  bonfire,
  lever,
  crate,
}

enum Status { playing, won, lost }

class Pos {
  final int x, y;
  const Pos(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is Pos && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class LevelData {
  final String name;
  final String hint;

  /// Через сколько ходов появляется Echo.
  final int delay;
  final List<String> rows;
  final bool memoryFog;
  final int? cyclePeriod;

  const LevelData({
    required this.name,
    required this.hint,
    required this.delay,
    required this.rows,
    this.memoryFog = false,
    this.cyclePeriod,
  });
}

class _Snapshot {
  final Pos present;
  final Pos? echo;
  final int historyLen;
  final int turn;
  final bool plateActive;
  final bool leverActive;
  final List<Pos> crates;
  final int worldTick;
  final Status status;
  _Snapshot(
      this.present,
      this.echo,
      this.historyLen,
      this.turn,
      this.plateActive,
      this.leverActive,
      this.crates,
      this.worldTick,
      this.status);
}

class Board {
  final LevelData level;
  late final int width;
  late final int height;
  late final List<List<Tile>> _grid;
  late final Pos start;
  late Pos present;
  Pos? echo;
  List<Pos> crates = [];

  /// Все ходы игрока. Echo берёт ход history[turn - delay - 1].
  final List<Move> history = [];
  int turn = 0;
  bool plateActive = false;
  bool leverActive = false;
  int worldTick = 0;
  Status status = Status.playing;

  final List<_Snapshot> _undo = [];

  Board(this.level) {
    height = level.rows.length;
    width = level.rows.first.length;
    final grid = <List<Tile>>[];
    var st = const Pos(1, 1);
    for (var y = 0; y < height; y++) {
      final row = <Tile>[];
      for (var x = 0; x < width; x++) {
        final c = level.rows[y][x];
        if (c == 'S') st = Pos(x, y);
        row.add(switch (c) {
          '#' => Tile.wall,
          'H' => Tile.ladder,
          'T' => Tile.plate,
          'U' => Tile.plate2,
          'D' => Tile.door,
          'G' => Tile.gate,
          'F' => Tile.fog,
          'M' => Tile.platform,
          'B' => Tile.bonfire,
          'L' => Tile.lever,
          'C' => Tile.air,
          _ => Tile.air,
        });
        if (c == 'C') crates.add(Pos(x, y));
      }
      grid.add(row);
    }
    _grid = grid;
    start = st;
    present = _settle(start);
    _resolvePlates();
  }

  bool get canUndo => _undo.isNotEmpty;
  bool get clockOpen => _clockOpen;

  Tile tileAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return Tile.wall;
    return _grid[y][x];
  }

  bool _solid(int x, int y) => switch (tileAt(x, y)) {
        Tile.wall => true,
        Tile.door => !(_doorOpen || leverActive),
        Tile.gate => !_clockOpen,
        Tile.platform => plateActive || leverActive,
        _ => false,
      };

  bool get _hasSecondPlate {
    for (final row in _grid) {
      if (row.contains(Tile.plate2)) return true;
    }
    return false;
  }

  bool get _doorOpen => _hasSecondPlate ? _platesPressed == 2 : plateActive;

  bool get _clockOpen {
    final period = level.cyclePeriod;
    if (period == null || period <= 1) return true;
    return worldTick % period < period ~/ 2;
  }

  int get _platesPressed {
    var pressed = 0;
    for (final kind in [Tile.plate, Tile.plate2]) {
      final occupied = _onPlateKind(present, kind) ||
          (echo != null && _onPlateKind(echo!, kind)) ||
          crates.any((p) => tileAt(p.x, p.y) == kind);
      if (occupied) pressed++;
    }
    return pressed;
  }

  bool _crateAt(int x, int y) => crates.any((p) => p.x == x && p.y == y);

  bool _blocked(int x, int y) => _solid(x, y) || _crateAt(x, y);

  bool _ladder(int x, int y) => tileAt(x, y) == Tile.ladder;

  bool _supported(Pos p) =>
      _ladder(p.x, p.y) || _solid(p.x, p.y + 1) || _ladder(p.x, p.y + 1);

  Pos _settle(Pos p) {
    while (!_supported(p) && p.y + 1 < height) {
      p = Pos(p.x, p.y + 1);
    }
    return p;
  }

  void _toggleLever(Pos p) {
    if (tileAt(p.x, p.y) == Tile.lever) leverActive = !leverActive;
  }

  bool _pushCrate(int fromX, int y, int dx) {
    final index = crates.indexWhere((p) => p.x == fromX && p.y == y);
    if (index < 0) return false;
    final targetX = fromX + dx;
    if (_blocked(targetX, y)) return false;
    crates[index] = Pos(targetX, y);
    return true;
  }

  /// Один шаг персонажа. Игрок и Echo используют ОДИН И ТОТ ЖЕ код.
  Pos _step(Pos p, Move m) {
    var n = p;
    switch (m) {
      case Move.left:
        if (!_blocked(p.x - 1, p.y) || _pushCrate(p.x - 1, p.y, -1)) {
          n = Pos(p.x - 1, p.y);
        }
      case Move.right:
        if (!_blocked(p.x + 1, p.y) || _pushCrate(p.x + 1, p.y, 1)) {
          n = Pos(p.x + 1, p.y);
        }
      case Move.up:
        if (_ladder(p.x, p.y) && !_solid(p.x, p.y - 1)) n = Pos(p.x, p.y - 1);
      case Move.down:
        if (!_solid(p.x, p.y + 1) &&
            (_ladder(p.x, p.y) || _ladder(p.x, p.y + 1))) {
          n = Pos(p.x, p.y + 1);
        }
      case Move.jump:
        if (!_blocked(p.x, p.y - 1)) {
          n = Pos(p.x, p.y - 1);
        } else if (!_blocked(p.x - 1, p.y) &&
            !_blocked(p.x - 2, p.y) &&
            _solid(p.x - 1, p.y + 1) &&
            !_blocked(p.x - 2, p.y + 1)) {
          n = Pos(p.x - 2, p.y);
        } else if (!_blocked(p.x + 1, p.y) &&
            !_blocked(p.x + 2, p.y) &&
            _solid(p.x + 1, p.y + 1) &&
            !_blocked(p.x + 2, p.y + 1)) {
          n = Pos(p.x + 2, p.y);
        }
      case Move.wait:
        break;
    }
    final settled = _settle(n);
    _toggleLever(settled);
    return settled;
  }

  bool _onPlateKind(Pos p, Tile kind) =>
      tileAt(p.x, p.y) == kind || _crateAt(p.x, p.y) &&
          tileAt(p.x, p.y) == kind;

  void _resolvePlates() {
    for (var i = 0; i < 4; i++) {
      final e = echo;
      final now = _platesPressed > (_hasSecondPlate ? 1 : 0);
      if (now == plateActive) break;
      plateActive = now;
      present = _settle(present);
      if (e != null) echo = _settle(e);
    }
  }

  void act(Move m) {
    if (status != Status.playing) return;
    _undo.add(_Snapshot(present, echo, history.length, turn, plateActive,
        leverActive, List.of(crates), worldTick, status));
    final presentBefore = present;
    final echoBefore = echo;

    final startedInFog = tileAt(present.x, present.y) == Tile.fog;
    present = _step(present, m);
    history.add(startedInFog ? Move.wait : m);
    turn++;
    worldTick++;

    final e = echo;
    if (e != null) {
      final i = turn - level.delay - 1;
      if (i >= 0 && i < history.length) echo = _step(e, history[i]);
    } else if (turn >= level.delay) {
      echo = _settle(start); // Echo появляется на старте
    }

    _resolvePlates();

    final e2 = echo;
    if (e2 != null) {
      final same = e2 == present;
      final swapped =
          echoBefore != null && present == echoBefore && e2 == presentBefore;
      if (same || swapped) {
        status = Status.lost;
        return;
      }
    }
    if (tileAt(present.x, present.y) == Tile.bonfire) status = Status.won;
  }

  List<Pos> echoPreview([int count = 5]) {
    final savedCrates = List.of(crates);
    final savedLever = leverActive;
    final result = <Pos>[];
    var p = echo ?? _settle(start);
    final first = echo == null ? 0 : turn - level.delay;
    for (var offset = 0; offset < count; offset++) {
      final index = first + offset;
      if (index < 0 || index >= history.length) break;
      p = _step(p, history[index]);
      result.add(p);
    }
    crates = savedCrates;
    leverActive = savedLever;
    return result;
  }

  void undo() {
    if (_undo.isEmpty) return;
    final s = _undo.removeLast();
    present = s.present;
    echo = s.echo;
    history.removeRange(s.historyLen, history.length);
    turn = s.turn;
    plateActive = s.plateActive;
    leverActive = s.leverActive;
    crates = List.of(s.crates);
    worldTick = s.worldTick;
    status = s.status;
  }
}
