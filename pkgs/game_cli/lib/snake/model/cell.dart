// A grid coordinate with value equality (so `body.contains(cell)` works).
class Cell {
  final int x;
  final int y;
  const Cell(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

// Movement direction. y increases upward (matches the renderer).
enum Direction {
  up(0, 1),
  down(0, -1),
  left(-1, 0),
  right(1, 0);

  final int dx;
  final int dy;
  const Direction(this.dx, this.dy);

  Direction get opposite => switch (this) {
    Direction.up => Direction.down,
    Direction.down => Direction.up,
    Direction.left => Direction.right,
    Direction.right => Direction.left,
  };
}