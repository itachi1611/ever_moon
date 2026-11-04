import 'dart:math' show Random;

import '../../common/game.dart' show Game;
import '../model/cell.dart';

// Snake state and rules. Rendering lives in ../ui/renderer.dart.
class SnakeGame extends Game {
  final int width;
  final int height;
  final rng = Random();

  final List<Cell> body = []; // head at index 0
  Direction dir = Direction.right; // committed direction
  Direction pending = Direction.right; // next turn, applied on the next step
  late Cell food;

  final double speedScale; // 1.0 = default speed
  double stepAccum = 0; // fractional steps carried between ticks
  bool started = false; // idle until the first key

  SnakeGame(this.width, this.height, {this.speedScale = 1.0}) {
    restart();
  }

  @override
  void update(double ms) {
    if (over || !started) return;
    stepAccum += stepRate;
    while (stepAccum >= 1) {
      stepAccum -= 1;
      _step();
      if (over) return;
    }
  }

  @override
  void handleKey(String key) {
    switch (key) {
      case 'q':
      case 'ctrlC':
        quit = true;
        break;
      case 'w':
      case 'arrowUp':
        _turn(Direction.up);
        break;
      case 's':
      case 'arrowDown':
        _turn(Direction.down);
        break;
      case 'a':
      case 'arrowLeft':
        _turn(Direction.left);
        break;
      case 'd':
      case 'arrowRight':
        _turn(Direction.right);
        break;
    }
  }

  // Steps per tick: ramps with score, scaled by the settings preset.
  double get stepRate => (0.22 + score * 0.006).clamp(0.22, 0.7) * speedScale;

  void _turn(Direction d) {
    if (over) {
      restart();
      return; // any move key restarts after game over
    }
    started = true;
    if (d != dir.opposite) pending = d; // can't reverse into itself
  }

  void restart() {
    final cx = width ~/ 2;
    final cy = height ~/ 2;
    body
      ..clear()
      ..addAll([Cell(cx, cy), Cell(cx - 1, cy), Cell(cx - 2, cy)]);
    dir = Direction.right;
    pending = Direction.right;
    stepAccum = 0;
    score = 0;
    started = false;
    over = false;
    _spawnFood();
  }

  void _step() {
    dir = pending; // commit the queued turn
    final head = body.first;
    final nx = head.x + dir.dx;
    final ny = head.y + dir.dy;

    // Wall collision — hitting the edge is death.
    if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
      endGame();
      return;
    }

    final newHead = Cell(nx, ny);
    final eating = newHead == food;

    // Self collision. When not eating, the tail vacates this step, so the
    // last segment is a legal target — exclude it from the check.
    final checkLen = eating ? body.length : body.length - 1;
    for (int i = 0; i < checkLen; i++) {
      if (body[i] == newHead) {
        endGame();
        return;
      }
    }

    body.insert(0, newHead);
    if (eating) {
      score++;
      _spawnFood();
    } else {
      body.removeLast();
    }
  }

  // Places food on a random free cell; a full board ends the game (a win).
  void _spawnFood() {
    final free = <Cell>[];
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final c = Cell(x, y);
        if (!body.contains(c)) free.add(c);
      }
    }
    if (free.isEmpty) {
      endGame();
      return;
    }
    food = free[rng.nextInt(free.length)];
  }
}