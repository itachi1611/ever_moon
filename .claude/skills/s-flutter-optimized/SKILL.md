---
name: s-flutter-optimized
description: Optimizes Flutter and Dart code for performance, memory efficiency, and readability/maintainability. Use this skill whenever the user shares Flutter widgets, Dart functions, or any Flutter/Dart code and asks to optimize, improve, clean up, refactor, speed up, reduce memory, or make it better. Also trigger when the user says things like "this is slow", "too many rebuilds", "make this cleaner", "improve my widget", or pastes Flutter/Dart code with a vague request to "fix" or "improve" it. Always use this skill for any Flutter/Dart code improvement request — even casual ones.
---

# Flutter & Dart Code Optimizer

You are an expert Flutter and Dart engineer. When given code, rewrite it to be optimized across all three dimensions:
- **Performance** — reduce unnecessary widget rebuilds, use const constructors, lazy loading, efficient state management
- **Memory** — dispose controllers/streams/subscriptions properly, avoid memory leaks, use efficient data structures
- **Readability/Maintainability** — clean structure, proper separation of concerns, idiomatic Dart, clear naming

## Output Format

Return only the optimized code. No preamble, no "here is the optimized version", no explanation unless explicitly asked.

Use this structure:

```dart
// [filename or widget name if identifiable]
[optimized code]
```

If multiple files/classes are involved, separate each with a clear comment header.

---

## Optimization Checklist

Apply all relevant optimizations below. Skip any that don't apply to the given code.

### Widget Performance
- [ ] Add `const` constructors wherever possible (`const Text(...)`, `const SizedBox(...)`, etc.)
- [ ] Extract repeated or heavy subtrees into separate `StatelessWidget` classes
- [ ] Replace `setState` on large trees with targeted rebuilds (`ValueNotifier`, `Provider`, `Riverpod`, `BLoC`, depending on what's already in use)
- [ ] Use `RepaintBoundary` around expensive-to-repaint subtrees
- [ ] Replace `Column`/`Row` with `ListView.builder` or `SliverList` when rendering many items
- [ ] Use `AutomaticKeepAliveClientMixin` thoughtfully (only where scroll retention is needed)
- [ ] Avoid building widgets inside `build()` that can be stored as fields or computed once
- [ ] Prefer `Expanded`/`Flexible` over hardcoded sizes where layout allows

### State Management
- [ ] Lift state only as high as needed — no global state for local concerns
- [ ] Replace `StatefulWidget` with `StatelessWidget` + external state when widget itself holds no logic
- [ ] Use `ValueListenableBuilder` or `StreamBuilder` for fine-grained rebuilds instead of `setState`
- [ ] Debounce rapid state changes (e.g., search input, scroll callbacks)

### Memory Management
- [ ] Dispose all `AnimationController`, `TextEditingController`, `ScrollController`, `FocusNode`, `StreamSubscription`, `Timer` in `dispose()`
- [ ] Cancel async operations on widget disposal using `mounted` checks or `CancelableOperation`
- [ ] Avoid storing large objects (images, lists) in state that outlives their need
- [ ] Use `WeakReference` for cache entries where appropriate
- [ ] Release image memory with `ImageCache` management when handling many images

### Async & Streams
- [ ] Replace nested `FutureBuilder` with combined futures (`Future.wait`)
- [ ] Avoid `async` in `initState` directly — use a helper method
- [ ] Handle errors in `StreamBuilder` and `FutureBuilder` (check `snapshot.hasError`)
- [ ] Use `Stream.distinct()` to avoid redundant rebuilds from identical values
- [ ] Avoid `await` inside loops when calls can be parallelized with `Future.wait`

### Dart Language Idioms
- [ ] Use `final` and `const` wherever variables aren't reassigned
- [ ] Prefer `??=`, `??`, `?.`, `...` spread operators, collection `if`/`for`
- [ ] Use named constructors and factory constructors for clarity
- [ ] Replace imperative loops with functional equivalents (`map`, `where`, `fold`, `any`, `every`) where cleaner
- [ ] Use `typedef` for complex function signatures
- [ ] Prefer `sealed class` / `enum` with methods over `switch` on string/int literals (Dart 3+)
- [ ] Use pattern matching and destructuring (Dart 3+) where it improves clarity
- [ ] Replace `dynamic` with proper types or generics

### Code Structure & Maintainability
- [ ] Extract business logic out of widgets into controllers, notifiers, or blocs
- [ ] Group related widgets into focused files (one widget per file for complex widgets)
- [ ] Use `extension` methods to add reusable helpers on existing types
- [ ] Replace magic numbers/strings with named constants
- [ ] Enforce single responsibility: each function/class does one thing

### Network & I/O
- [ ] Cache network results where appropriate (avoid redundant API calls on rebuild)
- [ ] Use pagination / infinite scroll instead of loading all data at once
- [ ] Compress or resize images before display; use `cached_network_image` for remote images
- [ ] Run heavy I/O in an `Isolate` or via `compute()` to avoid blocking the UI thread

### Build & Compilation
- [ ] Remove unused imports
- [ ] Remove dead code (commented-out blocks, unused variables/methods)
- [ ] Annotate with `@immutable` for immutable classes, `@visibleForTesting` for test helpers

---

## Edge Cases & Judgment Calls

- **Don't change external APIs or method signatures** unless clearly broken or explicitly asked.
- **Preserve existing state management library** (Provider, Riverpod, BLoC, GetX, etc.) — don't switch paradigms unless asked.
- **Dart version**: Default to Dart 3+ idioms unless the code signals an older version (e.g., no null safety = pre-2.12).
- **Partial code**: If only a snippet is given (not a full widget), optimize what's there and add `// ... rest of class` placeholders as needed.
- **Tests**: If test code is included, optimize it too (remove redundancy, use `setUp`/`tearDown` properly).

---

## Reference Files

- `references/flutter-patterns.md` — Common Flutter anti-patterns and their idiomatic replacements
- `references/dart3-features.md` — Dart 3 features worth applying (patterns, sealed classes, records)

Read these if you need deeper guidance on a specific pattern.
