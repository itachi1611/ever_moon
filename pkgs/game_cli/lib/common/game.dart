// Shared contract for every tick-based game that runGameLoop can run.
// Rendering stays a per-game extension (ui/renderer.dart) and is passed to the
// loop separately — deliberately NOT part of this contract.
abstract class Game {
  int score = 0;
  int high = 0;
  bool over = false;
  bool quit = false;
  bool paused = false;

  // Advances the simulation by one tick ([ms] = tick duration in ms).
  void update(double ms);

  // Handles one decoded key token (see common/keys.dart).
  void handleKey(String key);

  // Ends the game and records a new personal best. Games that die on a
  // discrete event (dino/flappy/tetris/snake) call this; 2048 tracks its
  // best live and simply never calls it.
  void endGame() {
    over = true;
    if (score > high) high = score;
  }
}