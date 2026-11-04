import '../../common/ansi.dart';
import '../engine/game_2048.dart';

const _cellW = 6;

// Background/foreground 8-bit colors per tile value (2048-like palette).
(int, int) _style(int v) {
  switch (v) {
    case 0:
      return (236, 236);
    case 2:
      return (250, 235);
    case 4:
      return (223, 235);
    case 8:
      return (215, 235);
    case 16:
      return (209, 235);
    case 32:
      return (203, 235);
    case 64:
      return (202, 231);
    case 128:
      return (227, 235);
    case 256:
      return (226, 235);
    case 512:
      return (220, 235);
    case 1024:
      return (214, 235);
    case 2048:
      return (208, 231);
    default:
      return (201, 231); // beyond 2048
  }
}

String _center(String s, int w) {
  if (s.length >= w) return s.substring(0, w);
  final pad = w - s.length;
  final left = pad ~/ 2;
  return '${' ' * left}$s${' ' * (pad - left)}';
}

extension Game2048Renderer on Game2048 {
  List<String> render() {
    final out = <String>[];
    out.add('SCORE  $score        BEST  $high');
    out.add('');

    // Each tile is three lines tall so numbers sit inside a solid block.
    for (int r = 0; r < size; r++) {
      final top = StringBuffer();
      final mid = StringBuffer();
      final bot = StringBuffer();
      for (int c = 0; c < size; c++) {
        final v = grid[r][c];
        final flashing =
            flashTicks > 0 && merged.any((m) => m[0] == r && m[1] == c);
        final (bg, fg) = flashing ? (231, 235) : _style(v);
        final b = '${esc}48;5;${bg}m';
        final blank = '$b${' ' * _cellW}${esc}0m ';
        top.write(blank);
        mid.write('$b${esc}38;5;${fg}m${_center(v == 0 ? '' : '$v', _cellW)}'
            '${esc}0m ');
        bot.write(blank);
      }
      out.add(top.toString());
      out.add(mid.toString());
      out.add(bot.toString());
      out.add('');
    }

    if (won) out.add('🏆  2048! Congrats — keep going!');
    if (over) out.add('GAME OVER — press R to restart');
    if (paused) out.add('⏸  PAUSED — press p to resume');
    out.add('');
    out.add(paused
        ? 'p resume   q quit'
        : '←/↑/↓/→ or WASD move   U undo   R restart   p pause   q quit');
    return out;
  }
}
