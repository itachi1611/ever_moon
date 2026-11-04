import 'dart:io' show stdout;

import '../../common/game_loop.dart';
import '../../common/settings.dart';
import '../ui/renderer.dart';
import 'dino_game.dart';

// Builds a Dino game sized to the terminal, runs it, then saves the high score.
Future<void> runDino() async {
  final termCols = stdout.hasTerminal ? stdout.terminalColumns : 80;
  final width = ((termCols ~/ 2) - 1).clamp(20, 45);
  const height = 7;
  final game = DinoGame(width, height, speedScale: settings.dinoSpeedValue);
  game.high = settings.dinoHigh;

  await runGameLoop(
    title: 'Dinosaur',
    tickMs: 70,
    game: game,
    render: game.renderFrame,
    qualifies: settings.qualifiesDino,
    submit: settings.addDinoScore,
  );
}
