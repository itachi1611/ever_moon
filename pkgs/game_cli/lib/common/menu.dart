import 'dart:async' show Completer;
import 'dart:io' show stdin, stdout;

import '../2048/game_2048.dart';
import '../dino/dino.dart';
import '../flappy_bird/flappy_bird.dart';
import '../snake/snake.dart';
import '../tetris/tetris.dart';
import 'ansi.dart';
import 'input.dart';
import 'settings.dart';

// Entry point: sets the terminal into raw mode, runs the menu, restores state.
Future<void> runMenu() async {
  final wasEcho = stdin.echoMode;
  final wasLine = stdin.lineMode;
  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
  } catch (_) {}
  settings.load();
  hideCursor();
  clearScreen();

  await _mainMenu();

  showCursor();
  clearScreen();
  cursorHome();
  try {
    stdin.echoMode = wasEcho;
    stdin.lineMode = wasLine;
  } catch (_) {}
}

const _mainItems = [
  'Tetris',
  'Dinosaur',
  '2048',
  'Flappy Bird',
  'Snake',
  'Settings',
  'High score',
];

Future<void> _mainMenu() async {
  int sel = 0;
  while (true) {
    _render([
      '',
      ..._header('GAME  CLI'),
      '',
      for (int i = 0; i < _mainItems.length; i++)
        _item(i == sel, _mainItems[i]),
      '',
      '   ↑/↓ or w/s move   Enter select   q quit',
    ]);
    switch (await _readKey()) {
      case 'up':
        sel = (sel - 1 + _mainItems.length) % _mainItems.length;
        break;
      case 'down':
        sel = (sel + 1) % _mainItems.length;
        break;
      case 'enter':
        switch (sel) {
          case 0:
            await runTetris();
            break;
          case 1:
            await runDino();
            break;
          case 2:
            await run2048();
            break;
          case 3:
            await runFlappy();
            break;
          case 4:
            await runSnake();
            break;
          case 5:
            await _settingsMenu();
            break;
          case 6:
            await _highScoreMenu();
            break;
        }
        hideCursor(); // games restore the cursor on exit
        clearScreen();
        break;
      case 'quit':
        return;
    }
  }
}

const _settingsItems = [
  'Tetris Setting',
  'Dinosaur Setting',
  '2048 Setting',
  'Flappy Bird Setting',
  'Snake Setting',
  'Back',
];

Future<void> _settingsMenu() async {
  int sel = 0;
  while (true) {
    _render([
      '',
      ..._header('SETTINGS'),
      '',
      for (int i = 0; i < _settingsItems.length; i++)
        _item(i == sel, _settingsItems[i]),
      '',
      '   ↑/↓ move   Enter select   q back',
    ]);
    switch (await _readKey()) {
      case 'up':
        sel = (sel - 1 + _settingsItems.length) % _settingsItems.length;
        break;
      case 'down':
        sel = (sel + 1) % _settingsItems.length;
        break;
      case 'enter':
        switch (sel) {
          case 0:
            await _tetrisSettings();
            break;
          case 1:
            await _dinoSettings();
            break;
          case 2:
            await _comingSoon('2048 SETTING');
            break;
          case 3:
            await _flappySettings();
            break;
          case 4:
            await _snakeSettings();
            break;
          case 5:
            return;
        }
        break;
      case 'quit':
        return;
    }
  }
}

// Tetris settings: board-size preset + drop-speed preset.
Future<void> _tetrisSettings() async {
  int sel = 0;
  const n = 3; // Board size, Drop speed, Back
  while (true) {
    _render([
      '',
      ..._header('TETRIS SETTING'),
      '',
      _optItem(sel == 0, 'Board size', settings.board.label),
      _optItem(sel == 1, 'Drop speed', tetrisSpeeds[settings.tetrisSpeed].label),
      _item(sel == 2, 'Back'),
      '',
      '   ↑/↓ move   ←/→ change   Enter select   q back',
    ]);
    switch (await _readKey()) {
      case 'up':
        sel = (sel - 1 + n) % n;
        break;
      case 'down':
        sel = (sel + 1) % n;
        break;
      case 'left':
        if (sel == 0) {
          settings.tetrisBoard = (settings.tetrisBoard - 1 + tetrisBoards.length) %
              tetrisBoards.length;
        } else if (sel == 1) {
          settings.tetrisSpeed = (settings.tetrisSpeed - 1 + tetrisSpeeds.length) %
              tetrisSpeeds.length;
        }
        break;
      case 'right':
        if (sel == 0) {
          settings.tetrisBoard = (settings.tetrisBoard + 1) % tetrisBoards.length;
        } else if (sel == 1) {
          settings.tetrisSpeed = (settings.tetrisSpeed + 1) % tetrisSpeeds.length;
        }
        break;
      case 'enter':
        if (sel == 2) return;
        break;
      case 'quit':
        return;
    }
    settings.save();
  }
}

// Dino settings: run-speed preset only.
Future<void> _dinoSettings() async {
  int sel = 0;
  const n = 2; // Speed, Back
  while (true) {
    _render([
      '',
      ..._header('DINOSAUR SETTING'),
      '',
      _optItem(sel == 0, 'Speed', dinoSpeeds[settings.dinoSpeed].label),
      _item(sel == 1, 'Back'),
      '',
      '   ↑/↓ move   ←/→ change   Enter select   q back',
    ]);
    switch (await _readKey()) {
      case 'up':
        sel = (sel - 1 + n) % n;
        break;
      case 'down':
        sel = (sel + 1) % n;
        break;
      case 'left':
        if (sel == 0) {
          settings.dinoSpeed =
              (settings.dinoSpeed - 1 + dinoSpeeds.length) % dinoSpeeds.length;
        }
        break;
      case 'right':
        if (sel == 0) {
          settings.dinoSpeed = (settings.dinoSpeed + 1) % dinoSpeeds.length;
        }
        break;
      case 'enter':
        if (sel == 1) return;
        break;
      case 'quit':
        return;
    }
    settings.save();
  }
}

// Flappy settings: scroll-speed preset only.
Future<void> _flappySettings() async {
  int sel = 0;
  const n = 2; // Speed, Back
  while (true) {
    _render([
      '',
      ..._header('FLAPPY SETTING'),
      '',
      _optItem(sel == 0, 'Speed', flappySpeeds[settings.flappySpeed].label),
      _item(sel == 1, 'Back'),
      '',
      '   ↑/↓ move   ←/→ change   Enter select   q back',
    ]);
    switch (await _readKey()) {
      case 'up':
        sel = (sel - 1 + n) % n;
        break;
      case 'down':
        sel = (sel + 1) % n;
        break;
      case 'left':
        if (sel == 0) {
          settings.flappySpeed =
              (settings.flappySpeed - 1 + flappySpeeds.length) % flappySpeeds.length;
        }
        break;
      case 'right':
        if (sel == 0) {
          settings.flappySpeed = (settings.flappySpeed + 1) % flappySpeeds.length;
        }
        break;
      case 'enter':
        if (sel == 1) return;
        break;
      case 'quit':
        return;
    }
    settings.save();
  }
}

// Snake settings: step-speed preset only.
Future<void> _snakeSettings() async {
  int sel = 0;
  const n = 2; // Speed, Back
  while (true) {
    _render([
      '',
      ..._header('SNAKE SETTING'),
      '',
      _optItem(sel == 0, 'Speed', snakeSpeeds[settings.snakeSpeed].label),
      _item(sel == 1, 'Back'),
      '',
      '   ↑/↓ move   ←/→ change   Enter select   q back',
    ]);
    switch (await _readKey()) {
      case 'up':
        sel = (sel - 1 + n) % n;
        break;
      case 'down':
        sel = (sel + 1) % n;
        break;
      case 'left':
        if (sel == 0) {
          settings.snakeSpeed =
              (settings.snakeSpeed - 1 + snakeSpeeds.length) % snakeSpeeds.length;
        }
        break;
      case 'right':
        if (sel == 0) {
          settings.snakeSpeed = (settings.snakeSpeed + 1) % snakeSpeeds.length;
        }
        break;
      case 'enter':
        if (sel == 1) return;
        break;
      case 'quit':
        return;
    }
    settings.save();
  }
}

const _highScoreItems = [
  'Tetris',
  'Dinosaur',
  '2048',
  'Flappy Bird',
  'Snake',
  'Back',
];

Future<void> _highScoreMenu() async {
  int sel = 0;
  while (true) {
    _render([
      '',
      ..._header('HIGH SCORES'),
      '',
      for (int i = 0; i < _highScoreItems.length; i++)
        _item(i == sel, _highScoreItems[i]),
      '',
      '   ↑/↓ move   Enter view   q back',
    ]);
    switch (await _readKey()) {
      case 'up':
        sel = (sel - 1 + _highScoreItems.length) % _highScoreItems.length;
        break;
      case 'down':
        sel = (sel + 1) % _highScoreItems.length;
        break;
      case 'enter':
        switch (sel) {
          case 0:
            await _showScores('TETRIS', settings.tetrisScores);
            break;
          case 1:
            await _showScores('DINOSAUR', settings.dinoScores);
            break;
          case 2:
            await _showScores('2048', settings.scores2048);
            break;
          case 3:
            await _showScores('FLAPPY BIRD', settings.flappyScores);
            break;
          case 4:
            await _showScores('SNAKE', settings.snakeScores);
            break;
          case 5:
            return;
        }
        break;
      case 'quit':
        return;
    }
  }
}

// Shows the top-15 leaderboard for a game.
Future<void> _showScores(String title, List<ScoreEntry> scores) async {
  final lines = <String>['', ..._header('$title  TOP 15'), ''];
  if (scores.isEmpty) {
    lines.add('        No scores yet');
  } else {
    for (int i = 0; i < scores.length; i++) {
      final rank = '${i + 1}'.padLeft(2);
      final e = scores[i];
      final name = e.name.length > 12
          ? e.name.substring(0, 12)
          : e.name.padRight(12);
      final row = '   $rank.  $name ${e.score}';
      lines.add(i == 0 ? '${esc}1m${esc}36m$row${esc}0m' : row);
    }
  }
  lines.add('');
  lines.add('   Press any key to go back');
  _render(lines);
  await _anyKey();
}

Future<void> _comingSoon(String title) async {
  _render([
    '',
    ..._header(title),
    '',
    '      Coming soon.',
    '',
    '   Press any key to go back',
  ]);
  await _anyKey();
}

// Drawing helpers

List<String> _header(String title) {
  const w = 26;
  final t = title.length > w ? title.substring(0, w) : title;
  final pad = w - t.length;
  final left = pad ~/ 2;
  final right = pad - left;
  return [
    '   ╔${'═' * w}╗',
    '   ║${' ' * left}$t${' ' * right}║',
    '   ╚${'═' * w}╝',
  ];
}

String _item(bool selected, String text) {
  final marker = selected ? '▶' : ' ';
  final label = selected ? '${esc}36m$text${esc}0m' : text;
  return '      $marker  $label';
}

String _optItem(bool selected, String name, String value) {
  final shown = selected ? '‹ $value ›' : '  $value';
  return _item(selected, '${name.padRight(12)}$shown');
}

// Draws in place (no scrolling): home the cursor, overwrite each line and
// clear anything left below.
void _render(List<String> lines) {
  cursorHome();
  stdout.write(lines.map((l) => '$l${esc}K').join('\n'));
  stdout.write('${esc}J');
}

// Input helpers

// Waits for a single mapped key and returns the action.
Future<String> _readKey() {
  final completer = Completer<String>();
  onKey((data) {
    for (int i = 0; i < data.length; i++) {
      final x = data[i];
      String? action;
      if (x == 3 || x == 113) {
        action = 'quit'; // Ctrl-C or q
      } else if (x == 13 || x == 10) {
        action = 'enter';
      } else if (x == 119 || x == 87) {
        action = 'up'; // w
      } else if (x == 115 || x == 83) {
        action = 'down'; // s
      } else if (x == 97 || x == 65) {
        action = 'left'; // a
      } else if (x == 100 || x == 68) {
        action = 'right'; // d
      } else if (x == 27 && i + 2 < data.length && data[i + 1] == 91) {
        switch (data[i + 2]) {
          case 65:
            action = 'up';
            break;
          case 66:
            action = 'down';
            break;
          case 68:
            action = 'left';
            break;
          case 67:
            action = 'right';
            break;
        }
      }
      if (action != null) {
        offKey();
        if (!completer.isCompleted) completer.complete(action);
        return;
      }
    }
  });
  return completer.future;
}

// Waits for any key press.
Future<void> _anyKey() {
  final completer = Completer<void>();
  onKey((_) {
    offKey();
    if (!completer.isCompleted) completer.complete();
  });
  return completer.future;
}
