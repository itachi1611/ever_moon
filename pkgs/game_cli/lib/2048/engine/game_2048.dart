import 'dart:math' show Random;

import '../../common/game.dart' show Game;

// 2048 game state and rules. Rendering lives in ../ui/renderer.dart.
class Game2048 extends Game {
  final int size;
  final rng = Random();
  late final List<List<int>> grid =
      List.generate(size, (_) => List.filled(size, 0));

  bool won = false; // reached 2048 at least once (keep playing)

  // Merge flash: cells [r, c] that just merged, shown briefly.
  List<List<int>> merged = [];
  int flashTicks = 0;
  static const int flashAnimTicks = 3;

  // One-step undo snapshot.
  List<List<int>> _prevGrid = [];
  int _prevScore = 0;
  bool _prevWon = false;
  bool _canUndo = false;

  Game2048({this.size = 4}) {
    _addRandomTile();
    _addRandomTile();
  }

  @override
  void update(double ms) {
    if (flashTicks > 0) {
      flashTicks--;
      if (flashTicks == 0) merged = [];
    }
  }

  @override
  void handleKey(String key) {
    switch (key) {
      case 'q':
      case 'ctrlC':
        quit = true;
        break;
      case 'r':
        input('restart');
        break;
      case 'u':
        input('undo');
        break;
      case 'w':
      case 'arrowUp':
        input('up');
        break;
      case 's':
      case 'arrowDown':
        input('down');
        break;
      case 'a':
      case 'arrowLeft':
        input('left');
        break;
      case 'd':
      case 'arrowRight':
        input('right');
        break;
    }
  }

  void _addRandomTile() {
    final empty = <List<int>>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == 0) empty.add([r, c]);
      }
    }
    if (empty.isEmpty) return;
    final cell = empty[rng.nextInt(empty.length)];
    grid[cell[0]][cell[1]] = rng.nextInt(10) == 0 ? 4 : 2; // 10% chance of a 4
  }

  // Slides values toward index 0 and merges equal neighbours once. Returns the
  // new line plus the indices in it that resulted from a merge.
  (List<int>, List<int>) _collapse(List<int> line) {
    final values = [for (final v in line) if (v != 0) v];
    final res = <int>[];
    final mergedIdx = <int>[];
    var i = 0;
    while (i < values.length) {
      if (i + 1 < values.length && values[i] == values[i + 1]) {
        final m = values[i] * 2;
        res.add(m);
        mergedIdx.add(res.length - 1);
        score += m;
        if (m >= 2048) won = true;
        i += 2;
      } else {
        res.add(values[i]);
        i += 1;
      }
    }
    while (res.length < size) {
      res.add(0);
    }
    return (res, mergedIdx);
  }

  List<int> _readLine(String dir, int i) => [
        for (int k = 0; k < size; k++)
          switch (dir) {
            'left' => grid[i][k],
            'right' => grid[i][size - 1 - k],
            'up' => grid[k][i],
            _ => grid[size - 1 - k][i], // down
          }
      ];

  void _writeLine(String dir, int i, List<int> line) {
    for (int k = 0; k < size; k++) {
      final cell = _cellOf(dir, i, k);
      grid[cell[0]][cell[1]] = line[k];
    }
  }

  // Maps a line index back to a grid coordinate for the given direction.
  List<int> _cellOf(String dir, int i, int k) => switch (dir) {
        'left' => [i, k],
        'right' => [i, size - 1 - k],
        'up' => [k, i],
        _ => [size - 1 - k, i], // down
      };

  bool _move(String dir) {
    final snapGrid = [for (final row in grid) [...row]];
    final snapScore = score;
    final snapWon = won;

    final mergedCells = <List<int>>[];
    var moved = false;
    for (int i = 0; i < size; i++) {
      final line = _readLine(dir, i);
      final (next, mergedIdx) = _collapse(line);
      for (int k = 0; k < size; k++) {
        if (line[k] != next[k]) moved = true;
      }
      _writeLine(dir, i, next);
      for (final idx in mergedIdx) {
        mergedCells.add(_cellOf(dir, i, idx));
      }
    }

    if (moved) {
      _prevGrid = snapGrid;
      _prevScore = snapScore;
      _prevWon = snapWon;
      _canUndo = true;
      _addRandomTile();
      if (score > high) high = score;
      merged = mergedCells;
      flashTicks = flashAnimTicks;
      over = !_canMove();
    }
    return moved;
  }

  bool _canMove() {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == 0) return true;
        if (c + 1 < size && grid[r][c] == grid[r][c + 1]) return true;
        if (r + 1 < size && grid[r][c] == grid[r + 1][c]) return true;
      }
    }
    return false;
  }

  void undo() {
    if (!_canUndo) return;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        grid[r][c] = _prevGrid[r][c];
      }
    }
    score = _prevScore;
    won = _prevWon;
    over = false;
    merged = [];
    flashTicks = 0;
    _canUndo = false; // single-step undo
  }

  void input(String action) {
    if (action == 'undo') {
      undo();
      return;
    }
    if (over) {
      if (action == 'restart') reset();
      return;
    }
    switch (action) {
      case 'left':
      case 'right':
      case 'up':
      case 'down':
        _move(action);
        break;
      case 'restart':
        reset();
        break;
    }
  }

  void reset() {
    for (final row in grid) {
      row.fillRange(0, size, 0);
    }
    score = 0;
    won = false;
    over = false;
    merged = [];
    flashTicks = 0;
    _canUndo = false;
    _addRandomTile();
    _addRandomTile();
  }
}
