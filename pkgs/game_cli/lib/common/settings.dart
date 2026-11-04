import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show Directory, File, Platform;

// Shared game settings + high scores. Adjusted from the Settings menu, read by
// the game runners, and persisted to ~/.game_cli.json across runs.

// Tetris board-size presets. Users pick from this list so they can never enter
// an invalid column/row count.
class BoardPreset {
  final int cols;
  final int rows;
  const BoardPreset(this.cols, this.rows);
  String get label => '$cols x $rows';
}

const tetrisBoards = <BoardPreset>[
  BoardPreset(10, 20), // Standard (default)
  BoardPreset(8, 16), // Small
  BoardPreset(12, 22), // Wide
  BoardPreset(14, 24), // Huge
];

// A named speed multiplier. 1.0 = the game's current/default speed.
class SpeedPreset {
  final String label;
  final double value;
  const SpeedPreset(this.label, this.value);
}

// Tetris drop speed — higher value makes pieces fall faster.
const tetrisSpeeds = <SpeedPreset>[
  SpeedPreset('Normal', 1.0), // default = current speed
  SpeedPreset('Fast', 1.4),
  SpeedPreset('Faster', 1.8),
  SpeedPreset('Turbo', 2.4),
];

// Dino run speed — higher value makes the game run faster.
const dinoSpeeds = <SpeedPreset>[
  SpeedPreset('Normal', 1.0), // default = current speed
  SpeedPreset('Fast', 1.3),
  SpeedPreset('Faster', 1.6),
  SpeedPreset('Turbo', 2.0),
];

// Flappy bird run speed - higher value makes pipes scroll faster
const flappySpeeds = <SpeedPreset>[
  SpeedPreset('Normal', 1.0), // Default speed
  SpeedPreset('Fast', 1.3),
  SpeedPreset('Faster', 1.6),
  SpeedPreset('Turbo', 2.0),
];

// Snake speed — higher value makes the snake step faster.
const snakeSpeeds = <SpeedPreset>[
  SpeedPreset('Normal', 1.0),
  SpeedPreset('Fast', 1.3),
  SpeedPreset('Faster', 1.6),
  SpeedPreset('Turbo', 2.0),
];

// A single leaderboard entry: player name + score.
class ScoreEntry {
  final String name;
  final int score;
  const ScoreEntry(this.name, this.score);

  Map<String, dynamic> toJson() => {'name': name, 'score': score};

  static ScoreEntry? fromJson(dynamic v) {
    if (v is Map && v['score'] is int) {
      final n = v['name'];
      return ScoreEntry(n is String && n.isNotEmpty ? n : '---', v['score']);
    }
    if (v is int && v > 0) return ScoreEntry('---', v); // legacy bare int
    return null;
  }
}

// Selected option indices + named leaderboards, shared across the app.
class GameSettings {
  int tetrisBoard = 0;
  int tetrisSpeed = 0;
  int dinoSpeed = 0;
  int flappySpeed = 0;
  int snakeSpeed = 0;

  // Leaderboards per game, sorted high → low (max 15 entries).
  List<ScoreEntry> tetrisScores = [];
  List<ScoreEntry> dinoScores = [];
  List<ScoreEntry> scores2048 = [];
  List<ScoreEntry> flappyScores = [];
  List<ScoreEntry> snakeScores = [];

  BoardPreset get board => tetrisBoards[tetrisBoard];
  double get tetrisSpeedValue => tetrisSpeeds[tetrisSpeed].value;
  double get dinoSpeedValue => dinoSpeeds[dinoSpeed].value;
  double get flappySpeedValue  => flappySpeeds[flappySpeed].value;
  double get snakeSpeedValue  => snakeSpeeds[snakeSpeed].value;

  // Best score per game (top of its leaderboard) for the in-game display.
  int get tetrisHigh => tetrisScores.isEmpty ? 0 : tetrisScores.first.score;
  int get dinoHigh => dinoScores.isEmpty ? 0 : dinoScores.first.score;
  int get best2048 => scores2048.isEmpty ? 0 : scores2048.first.score;
  int get flappyHigh => flappyScores.isEmpty ? 0 : flappyScores.first.score;
  int get snakeHigh => snakeScores.isEmpty ? 0 : snakeScores.first.score;

  static const int maxRanks = 15;

  // True if [score] would make the top-15 leaderboard for that game.
  bool qualifiesTetris(int s) => _qualifies(tetrisScores, s);
  bool qualifiesDino(int s) => _qualifies(dinoScores, s);
  bool qualifies2048(int s) => _qualifies(scores2048, s);
  bool qualifiesFlappy(int s) => _qualifies(flappyScores, s);
  bool qualifiesSnake(int s) => _qualifies(snakeScores, s);

  bool _qualifies(List<ScoreEntry> list, int score) =>
      score > 0 && (list.length < maxRanks || score > list.last.score);

  void addTetrisScore(String name, int s) => _record(tetrisScores, name, s);
  void addDinoScore(String name, int s) => _record(dinoScores, name, s);
  void add2048Score(String name, int s) => _record(scores2048, name, s);
  void addFlappyScore(String name, int s) => _record(flappyScores, name, s);
  void addSnakeScore(String name, int s) => _record(snakeScores, name, s);

  void _record(List<ScoreEntry> list, String name, int score) {
    if (score <= 0) return;
    list.add(ScoreEntry(name.isEmpty ? '---' : name, score));
    list.sort((a, b) => b.score.compareTo(a.score));
    if (list.length > maxRanks) list.removeRange(maxRanks, list.length);
    save();
  }

  static final File _file = _resolveDbFile();

  // Finds the package root (folder with pubspec.yaml) and points at lib/db,
// so the path is correct no matter which directory the game is launched from.
  static File _resolveDbFile() {
    Directory dir;
    try {
      dir = File.fromUri(Platform.script).parent;
    } catch (_) {
      dir = Directory.current;
    }
    while (true) {
      if (File('${dir.path}/pubspec.yaml').existsSync()) break;
      final parent = dir.parent;
      if (parent.path == dir.path) break; // reached filesystem root — give up
      dir = parent;
    }
    return File('${dir.path}/lib/db/game_cli.json');
  }

  // Loads persisted settings/scores; ignores a missing or corrupt file.
  void load() {
    try {
      if (!_file.existsSync()) return;
      final m = jsonDecode(_file.readAsStringSync()) as Map<String, dynamic>;
      tetrisBoard = _clampIndex(m['tetrisBoard'], tetrisBoards.length);
      tetrisSpeed = _clampIndex(m['tetrisSpeed'], tetrisSpeeds.length);
      dinoSpeed = _clampIndex(m['dinoSpeed'], dinoSpeeds.length);
      flappySpeed = _clampIndex(m['flappySpeed'], flappySpeeds.length);
      snakeSpeed = _clampIndex(m['snakeSpeed'], snakeSpeeds.length);
      tetrisScores = _scores(m['tetrisScores']);
      dinoScores = _scores(m['dinoScores']);
      scores2048 = _scores(m['scores2048']);
      flappyScores = _scores(m['flappyScores']);
      snakeScores = _scores(m['snakeScores']);
    } catch (_) {
      // Fall back to defaults on any read/parse error.
    }
  }

  // Writes settings/scores; ignores write failures (e.g. read-only home).
  void save() {
    try {
      _file.createSync(recursive: true);
      _file.writeAsStringSync(jsonEncode({
        'tetrisBoard': tetrisBoard,
        'tetrisSpeed': tetrisSpeed,
        'tetrisScores': [for (final e in tetrisScores) e.toJson()],
        'dinoSpeed': dinoSpeed,
        'dinoScores': [for (final e in dinoScores) e.toJson()],
        'flappySpeed': flappySpeed,
        'flappyScores': [for (final e in flappyScores) e.toJson()],
        'scores2048': [for (final e in scores2048) e.toJson()],
        'snakeSpeed': snakeSpeed,
        'snakeScores': [for (final e in snakeScores) e.toJson()],
      }));
    } catch (_) {}
  }

  static int _clampIndex(dynamic v, int length) {
    final i = v is int ? v : 0;
    return (i < 0 || i >= length) ? 0 : i;
  }

  // Reads a leaderboard; falls back to a legacy single high-score int.
  static List<ScoreEntry> _scores(dynamic list) {
    final out = <ScoreEntry>[];
    if (list is List) {
      for (final e in list) {
        final s = ScoreEntry.fromJson(e);
        if (s != null) out.add(s);
      }
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }
}

final settings = GameSettings();
