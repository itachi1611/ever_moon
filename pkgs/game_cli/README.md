# game_cli

Terminal mini-games written in pure Dart: a Dino runner and Tetris.

## Run

```bash
cd pkgs/game_cli
dart pub get

dart run              # opens the menu to pick a game
```

## Controls

Menu — `↑/↓` or `w/s` select, `Enter` play, `q` quit. After a game ends you return here.
Dino — `SPACE`/`↑`/`w` jump, `↓`/`s` crouch, `q` back to menu.
Tetris — `←/→` or `a/d` move, `↑`/`w` rotate, `↓`/`s` soft drop, `SPACE` hard drop, `q` back to menu.

## Structure

```
lib/
├── common/ansi.dart        # shared ANSI helpers
├── dino/
│   ├── dino.dart           # barrel
│   ├── model/              # Dino, Obstacle
│   ├── engine/             # Game logic + runner
│   └── ui/renderer.dart    # frame rendering
└── tetris/
    ├── tetris.dart         # barrel
    ├── model/              # Piece + pieces
    ├── engine/             # Tetris logic + runner
    └── ui/renderer.dart    # board rendering
```
