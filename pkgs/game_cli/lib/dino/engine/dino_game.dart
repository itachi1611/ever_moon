import 'dart:math' show Random;

import '../../common/game.dart' show Game;
import '../model/dino.dart';
import '../model/obstacle.dart';

// Game state and update rules. Rendering lives in ../ui/renderer.dart.
class DinoGame extends Game {
  final int width;
  final int height;
  // Dino sits on the right; the 🦖 emoji faces left, toward incoming obstacles.
  late final int dinoCol = width - 4;
  final rng = Random();

  final Dinosaur dino = Dinosaur();
  final List<Obstacle> obstacles = [];

  final double speedScale; // 1.0 = default speed
  late double speed = 0.6 * speedScale; // columns moved per tick
  double spawnGap = 18;
  double sinceSpawn = 0;
  int frame = 0;

  DinoGame(this.width, this.height, {this.speedScale = 1.0});

  @override
  void update(double ms) {
    if (over) return;
    frame++;
    dino.update();

    // Obstacles enter from the left and move right toward the dino
    for (final o in obstacles) {
      o.x += speed;
    }
    obstacles.removeWhere((o) => o.x > width + 1);

    // Spawn a new obstacle after enough distance
    sinceSpawn += speed;
    if (sinceSpawn >= spawnGap) {
      sinceSpawn = 0;
      spawnGap = 14 + rng.nextInt(14).toDouble();
      final kind = rng.nextBool() ? ObstacleKind.cactus : ObstacleKind.bird;
      obstacles.add(Obstacle(-1, kind));
    }

    // Collision: obstacle column near the dino column and rows overlap
    for (final o in obstacles) {
      if ((o.x - dinoCol).abs() < 1.0) {
        final hitByRow = dino.low <= o.row && dino.high >= o.row;
        if (hitByRow) {
          endGame();
        }
      }
    }

    // Score and gradual difficulty
    score++;
    if (score % 50 == 0 && speed < 1.5 * speedScale) speed += 0.12 * speedScale;
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
        input('jump');
        break;
      case 's':
      case 'arrowDown':
        input('duck');
        break;
    }
  }

  void input(String action) {
    if (over) {
      if (action == 'jump') restart();
      return;
    }
    if (action == 'jump') dino.jump();
    if (action == 'duck') dino.duck();
  }

  void restart() {
    obstacles.clear();
    dino
      ..y = 0
      ..velocity = 0
      ..duckTicks = 0;
    speed = 0.6 * speedScale;
    sinceSpawn = 0;
    score = 0;
    over = false;
  }
}
