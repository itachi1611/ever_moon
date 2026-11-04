import '../engine/flappy_bird_game.dart';
import '../model/pipe.dart';

// Renders the game state into terminal lines.
extension FlappyRenderer on FlappyBirdGame {
  List<String> renderFrame() {
    final lines = <String>[];
    lines.add(
      ' 🐤 FLAPPY   score:$score   high:$high   speed:${speed.toStringAsFixed(1)}',
    );
    // Rows drawn top → bottom (row height-1 at the top).
    for (int r = height - 1; r >= 0; r--) {
      final sb = StringBuffer();
      for (int c = 0; c < width; c++) {
        sb.write(_cell(r, c));
      }
      lines.add(sb.toString());
    }
    lines.add(
      over
          ? '   💥 GAME OVER — SPACE to Retry, q to Quit'
          : paused
          ? '   ⏸  PAUSED — p to Resume   q Quit'
          : !started
          ? '   SPACE/↑ Start & Flap   q Quit'
          : '   SPACE/↑ Flap   p Pause   q Quit',
    );
    return lines;
  }

  // Each cell is a 2-display-width token so emojis stay aligned.
  String _cell(int r, int c) {
    if (c == birdCol && r == bird.row) return '🐤';
    for (final Pipe p in pipes) {
      if (p.x.round() == c && !p.openAt(r)) return '🟩';
    }
    return '  ';
  }
}