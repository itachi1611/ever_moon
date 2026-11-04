import 'dart:io' show stdout;

import '../../common/game_loop.dart';
import '../../common/settings.dart';
import '../ui/renderer.dart';
import 'flappy_bird_game.dart';

// Builds a Flappy game sized to the terminal, runs it, then saves the score.
Future<void> runFlappy() async {
  final termCols = stdout.hasTerminal ? stdout.terminalColumns : 80;
  final width = ((termCols ~/ 2) - 1).clamp(20, 45);
  const height = 14;
  final game = FlappyBirdGame(width, height, speedScale: settings.flappySpeedValue);
  game.high = settings.flappyHigh;

  await runGameLoop(
    title: 'Flappy Bird',
    tickMs: 90,
    game: game,
    render: game.renderFrame,
    qualifies: settings.qualifiesFlappy,
    submit: settings.addFlappyScore,
  );
}