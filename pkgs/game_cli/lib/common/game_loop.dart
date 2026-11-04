import 'dart:async' show Completer, Timer;
import 'dart:io' show stdout, stdin;

import 'ansi.dart';
import 'app_info.dart';
import 'game.dart' show Game;
import 'input.dart';
import 'keys.dart';

// Runs a game on the alternate screen with a fixed-tick loop. Handles raw-mode
// setup/teardown, the title header, centering, frame diffing and cleanup, so
// each game only supplies its update/render/input logic. Returns when
// [shouldQuit] becomes true.
//
// If the high-score hooks are provided, then whenever [isOver] first becomes
// true and [qualifies] accepts the score, the loop pauses the game and shows a
// name-entry prompt; on Enter it calls [submit] with the typed name.
Future<void> runGameLoop({
  required String title,
  required int tickMs,
  required Game game,
  required List<String> Function() render,
  bool Function(int score)? qualifies,
  void Function(String name, int score)? submit,
}) async {
  final wasEcho = stdin.echoMode;
  final wasLine = stdin.lineMode;
  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
  } catch (_) {}
  stdout.write('$esc?1049h'); // enter alternate screen
  hideCursor();
  clearScreen();

  final done = Completer<void>();
  late Timer timer;

  final canScore = qualifies != null && submit != null;
  var capturing = false; // entering a high-score name
  var handledOver = false; // this game-over already processed
  var nameBuf = '';

  void cleanup() {
    timer.cancel();
    offKey();
    showCursor();
    stdout.write('$esc?1049l'); // leave alternate screen
    try {
      stdin.echoMode = wasEcho;
      stdin.lineMode = wasLine;
    } catch (_) {}
  }

  onKey((data) {
    for (final k in decodeKeys(data)) {
      if (capturing) {
        if (k == 'enter') {
          final name = nameBuf
              .trim()
              .isEmpty ? 'YOU' : nameBuf.trim();
          submit!(name, game.score);
          capturing = false;
        } else if (k == 'backspace') {
          if (nameBuf.isNotEmpty) {
            nameBuf = nameBuf.substring(0, nameBuf.length - 1);
          }
        } else if (k == 'space') {
          if (nameBuf.length < 12) nameBuf += ' ';
        } else if (k.length == 1 && RegExp(r'[a-z0-9]').hasMatch(k)) {
          if (nameBuf.length < 12) nameBuf += k;
        }
      } else if (k == 'p' && !game.over) {
        game.paused = !game.paused;
      } else if (!game.paused || k == 'q' || k == 'ctrlC'){
        game.handleKey(k);
      }
    }
  });

  List<String> promptLines(int score) => [
        '',
        '${esc}1m${esc}33mNEW HIGH SCORE!${esc}0m',
        'Score: $score',
        '',
        'Enter your name:',
        '${esc}36m${nameBuf}_${esc}0m',
        '',
        'Enter to save',
      ];

  String? last;
  timer = Timer.periodic(Duration(milliseconds: tickMs), (t) {
    if (game.quit) {
      cleanup();
      if (!done.isCompleted) done.complete();
      return;
    }

    if (game.over) game.paused = false;

    if (!capturing) {
      if (!game.paused) game.update(tickMs.toDouble());
      if (canScore && game.over) {
        if (!handledOver) {
          handledOver = true;
          if (qualifies(game.score)) {
            capturing = true;
            nameBuf = '';
          }
        }
      } else {
        handledOver = false;
      }
    }
    final body = capturing ? promptLines(game.score) : render();
    final frame = centered([
      '${esc}1m${esc}36m$title${esc}0m',
      '${esc}2mv$appVersion - Made by $appAuthor${esc}0m',
      '',
      ...body,
    ]).map((l) => '$l${esc}K').join('\n');
    if (frame != last) {
      last = frame;
      cursorHome();
      stdout.write(frame);
    }
  });

  await done.future;
}
