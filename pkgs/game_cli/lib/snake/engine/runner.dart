import 'dart:io' show stdout;

import '../../common/game_loop.dart';
import '../../common/settings.dart';
import '../ui/renderer.dart';
import 'snake_game.dart';

// Builds a Snake game sized to the terminal, runs it, then saves the score.
Future<void> runSnake() async {
  final termCols = stdout.hasTerminal ? stdout.terminalColumns : 80;
  final width = ((termCols ~/ 2) - 1).clamp(16, 40);
  const height = 16;
  final game = SnakeGame(width, height, speedScale: settings.snakeSpeedValue)
    ..high = settings.snakeHigh;

  await runGameLoop(
    title: 'Snake',
    tickMs: 60,
    game: game,
    render: game.renderFrame,
    qualifies: settings.qualifiesSnake,
    submit: settings.addSnakeScore,
  );
}