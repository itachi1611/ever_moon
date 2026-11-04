import 'dart:io' show exit;

import 'package:game_cli/common/menu.dart';

Future<void> main(List<String> arguments) async {
  await runMenu();
  exit(0);
}
