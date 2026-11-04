import '../../common/game_loop.dart';
import '../../common/settings.dart';
import '../ui/renderer.dart';
import 'tetris_game.dart';

// Builds a Tetris game from the current settings, runs it, then saves the high
// score.
Future<void> runTetris() async {
  final board = settings.board;
  final game = TetrisGame(
    cols: board.cols,
    rows: board.rows,
    speedMultiplier: settings.tetrisSpeedValue,
    high: settings.tetrisHigh,
  );
  await runGameLoop(
    title: 'Tetris',
    tickMs: 30,
    game: game,
    render: game.render,
    qualifies: settings.qualifiesTetris,
    submit: settings.addTetrisScore,
  );
}
