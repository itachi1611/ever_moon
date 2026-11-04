import '../engine/dino_game.dart';
import '../model/obstacle.dart';

// Renders the game state into terminal lines.
extension DinoRenderer on DinoGame {
  List<String> renderFrame() {
    final lines = <String>[];
    lines.add(
      ' 🦖 DINO RUN   score:$score   high:$high   speed:${speed.toStringAsFixed(1)}',
    );
    for (int r = height - 1; r >= 0; r--) {
      final sb = StringBuffer();
      for (int c = 0; c < width; c++) {
        sb.write(_cell(r, c));
      }
      lines.add(sb.toString());
    }
    // Scrolling ground (every column is 2 terminal cells wide)
    final g = StringBuffer();
    for (int c = 0; c < width; c++) {
      g.write(((c - frame) % 6 + 6) % 6 == 0 ? '•‾' : '‾‾');
    }
    lines.add(g.toString());
    lines.add(over
        ? '   💥 GAME OVER — SPACE to Retry, q to Quit'
        : paused
        ? '   ⏸  PAUSED — p to Resume   q Quit'
        : '   SPACE/↑ Jump   ↓ Crouch   p Pause   q Quit');
    return lines;
  }

  // Each cell is a 2-display-width token so emojis stay aligned
  String _cell(int r, int c) {
    if (c == dinoCol && r == dino.low) {
      return dino.ducking ? '🦎' : '🦖';
    }
    for (final Obstacle o in obstacles) {
      if (o.x.round() == c && r == o.row) return o.sprite;
    }
    return '  ';
  }
}
