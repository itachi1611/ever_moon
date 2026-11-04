// Game state and update rules. Rendering lives in ../ui/renderer.dart.
import 'dart:math';

import '../../common/game.dart' show Game;
import '../model/bird.dart' show Bird;
import '../model/pipe.dart' show Pipe;

class FlappyBirdGame extends Game {
  final int width;
  final int height;
  // Bird sits on the right third; pipes scroll in from the left so the
  // left-facing 🐤 emoji faces the oncoming pipes.
  late final int birdCol = (width * 2) ~/ 3;
  final rng = Random();

  final Bird bird = Bird();
  final List<Pipe> pipes = [];

  final double speedScale; // 1.0 = default speed
  double speed = 0.5; // columns moved per tick (recomputed each update)
  double spawnGap = 14; // distance between pipe spawns
  double sinceSpawn = 0;
  int frame = 0;
  bool started = false; // idle until the first flap

  FlappyBirdGame(this.width, this.height, {this.speedScale = 1.0}) {
    bird.y = height / 2; // start hovering in the middle
  }

  @override
  void update(double ms) {
    if (over || !started) return;
    frame++;

    // Difficulty: speed ramps with score, scaled by the settings preset.
    speed = (0.5 + score * 0.02).clamp(0.5, 1.4) * speedScale;

    bird.update();

    // Ceiling clamps; touching the ground ends the game.
    if (bird.y >= height - 1) {
      bird.y = height - 1.0;
      bird.velocity = 0;
    }
    if (bird.y <= 0) {
      bird.y = 0;
      endGame();
      return;
    }

    // Pipes move right; drop the ones fully off-screen.
    for (final p in pipes) {
      p.x += speed;
    }
    pipes.removeWhere((p) => p.x > width + 1);

    // Spawn a new pipe pair after enough distance.
    sinceSpawn += speed;
    if (sinceSpawn >= spawnGap) {
      sinceSpawn = 0;
      spawnGap = 12 + rng.nextInt(8).toDouble();
      final g = gapSize;
      final start = 1 + rng.nextInt(height - g - 1);
      pipes.add(Pipe(-1.0, start, g));
    }

    // Collision + scoring.
    final br = bird.row;
    for (final p in pipes) {
      if ((p.x - birdCol).abs() < 1.0 && !p.openAt(br)) {
        endGame();
        return;
      }
      if (!p.scored && p.x > birdCol) {
        p.scored = true;
        score++;
      }
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
      case 'w':
      case 'arrowUp':
        input('flap');
        break;
    }
  }

  // Gap shrinks as the score climbs — never below 4 rows.
  int get gapSize => max(4, 7 - score ~/ 5);

  void input(String action) {
    if (action != 'flap') return;
    if (over) {
      restart();
      return;
    }
    started = true;
    bird.flap();
  }

  void restart() {
    pipes.clear();
    bird
      ..y = height / 2
      ..velocity = 0;
    sinceSpawn = 0;
    score = 0;
    started = false;
    over = false;
  }
}