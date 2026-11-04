// Decodes a raw stdin chunk into canonical key tokens shared by all games.
//
// Tokens: 'arrowUp', 'arrowDown', 'arrowLeft', 'arrowRight', 'enter', 'space',
// 'ctrlC', and single lowercase characters like 'q', 'w', 'a', 's', 'd', 'r'.
List<String> decodeKeys(List<int> data) {
  final out = <String>[];
  for (int i = 0; i < data.length; i++) {
    final b = data[i];
    if (b == 3) {
      out.add('ctrlC');
    } else if (b == 13 || b == 10) {
      out.add('enter');
    } else if (b == 32) {
      out.add('space');
    } else if (b == 127 || b == 8) {
      out.add('backspace');
    } else if (b == 27 && i + 2 < data.length && data[i + 1] == 91) {
      switch (data[i + 2]) {
        case 65:
          out.add('arrowUp');
          break;
        case 66:
          out.add('arrowDown');
          break;
        case 67:
          out.add('arrowRight');
          break;
        case 68:
          out.add('arrowLeft');
          break;
      }
      i += 2;
    } else if (b >= 33 && b < 127) {
      out.add(String.fromCharCode(b).toLowerCase());
    }
  }
  return out;
}
