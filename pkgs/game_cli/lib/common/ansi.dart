import 'dart:io' show stdout;

// ANSI escape helpers shared by all games.
const esc = '\x1B[';

void clearScreen() => stdout.write('${esc}2J');
void cursorHome() => stdout.write('${esc}H');
void hideCursor() => stdout.write('$esc?25l');
void showCursor() => stdout.write('$esc?25h');

final _ansiPattern = RegExp('\x1B\\[[0-9;?]*[a-zA-Z]');

// Visible width of a line, ignoring ANSI escape codes.
int _visibleWidth(String s) => s.replaceAll(_ansiPattern, '').length;

// Pads a block of lines with a left and top margin so it sits roughly centered
// in the terminal instead of the top-left corner. Blank lines stay empty.
List<String> centered(List<String> lines) {
  final cols = stdout.hasTerminal ? stdout.terminalColumns : 80;
  final rows = stdout.hasTerminal ? stdout.terminalLines : 24;
  var maxW = 0;
  for (final l in lines) {
    final w = _visibleWidth(l);
    if (w > maxW) maxW = w;
  }
  final left = ((cols - maxW) ~/ 2).clamp(0, cols);
  final top = ((rows - lines.length) ~/ 2).clamp(0, rows);
  final pad = ' ' * left;
  return [
    for (var i = 0; i < top; i++) '',
    for (final l in lines) l.isEmpty ? '' : '$pad$l',
  ];
}
