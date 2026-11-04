import 'dart:io' show stdin;

// stdin is a single-subscription stream and may be listened to only once per
// process. We attach that single listener here and forward every chunk of
// bytes to whichever handler is currently active (the menu or a running game).
void Function(List<int> data)? _handler;
bool _started = false;

// Registers [handler] as the active key handler, replacing any previous one.
void onKey(void Function(List<int> data) handler) {
  if (!_started) {
    _started = true;
    stdin.listen((data) => _handler?.call(data));
  }
  _handler = handler;
}

// Removes the active key handler so incoming bytes are ignored.
void offKey() => _handler = null;
