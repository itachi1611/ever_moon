# Flutter Anti-Patterns & Idiomatic Replacements

## Widget Rebuilds

### ❌ setState on entire page for small change
```dart
setState(() { _counter++; });
// triggers full page rebuild
```
### ✅ ValueNotifier for isolated state
```dart
final _counter = ValueNotifier<int>(0);
// In widget:
ValueListenableBuilder<int>(
  valueListenable: _counter,
  builder: (_, value, __) => Text('$value'),
);
_counter.value++;
```

---

## Missing const

### ❌ No const on immutable widgets
```dart
Text('Hello'),
SizedBox(height: 16),
Icon(Icons.star),
```
### ✅ Always const
```dart
const Text('Hello'),
const SizedBox(height: 16),
const Icon(Icons.star),
```

---

## Missing dispose

### ❌ Controller never disposed
```dart
class _MyState extends State<MyWidget> {
  final _ctrl = TextEditingController();
  // No dispose!
}
```
### ✅ Always dispose
```dart
@override
void dispose() {
  _ctrl.dispose();
  super.dispose();
}
```

---

## Async in initState

### ❌ Direct await in initState
```dart
@override
void initState() {
  super.initState();
  await loadData(); // Won't work, initState isn't async
}
```
### ✅ Call a helper
```dart
@override
void initState() {
  super.initState();
  _loadData();
}

Future<void> _loadData() async {
  final data = await fetchSomething();
  if (!mounted) return;
  setState(() => _data = data);
}
```

---

## Building widgets inside build()

### ❌ Creating objects every build
```dart
Widget build(BuildContext context) {
  final style = TextStyle(fontSize: 18, color: Colors.blue); // recreated every build
  return Text('Hi', style: style);
}
```
### ✅ Static or const
```dart
static const _titleStyle = TextStyle(fontSize: 18, color: Colors.blue);

Widget build(BuildContext context) {
  return const Text('Hi', style: _titleStyle);
}
```

---

## Nested FutureBuilders

### ❌ Nested futures cause cascading loading states
```dart
FutureBuilder(
  future: fetchUser(),
  builder: (_, snap) => FutureBuilder(
    future: fetchPosts(),
    ...
  ),
)
```
### ✅ Combine with Future.wait
```dart
FutureBuilder(
  future: Future.wait([fetchUser(), fetchPosts()]),
  builder: (_, snap) {
    final user = snap.data?[0];
    final posts = snap.data?[1];
    ...
  },
)
```

---

## Large widget trees in one class

### ❌ One giant build method
```dart
Widget build(BuildContext context) {
  return Column(children: [
    // 200 lines of nested widgets
  ]);
}
```
### ✅ Extract to focused StatelessWidgets
```dart
Widget build(BuildContext context) {
  return Column(children: [
    const _Header(),
    const _Body(),
    const _Footer(),
  ]);
}
```

---

## Dynamic types

### ❌ Using dynamic
```dart
dynamic result = await fetchData();
result['name'];
```
### ✅ Typed models
```dart
final result = await fetchData(); // returns User
result.name;
```

---

## String/int switch without enums

### ❌ Switching on raw strings
```dart
switch (status) {
  case 'loading': ...
  case 'error': ...
}
```
### ✅ Enum with Dart 3 pattern matching
```dart
enum Status { loading, error, success }

switch (status) {
  case Status.loading => ...,
  case Status.error => ...,
  case Status.success => ...,
}
```
