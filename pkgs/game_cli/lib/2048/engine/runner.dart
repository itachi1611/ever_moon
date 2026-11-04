import '../../common/game_loop.dart';
import '../../common/settings.dart';
import '../ui/renderer.dart';
import 'game_2048.dart';

// Runs a 2048 game seeded with the saved best score, then persists it.
Future<void> run2048() async {
  final game = Game2048();
  game.high = settings.best2048;

  await runGameLoop(
    title: '2048',
    tickMs: 60,
    game: game,
    render: game.render,
    qualifies: settings.qualifies2048,
    submit: settings.add2048Score,
  );
}
