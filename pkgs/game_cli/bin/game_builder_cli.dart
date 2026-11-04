import 'dart:convert' show latin1;
import 'dart:developer';
import 'dart:io';

void main() async {
  // Asking game name
  stdout.write('Enter game name (snake case): ');
  final raw = stdin.readLineSync(encoding: latin1) ?? '';
  final input = raw.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();

  if (input.isEmpty) {
    log('Error: Name cannot be empty');
    exit(1);
  }

  // Make the path for creating the structure
  final base = 'lib/$input';

  // Creating the game structure folder
  Directory('$base/engine').createSync(recursive: true);
  Directory('$base/model').createSync(recursive: true);
  Directory('$base/ui').createSync(recursive: true);

  // Put files into folder
  _createGameFileComponent('$base/engine/${input}_game.dart',_gameTmp(input));
  _createGameFileComponent('$base/engine/runner.dart', _runnerTmp(input));
  _createGameFileComponent('$base/model/example.dart', _modelTmp(input));
  _createGameFileComponent('$base/ui/renderer.dart', _renderTmp(input));
  _createGameFileComponent('$base/$input.dart', _barrelTmp(input));

  log('\nDone! Created:');
  log('  $base/engine/${input}_game.dart');
  log('  $base/engine/runner.dart');
  log('  $base/model/example.dart');
  log('  $base/ui/renderer.dart');
  log('  $base/$input.dart');
}

void _createGameFileComponent(String path, String content) =>
    File(path).writeAsStringSync(content);

String toPascalCase(String snakeCase) =>
    snakeCase.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join();

String _gameTmp(String name) {
  final cls = toPascalCase(name);
  return '''
  import '../../common/game.dart' show Game;
  
  class ${cls}Game extends Game {
    @override
    void update(double ms) {
      if (over) return;
      // Todo: Implement game logic here
    }
    
    @override
    void handleKey(String key) {
      switch(key) {
        case 'q':
        case 'ctrlC':
          quit = true;
          break;
        // Todo: Implement other keys handling here
      }
    }
  }
''';
}

String _runnerTmp(String name) {
  final cls = toPascalCase(name);
  return '''
    import 'dart:io' show stdout;
    
    import '../../common/game_loop.dart';
    import '${name}_game.dart';
    import '../ui/renderer.dart';
    
    Future<void> run$cls() async {
      final game = ${cls}Game();
      
      await runGameLoop(                                                                                                        
        title: '${name.toUpperCase()}',                                                                                         
        tickMs: 60,                                                                                                             
        game: game,                                                                                                             
        render: ,                                                                                               
        qualifies: (s) {
          return false;
        },                                                                             
        submit: (n, s) {},                                                                             
      );
    }
  ''';
}

String _modelTmp(String name) {
  return '''
    class Example {
      final int x;
      final int y;
      
      const Example(this.x, this.y);
    }
  ''';
}

String _renderTmp(String name) {
  final cls = toPascalCase(name);

  return '''
    import '../engine/${name}_game.dart';                                                                                       
                                                                                                                              
    extension ${cls}Renderer on ${cls}Game {                                                                                    
      List<String> renderFrame() {                                                                                              
        final lines = <String>[];                                                                                               
        lines.add(' ${name.toUpperCase()}   score:\$score   high:\$high');                                                      
        // TODO: render board                                                                                                   
        lines.add(                                                                                                              
          over                                                                                                                  
              ? '   GAME OVER — r to Retry, q to Quit'                                                                          
              : paused                                                                                                          
              ? '   PAUSED — p to Resume   q Quit'                                                                              
              : '   p Pause   q Quit',                                                                                          
        );                                                                                                                      
        return lines;                                                                                                           
      }                                                                                                                         
    }  
  ''';
}

String _barrelTmp(String name) {
  return '''                                                                                                                
  library $name;                                                                                                              
                                                                                                                              
  export 'engine/${name}_game.dart';                                                                                          
  export 'engine/runner.dart';                                                                                                
  export 'model/example.dart';                                                                                                
  export 'ui/renderer.dart';                                                                                                  
  ''';
}