// Pipe — a top+bottom pair with an open gap the bird must fly through.
class Pipe {
  double x; // column position, moves right → left
  final int gapStart; // lowest open row of the gap
  final int gapSize; // gap height in rows
  bool scored = false; // already counted when passing the bird

  Pipe(this.x, this.gapStart, this.gapSize);

  // True if [row] is inside the open gap (no pipe there).
  bool openAt(int row) => row >= gapStart && row < gapStart + gapSize;
}