// Dino — physics for jumping and crouching.
class Dinosaur {
  double y = 0; // height above ground, in rows (0 = on ground)
  double velocity = 0;
  int duckTicks = 0; // remaining ticks in crouch pose

  static const double gravity = -0.45;
  static const double jumpV = 2.7;

  bool get onGround => y <= 0.0001;
  bool get ducking => duckTicks > 0 && onGround;

  void jump() {
    if (onGround) velocity = jumpV;
  }

  void duck() {
    if (onGround) duckTicks = 8;
  }

  void update() {
    velocity += gravity;
    y += velocity;
    if (y < 0) {
      y = 0;
      velocity = 0;
    }
    if (duckTicks > 0) duckTicks--;
  }

  int get low => y.floor();
  int get high => low + (ducking ? 0 : 1); // standing is 2 rows tall
}
