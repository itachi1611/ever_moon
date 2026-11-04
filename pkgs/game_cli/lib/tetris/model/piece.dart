// A tetromino: 4x4 spawn grid ('X' = filled cell) + ANSI color code.
class Piece {
  final List<String> cells;
  final int color;
  const Piece(this.cells, this.color);
}

// The seven standard tetrominoes.
const pieces = <Piece>[
  Piece(['    ', 'XXXX', '    ', '    '], 36), // I cyan
  Piece([' XX ', ' XX ', '    ', '    '], 33), // O yellow
  Piece([' X  ', 'XXX ', '    ', '    '], 35), // T magenta
  Piece([' XX ', 'XX  ', '    ', '    '], 32), // S green
  Piece(['XX  ', ' XX ', '    ', '    '], 31), // Z red
  Piece(['X   ', 'XXX ', '    ', '    '], 34), // J blue
  Piece(['  X ', 'XXX ', '    ', '    '], 37), // L white
];
