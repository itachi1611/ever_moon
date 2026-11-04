import 'dart:math' show Random, max;

import '../../common/game.dart' show Game;
import '../model/piece.dart';

// Tetris state and rules. Rendering lives in ../ui/renderer.dart.
// Board size and drop speed are configurable from the Settings menu.
class TetrisGame extends Game {
  final int cols;
  final int rows;
  final double speedMultiplier;

  final rng = Random();
  late final List<List<int>> board =
      List.generate(rows, (_) => List.filled(cols, 0));

  late List<List<bool>> shape;
  late int color;
  int px = 0, py = 0;
  int nextIndex = 0;

  int lines = 0, level = 1;
  double dropAccum = 0;

  // Line-clear animation: rows being flashed before they are removed.
  List<int> clearing = [];
  int clearTicks = 0;
  bool lastWasTetris = false; // for the back-to-back Tetris bonus
  static const int clearAnimTicks = 8;

  TetrisGame({
    this.cols = 10,
    this.rows = 20,
    this.speedMultiplier = 1.0,
    int high = 0,
  }) {
    this.high = high;
    nextIndex = _drawFromBag();
    spawn();
  }

  @override
  void update(double ms) {
    if (score > high) high = score;
    if (over) return;
    if (clearTicks > 0) {
      clearTicks--;
      if (clearTicks == 0) _applyClear();
      return; // pause gravity during the line-clear flash
    }
    dropAccum += ms;
    final interval = max(60.0, (500.0 - (level - 1) * 40) / speedMultiplier);
    if (dropAccum >= interval) {
      dropAccum = 0;
      step();
    }
  }

  @override
  void handleKey(String key) {
    switch (key) {
      case 'q':
      case 'ctrlC':
        quit = true;
        break;
      case 'space':
        input('drop');
        break;
      case 'arrowUp':
      case 'w':
        input('rotate');
        break;
      case 'arrowDown':
      case 's':
        input('soft');
        break;
      case 'arrowLeft':
      case 'a':
        input('left');
        break;
      case 'arrowRight':
      case 'd':
        input('right');
        break;
    }
  }

  // 7-bag randomizer: each of the seven pieces appears once per shuffled bag,
  // so you never get long droughts or repeats of the same piece.
  final List<int> _bag = [];
  int _drawFromBag() {
    if (_bag.isEmpty) {
      _bag.addAll([for (int i = 0; i < pieces.length; i++) i]..shuffle(rng));
    }
    return _bag.removeLast();
  }

  // Row where the current piece would land if hard-dropped (for the ghost).
  int get ghostY {
    int y = py;
    while (!collides(shape, px, y + 1)) {
      y++;
    }
    return y;
  }

  // Convert a piece definition into a 4x4 boolean grid
  List<List<bool>> gridOf(int idx) => [
        for (final row in pieces[idx].cells)
          [for (final ch in row.split('')) ch == 'X']
      ];

  int topOffset(List<List<bool>> s) {
    for (int r = 0; r < 4; r++) {
      if (s[r].any((b) => b)) return r;
    }
    return 0;
  }

  void spawn() {
    final idx = nextIndex;
    nextIndex = _drawFromBag();
    shape = gridOf(idx);
    color = pieces[idx].color;
    px = (cols ~/ 2) - 2;
    py = -topOffset(shape);
    if (collides(shape, px, py)) over = true;
  }

  bool collides(List<List<bool>> s, int ox, int oy) {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (!s[r][c]) continue;
        final x = ox + c, y = oy + r;
        if (x < 0 || x >= cols || y >= rows) return true;
        if (y >= 0 && board[y][x] != 0) return true;
      }
    }
    return false;
  }

  // Rotate the 4x4 grid clockwise
  List<List<bool>> rotated(List<List<bool>> s) =>
      [for (int i = 0; i < 4; i++) [for (int j = 0; j < 4; j++) s[3 - j][i]]];

  void tryRotate() {
    final r = rotated(shape);
    for (final dx in [0, -1, 1, -2, 2]) { // simple wall-kick
      if (!collides(r, px + dx, py)) {
        shape = r;
        px += dx;
        return;
      }
    }
  }

  void move(int dx) {
    if (!collides(shape, px + dx, py)) px += dx;
  }

  void softDrop() {
    if (!collides(shape, px, py + 1)) {
      py++;
      score += 1; // soft-drop point per cell
    } else {
      lock();
    }
    dropAccum = 0;
  }

  void hardDrop() {
    var dropped = 0;
    while (!collides(shape, px, py + 1)) {
      py++;
      dropped++;
    }
    score += dropped * 2; // hard-drop points per cell
    lock();
  }

  void step() {
    if (!collides(shape, px, py + 1)) {
      py++;
    } else {
      lock();
    }
  }

  void lock() {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (!shape[r][c]) continue;
        final x = px + c, y = py + r;
        if (y < 0) {
          over = true;
          continue;
        }
        board[y][x] = color;
      }
    }
    if (over) return;

    // Detect full rows. If any, flash them first (animation); the rows are
    // actually removed and scored when the flash finishes in _applyClear().
    final full = <int>[];
    for (int y = 0; y < rows; y++) {
      if (board[y].every((v) => v != 0)) full.add(y);
    }
    if (full.isEmpty) {
      spawn();
    } else {
      clearing = full;
      clearTicks = clearAnimTicks;
    }
  }

  // Removes the flashed rows and applies scoring, then spawns the next piece.
  void _applyClear() {
    final n = clearing.length;
    final removing = clearing.toSet();
    final kept = [
      for (int y = 0; y < rows; y++)
        if (!removing.contains(y)) board[y],
    ];
    board
      ..clear()
      ..addAll([for (int i = 0; i < n; i++) List.filled(cols, 0)])
      ..addAll(kept);

    // Tetris Guideline scoring: 100/300/500/800 x level, plus a back-to-back
    // x1.5 bonus for consecutive Tetrises (four lines).
    const table = [0, 100, 300, 500, 800];
    if (n == 4) {
      score += (lastWasTetris ? 1200 : 800) * level;
      lastWasTetris = true;
    } else {
      score += table[n] * level;
      lastWasTetris = false;
    }
    lines += n;
    level = 1 + lines ~/ 10;
    clearing = [];
    spawn();
  }

  void input(String a) {
    if (over) {
      if (a == 'drop' || a == 'rotate') reset();
      return;
    }
    if (clearTicks > 0) return; // ignore input during the line-clear flash
    switch (a) {
      case 'left':
        move(-1);
        break;
      case 'right':
        move(1);
        break;
      case 'rotate':
        tryRotate();
        break;
      case 'soft':
        softDrop();
        break;
      case 'drop':
        hardDrop();
        break;
    }
  }

  void reset() {
    for (final row in board) {
      row.fillRange(0, cols, 0);
    }
    score = 0;
    lines = 0;
    level = 1;
    over = false;
    dropAccum = 0;
    clearing = [];
    clearTicks = 0;
    lastWasTetris = false;
    _bag.clear();
    nextIndex = _drawFromBag();
    spawn();
  }
}
