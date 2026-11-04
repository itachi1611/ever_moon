import '../engine/snake_game.dart';
import '../model/cell.dart';

// Renders the game state into terminal lines.
extension SnakeRenderer on SnakeGame {
  List<String> renderFrame() {
    final lines = <String>[];
    lines.add(' 🐍 SNAKE   score:$score   high:$high   len:${body.length}');
    // Wall frame — hitting it ends the game. Box chars are 1 display column
    // wide, matching the width*2 columns of the interior cells.
    final wall = '═' * (width * 2);
    lines.add('╔$wall╗');
    for (int r = height - 1; r >= 0; r--) {
      final sb = StringBuffer('║');
      for (int c = 0; c < width; c++) {
        sb.write(_cell(r, c));
      }
      sb.write('║');
      lines.add(sb.toString());
    }
    lines.add('╚$wall╝');
    lines.add(
      over
          ? '   💥 GAME OVER — Arrows/WASD to Retry, q to Quit'
          : paused
          ? '   ⏸  PAUSED — p to Resume   q Quit'
          : !started
          ? '   Arrows/WASD to Start   p Pause   q Quit'
          : '   Arrows/WASD Move   p Pause   q Quit',
    );
    return lines;
  }

  // Each cell is a 2-display-width token so emojis stay aligned.
  String _cell(int r, int c) {
    final p = Cell(c, r);
    if (body.first == p) return '🟢'; // head
    if (body.contains(p)) return '🟩'; // body
    if (food == p) return '🍎';
    return '  ';
  }
}
