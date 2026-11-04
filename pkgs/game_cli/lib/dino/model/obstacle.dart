enum ObstacleKind { cactus, bird }

// Obstacle — cactus on the ground, bird one row up.
class Obstacle {
  double x;
  final ObstacleKind kind;
  Obstacle(this.x, this.kind);

  int get row => kind == ObstacleKind.bird ? 1 : 0;
  String get sprite => kind == ObstacleKind.bird ? '🦅' : '🌵';
}
