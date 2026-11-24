// Детерминированная симуляция (чистый Dart, без Flutter). 60 тиков/с.
// Точное зеркало эталона sim.py, на котором проверена проходимость всех уровней.
import 'dart:math' as math;

const double tickDt = 1 / 60;
const int tile = 8, yOff = 68, gridCols = 40, gridRows = 14;
const int inL = 1, inR = 2, inJ = 4;

class Rc {
  final double x, y, w, h;
  const Rc(this.x, this.y, this.w, this.h);
  bool ov(Rc o) => x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y;
  Rc shrink(double d) => Rc(x + d, y + d, w - 2 * d, h - 2 * d);
}

const _frame = [Rc(0, 0, 320, 12), Rc(0, 12, 8, 168), Rc(312, 12, 8, 168)];

int _sign(double v) => v > 0 ? 1 : (v < 0 ? -1 : 0);

class LiftSpec {
  final int dx, dy, cycle;
  const LiftSpec(this.dx, this.dy, this.cycle);
}

class Level {
  final String name, hint;
  final List<String> rows;
  final List<int> delays;
  final List<LiftSpec> liftSpecs;
  final int fogFrom, fogTo; // -1 = тумана нет
  final Set<int> solid = {}; // c*100+r
  final Map<int, List<Rc>> plates = {1: [], 2: []};
  final Map<int, String> doors = {};
  final Map<int, int> bridges = {};
  final List<Rc> lever = [];
  final List<(double, double)> crates = [];
  final List<(Rc, LiftSpec)> lifts = [];
  late final double spawnX, spawnY;
  late final Rc goal;

  static int key(int c, int r) => c * 100 + r;

  Level(this.name, this.hint, this.rows, this.delays,
      {this.liftSpecs = const [], this.fogFrom = -1, this.fogTo = -1}) {
    var li = 0;
    for (var r = 0; r < gridRows; r++) {
      final row = rows[r];
      for (var c = 0; c < gridCols; c++) {
        final ch = row[c];
        final x = c * tile.toDouble(), y = (yOff + r * tile).toDouble();
        switch (ch) {
          case '#':
            solid.add(key(c, r));
          case 'S':
            spawnX = x + 1;
            spawnY = y + tile - 12;
          case '*':
            goal = Rc(x + 2, y - tile, 4, 16);
          case 'p':
            plates[1]!.add(Rc(x, y + 5, 8, 3));
          case 'q':
            plates[2]!.add(Rc(x, y + 5, 8, 3));
          case 'D' || 'E' || 'G' || 'H':
            doors[key(c, r)] = ch;
          case '~':
            bridges[key(c, r)] = 1;
          case '=':
            bridges[key(c, r)] = 2;
          case 'l':
            lever.add(Rc(x, y, 8, 8));
          case 'B':
            crates.add((x, y - tile));
          case 'L':
            final c0 = c;
            while (c + 1 < gridCols && row[c + 1] == 'L') {
              c++;
            }
            lifts.add((
              Rc(c0 * tile.toDouble(), y, (c - c0 + 1) * tile.toDouble(), 8),
              liftSpecs[li++]
            ));
        }
      }
    }
  }

  bool inFog(double px) {
    if (fogFrom < 0) return false;
    final fc = ((px + 3) / tile).floor();
    return fc >= fogFrom && fc <= fogTo;
  }
}

(double, double) liftOffset(LiftSpec s, int tick) {
  final p = (tick % s.cycle) / s.cycle;
  final f = p < 0.2
      ? 0.0
      : (p < 0.5 ? (p - 0.2) / 0.3 : (p < 0.7 ? 1.0 : 1 - (p - 0.7) / 0.3));
  return (s.dx * tile * f, s.dy * tile * f);
}

abstract class Mover {
  double x, y;
  final double w, h;
  Mover(this.x, this.y, this.w, this.h);
  Rc rect() => Rc(x, y, w, h);
}

class Crate extends Mover {
  double vy = 0;
  bool fallen = false;
  Crate(double x, double y) : super(x, y, 16, 16);
  void update(Sim sim) {
    if (fallen) return;
    vy = math.min(vy + 0.25, 5.0);
    y += vy;
    for (final o in sim.solids(rect())) {
      if (rect().ov(o)) {
        if (vy > 0) {
          y = o.y - 16;
        } else if (vy < 0) {
          y = o.y + o.h;
        }
        vy = 0;
      }
    }
    if (y > 190) fallen = true;
  }
}

class Body extends Mover {
  double vx = 0, vy = 0;
  bool g = false, face = true, onLever = false, fallen = false;
  int co = 0, bu = 0, prev = 0, anim = 0;
  Body(double x, double y) : super(x, y, 6, 12);

  void step(int inp, Sim sim, List<Rc> soft) {
    final l = (inp & inL) != 0, r = (inp & inR) != 0, j = (inp & inJ) != 0;
    final pressed = j && (prev & inJ) == 0;
    prev = inp;
    if (l == r) {
      final f = g ? 0.22 : 0.05;
      if (vx.abs() <= f) {
        vx = 0;
      } else {
        vx -= f * _sign(vx);
      }
    } else if (r) {
      vx = math.min(vx + (g ? 0.28 : 0.16), 1.6);
      face = true;
    } else {
      vx = math.max(vx - (g ? 0.28 : 0.16), -1.6);
      face = false;
    }
    if (g) {
      co = 6;
    } else if (co > 0) {
      co--;
    }
    if (pressed) {
      bu = 6;
    } else if (bu > 0) {
      bu--;
    }
    if (bu > 0 && co > 0) {
      vy = -3.2;
      bu = 0;
      co = 0;
      g = false;
    }
    if (!j && vy < -1.2) vy = -1.2;
    vy = math.min(vy + 0.25, 5.0);
    final mv = vx;
    x += vx;
    for (final o in sim.solids(rect())) {
      if (rect().ov(o)) {
        if (vx > 0) {
          x = o.x - 6;
        } else if (vx < 0) {
          x = o.x + o.w;
        }
        vx = 0;
      }
    }
    for (final cr in sim.crates) {
      if (cr.fallen || mv == 0) continue;
      if (rect().ov(cr.rect())) {
        final pen = mv > 0 ? (x + 6) - cr.x : (cr.x + 16) - x;
        if (pen > 0) {
          final d = mv > 0 ? pen : -pen;
          final old = cr.x;
          cr.x += d;
          if (sim.solids(cr.rect()).any((o) => cr.rect().ov(o))) {
            cr.x = old;
            x = mv > 0 ? cr.x - 6 : cr.x + 16;
            vx = 0;
          }
        }
      }
    }
    final vym = vy, pb = y + 12;
    y += vy;
    g = false;
    for (final o in sim.solids(rect())) {
      if (rect().ov(o)) {
        if (vy > 0) {
          y = o.y - 12;
          g = true;
        } else if (vy < 0) {
          y = o.y + o.h;
        }
        vy = 0;
      }
    }
    for (final cr in sim.crates) {
      if (cr.fallen) continue;
      if (rect().ov(cr.rect())) {
        if (vym > 0) {
          y = cr.y - 12;
          g = true;
        } else if (vym < 0) {
          y = cr.y + 16;
        }
        vy = 0;
      }
    }
    for (final sr in soft) {
      if (vym > 0 && pb <= sr.y + 2 && rect().ov(sr)) {
        y = sr.y - 12;
        g = true;
        vy = 0;
      }
    }
    if (g && vx.abs() > 0.3) {
      anim++;
    } else if (g) {
      anim = 0;
    }
  }
}

enum Status { playing, dead, won }

class Sim {
  final Level lv;
  Sim(this.lv) {
    reset();
  }
  int tick = 0, endTimer = 0;
  Status status = Status.playing;
  final List<int> hist = [];
  late Body player;
  late List<Body?> echoes;
  late List<Crate> crates;
  late List<Rc> liftRects;
  bool leverOn = false;
  final pressed = {1: false, 2: false};
  final Set<int> occ = {};

  void reset() {
    tick = 0;
    endTimer = 0;
    status = Status.playing;
    hist.clear();
    player = Body(lv.spawnX, lv.spawnY);
    echoes = List.filled(lv.delays.length, null);
    crates = [for (final c in lv.crates) Crate(c.$1, c.$2)];
    leverOn = false;
    liftRects = [for (final l in lv.lifts) l.$1];
    pressed[1] = false;
    pressed[2] = false;
    occ.clear();
  }

  List<Body> aliveEchoes() => [
        for (final e in echoes)
          if (e != null && !e.fallen) e
      ];
  List<Mover> movers() =>
      [player, ...aliveEchoes(), ...crates.where((c) => !c.fallen)];

  bool doorClosed(int c, int r, String k) {
    if (occ.contains(Level.key(c, r))) return false;
    switch (k) {
      case 'D':
        return !pressed[1]!;
      case 'E':
        return !pressed[2]!;
      case 'G':
        return !leverOn;
      default:
        return leverOn;
    }
  }

  bool doorAt(int c, int r) {
    final k = Level.key(c, r);
    final d = lv.doors[k];
    return d != null && doorClosed(c, r, d);
  }

  bool bridgeAt(int c, int r) {
    final b = lv.bridges[Level.key(c, r)];
    return b != null && pressed[b]!;
  }

  List<Rc> solids(Rc rect) {
    final out = <Rc>[];
    final c0 = (rect.x / tile).floor();
    final c1 = ((rect.x + rect.w - 1e-9) / tile).floor();
    final r0 = ((rect.y - yOff) / tile).floor();
    final r1 = ((rect.y + rect.h - 1e-9 - yOff) / tile).floor();
    for (var r = r0; r <= r1; r++) {
      for (var c = c0; c <= c1; c++) {
        final k = Level.key(c, r);
        if (c < 0 || r < 0) continue;
        if (lv.solid.contains(k)) {
          out.add(Rc(c * 8.0, yOff + r * 8.0, 8, 8));
        } else if (lv.doors.containsKey(k)) {
          if (doorClosed(c, r, lv.doors[k]!)) {
            out.add(Rc(c * 8.0, yOff + r * 8.0, 8, 8));
          }
        } else if (lv.bridges.containsKey(k)) {
          if (pressed[lv.bridges[k]!]!) {
            out.add(Rc(c * 8.0, yOff + r * 8.0, 8, 8));
          }
        }
      }
    }
    out.addAll(_frame);
    out.addAll(liftRects);
    return out;
  }

  void _beginWorld() {
    final mv = movers();
    for (var i = 0; i < lv.lifts.length; i++) {
      final base = lv.lifts[i].$1, spec = lv.lifts[i].$2;
      final old = liftRects[i];
      final (ox, oy) = liftOffset(spec, tick);
      final nw = Rc(base.x + ox, base.y + oy, base.w, base.h);
      final dx = nw.x - old.x, dy = nw.y - old.y;
      for (final b in mv) {
        if ((b.y + b.h - old.y).abs() < 0.01 &&
            b.x + b.w > old.x &&
            b.x < old.x + old.w) {
          b.x += dx;
          b.y += dy;
        }
      }
      liftRects[i] = nw;
    }
    final rects = [for (final b in mv) b.rect()];
    lv.plates.forEach((g, pl) {
      pressed[g] = pl.any((p) => rects.any(p.ov));
    });
    occ.clear();
    for (final k in lv.doors.keys) {
      final c = k ~/ 100, r = k % 100;
      final t = Rc(c * 8.0, yOff + r * 8.0, 8, 8);
      if (rects.any(t.ov)) occ.add(k);
    }
  }

  void step(int inp) {
    if (status != Status.playing) {
      endTimer++;
      return;
    }
    _beginWorld();
    final p = player;
    hist.add(lv.inFog(p.x) ? 0 : inp);
    ({Body e, double x, double y})? ride;
    for (final e in aliveEchoes()) {
      if (p.g &&
          (p.y + 12 - e.y).abs() < 0.01 &&
          p.x + 6 > e.x &&
          p.x < e.x + 6) {
        ride = (e: e, x: e.x, y: e.y);
      }
    }
    final soft = [for (final e in aliveEchoes()) e.rect()];
    p.step(inp, this, soft);
    for (var i = 0; i < lv.delays.length; i++) {
      if (tick == lv.delays[i]) echoes[i] = Body(lv.spawnX, lv.spawnY);
    }
    for (var i = 0; i < lv.delays.length; i++) {
      final e = echoes[i];
      if (e != null && !e.fallen) {
        e.step(hist[tick - lv.delays[i]], this, const []);
        if (e.y > 190) e.fallen = true;
      }
    }
    if (ride != null && !ride.e.fallen) {
      p.x += ride.e.x - ride.x;
      p.y += ride.e.y - ride.y;
    }
    for (final c in crates) {
      c.update(this);
    }
    for (final b in [player, ...aliveEchoes()]) {
      final on = lv.lever.any((r) => b.rect().ov(r));
      if (on && !b.onLever) leverOn = !leverOn;
      b.onLever = on;
    }
    tick++;
    if (p.y > 190) {
      status = Status.dead;
      endTimer = 0;
      return;
    }
    for (final e in aliveEchoes()) {
      if (p.rect().shrink(1).ov(e.rect().shrink(1))) {
        status = Status.dead;
        endTimer = 0;
        return;
      }
    }
    if (p.rect().ov(lv.goal)) {
      status = Status.won;
      endTimer = 0;
    }
  }
}
