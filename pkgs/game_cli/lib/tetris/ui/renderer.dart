import '../../common/ansi.dart';
import '../engine/tetris_game.dart';
import '../model/piece.dart';

// Empty cells: a full-height dark cell (background) with a faint dotted grid
// texture on top. The background makes every cell the same height as a block,
// so pieces stay aligned to the row grid instead of floating between dot rows.
const _gridCell = '${esc}48;5;236m${esc}38;5;240m··${esc}0m';

// Renders the board (with the active piece) and a side info panel.
extension TetrisRenderer on TetrisGame {
  // Fill the whole cell with a background color instead of drawing '██' glyphs,
  // which leave vertical gaps between rows in many terminal fonts.
  String _block(int color) => '$esc${color + 10}m  ${esc}0m';

  List<String> render() {
    final view = [for (final row in board) [...row]];
    // Ghost: where the piece would land (drawn first so the piece overwrites).
    final gy = ghostY;
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (!shape[r][c]) continue;
        final x = px + c, y = gy + r;
        if (y >= 0 && y < rows && x >= 0 && x < cols && view[y][x] == 0) {
          view[y][x] = -1; // ghost marker
        }
      }
    }
    // Active piece overlay.
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (!shape[r][c]) continue;
        final x = px + c, y = py + r;
        if (y >= 0 && y < rows && x >= 0 && x < cols) view[y][x] = color;
      }
    }

    // The play field with borders
    final boardLines = <String>[];
    boardLines.add('┌${'──' * cols}┐');
    for (int y = 0; y < rows; y++) {
      final sb = StringBuffer('│');
      // Rows being cleared blink bright white before they are removed.
      final flash = clearing.contains(y) && (clearTicks ~/ 2).isEven;
      for (int x = 0; x < cols; x++) {
        final v = view[y][x];
        if (flash) {
          sb.write('${esc}107m  ${esc}0m');
        } else if (v == -1) {
          sb.write('${esc}48;5;239m  ${esc}0m'); // ghost footprint
        } else {
          sb.write(v == 0 ? _gridCell : _block(v));
        }
      }
      sb.write('│');
      boardLines.add(sb.toString());
    }
    boardLines.add('└${'──' * cols}┘');

    // The info panel shown to the right of the field
    final panel = <String>[];
    panel.add('T E T R I S');
    panel.add('');
    panel.add('SCORE   $score');
    panel.add('HIGH    $high');
    panel.add('LINES   $lines');
    panel.add('LEVEL   $level');
    panel.add('');
    panel.add('NEXT');
    final ng = gridOf(nextIndex);
    for (int r = 0; r < 4; r++) {
      if (!ng[r].any((b) => b)) continue;
      final sb = StringBuffer(' ');
      for (int c = 0; c < 4; c++) {
        sb.write(ng[r][c] ? _block(pieces[nextIndex].color) : '  ');
      }
      panel.add(sb.toString());
    }
    panel.add('');
    if (over) {
      panel.add('GAME OVER');
      panel.add('SPACE  retry');
      panel.add('');
    } else if (paused) {
      panel.add('⏸ PAUSED');
      panel.add('p  resume');
      panel.add('');
    }
    panel.add('Move ←/→  Rotate ↑  Soft ↓');
    panel.add('Drop SPACE   p Pause   q Quit');

    // Merge the field and the panel line by line (the field is the taller one)
    final out = <String>[];
    for (int i = 0; i < boardLines.length; i++) {
      final p = i < panel.length ? panel[i] : '';
      out.add('${boardLines[i]}   $p');
    }
    return out;
  }
}
