# Dart 3 Features Worth Applying

## Records
Group multiple values without defining a class.

```dart
// ❌ Before
Map<String, dynamic> getCoords() => {'lat': 1.0, 'lng': 2.0};

// ✅ After
(double lat, double lng) getCoords() => (1.0, 2.0);
final (lat, lng) = getCoords();
```

---

## Patterns & Destructuring

```dart
// Destructure a record
final (name, age) = ('Alice', 30);

// Destructure in switch
switch (shape) {
  case Circle(radius: var r): print('circle r=$r');
  case Rectangle(width: var w, height: var h): print('rect ${w}x$h');
}

// List patterns
final [first, second, ...rest] = myList;

// Map patterns
final {'name': String name, 'age': int age} = json;
```

---

## Sealed Classes
Exhaustive pattern matching with sealed hierarchies.

```dart
sealed class Result<T> {}
class Success<T> extends Result<T> { final T value; ... }
class Failure<T> extends Result<T> { final String error; ... }

// Compiler enforces all cases are handled
switch (result) {
  case Success(:final value): display(value);
  case Failure(:final error): showError(error);
}
```

---

## Class Modifiers

| Modifier | Meaning |
|---|---|
| `final` | Can't be extended or implemented outside library |
| `base` | Can be extended but not implemented |
| `interface` | Can be implemented but not extended |
| `sealed` | Neither — exhaustive pattern matching |
| `mixin class` | Can be used as both mixin and class |

---

## Enhanced Enums

```dart
enum Status {
  loading('Loading...'),
  error('Something went wrong'),
  success('Done!');

  final String message;
  const Status(this.message);

  bool get isTerminal => this == error || this == success;
}
```

---

## if-case

```dart
// ❌ verbose null check + cast
if (value != null && value is String) {
  print(value.toUpperCase());
}

// ✅ if-case
if (value case String s) {
  print(s.toUpperCase());
}
```

---

## Guard Clauses in Switch

```dart
switch (user) {
  case User(:final age) when age >= 18:
    grantAccess();
  case User(:final age) when age < 18:
    denyAccess();
}
```

---

## Named Parameters with Records

```dart
// Pass multiple return values cleanly
({String name, int score}) evaluate(List<int> answers) {
  return (name: 'Alice', score: answers.fold(0, (a, b) => a + b));
}

final result = evaluate(answers);
print(result.name); // Alice
print(result.score);
```
