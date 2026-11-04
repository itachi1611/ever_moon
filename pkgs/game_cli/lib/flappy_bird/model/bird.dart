/// Bird - physics object for gravity and flapping
class Bird {
  double y = 0; // Row position (0 = ground, height - 1 = ceiling)
  double velocity = 0;

  static const double gravity = -0.15;  // Pulled down every tick
  static const double flapV = 1.0; // Upward impulse on a flap

  void flap() => velocity = flapV;

  void update() {
    velocity += gravity;
    y += velocity;
  }

  int get row => y.round();
}