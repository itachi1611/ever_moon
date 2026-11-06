---
name: moon-builder
description: Evermoon's scaffolder: generates Flutter features and screens (page, cubit, state, optional model/repository/service, route) using the project's established structure, Cubit (preferred), Provider, or Flutter built-in state management, and GoRouter navigation. Use this skill whenever the user asks to build, create, generate, or scaffold a new Flutter screen, page, feature, module, or flow — even if they just describe what they want in plain terms like "add a login screen", "build a product list feature", or "create a settings page". Trigger for any new Flutter UI or feature work, not just when the user says "scaffold". Also trigger when the user asks to run scripts, generate code, check architecture, or add models to an existing Flutter feature.
---

# Moon Builder (Evermoon feature scaffolder)

You are an expert Flutter architect. When asked to build a new feature or screen, generate a **complete, production-ready scaffold** matching the project's established conventions:

- **State management**: **Cubit** (default) — use BLoC only when explicitly asked or when complex event transformers are needed
- **Navigation**: GoRouter; routes are values of the `Routers` enum in `lib/routing/routers.dart`, wired in `lib/routing/router_config.dart`
- **Models**: `json_serializable` + `json_annotation` — never Freezed unless explicitly requested
- **Dart**: Dart 3+, null safety, `sealed class`, exhaustive `switch` with pattern matching
- **No external packages** without asking the user first

---

## Project Structure

This is the established project layout. All new features and pages must fit into it:

```
lib/
├── app/                        # AppPage, AppCubit, AppState (theme mode, locale)
├── common/                     # AppColors, AppDimensions, themes, text styles, enums, constants
├── models/                     # Shared data models (flat today); entities/ and data_class/
│                               #   subfolders are created by the scripts when first needed
├── pages/                      # All UI screens — one folder per feature/page
│   ├── <feature_name>/
│   │   ├── <feature>_page.dart
│   │   ├── <feature>_cubit.dart
│   │   ├── <feature>_state.dart
│   │   └── widgets/            # Feature-scoped widgets (optional)
│   └── widgets/                # Global reusable widgets
├── services/                   # Singletons and business logic (one file per domain)
├── repositories/               # Data access layer (created on first use)
├── network/                    # Dio, interceptors, api_utils
├── routing/                    # Routers enum, router_config, app_router, notifier, observer
├── storage/                    # AppStorage (get_storage), AppPreference (shared_preferences)
├── utils/                      # AppLogger, validators, extensions
├── l10n/                       # ARB files (en, vi); Vietnamese is the primary locale
└── generated/                  # Auto-generated files (never edit)
```

---

## Evermoon overrides (CLAUDE.md wins over anything below)

- Cubit only; sealed Equatable states; one Cubit per page, created in `initState`, closed in `dispose`.
- Never return widgets from `_buildX()` helpers; extract widget classes. `const` where possible; `ListView.builder` for dynamic lists.
- No hardcoded colors, paddings, dimensions or user-visible strings: use theme, `AppColors`, `AppDimensions` and `S.of(context)`; add keys to `intl_en.arb` and `intl_vi.arb`, then run `fvm flutter gen-l10n`.
- Functions of at most 20 lines; every `catch` logs through `AppLogger` or rethrows; no `print`, no `!` without a justifying comment, no `.then()`.
- Comments in English; `///` DartDoc on public API.
- Use `fvm` for every command. Claude's sandbox has no Dart, so the user runs `fvm dart analyze` and `fvm flutter test`.
- The generated scripts are a starting point: after running one, fix the output to meet these rules.

---

## Output Format

Always output the **full file tree first**, anchored to `lib/`, then each file in full with its path as a comment header. No placeholders, no omitted sections.

### New Feature (with API + Cubit)
```
lib/
├── models/
│   ├── data_class/
│   │   └── <feature>_model.dart
│   └── entities/
│       └── <feature>_entity.dart
├── pages/
│   └── <feature>/
│       ├── <feature>_page.dart
│       ├── <feature>_cubit.dart
│       ├── <feature>_state.dart
│       └── widgets/
│           └── <feature>_card.dart       (if list/card UI)
├── repositories/
│   └── <feature>_repositories.dart
└── services/
    └── <feature>_service.dart
```

### New Page (UI only, no data layer)
```
lib/pages/<feature>/
├── <feature>_page.dart
├── <feature>_cubit.dart
└── <feature>_state.dart
```

### GoRouter entry (always include)
```dart
// 1) lib/routing/routers.dart — add the enum value first:
//    <feature>('/<feature>', '<feature>'),
// 2) lib/routing/router_config.dart — then wire it (order matters):
GoRoute get _<feature>Route => GoRoute(
  name: Routers.<feature>.routerName,
  path: Routers.<feature>.routerPath,
  builder: (context, state) => const <Feature>Page(),
);
```

---

## Step-by-Step Generation Process

### 1. Clarify if needed
Ask ONE question max. Prefer assumptions — state them at the top of the response.

Common assumptions:
- Cubit unless otherwise indicated
- API call involved for data-heavy features
- Auth not required unless mentioned

### 2. Choose State Management

| Signal | Use |
|---|---|
| Default / no signal | **Cubit** |
| Simple local UI state, no network | `StatefulWidget` / `ValueNotifier` |
| Existing Provider usage in project | `Provider + ChangeNotifier` |
| Explicit ask, or debounce/throttle needed | Full BLoC |

See `references/state-management.md` for complete boilerplate per approach.

### 3. Layer generation order

1. **Entity** → `lib/models/entities/`
2. **Model** → `lib/models/data_class/`
3. **Repository** → `lib/repositories/<feature>_repositories.dart`
4. **Service** → `lib/services/<feature>_service.dart`
5. **State + Cubit** → `lib/pages/<feature>/`
6. **Page + Widgets** → `lib/pages/<feature>/`
7. **Router snippet** → enum value in `lib/routing/routers.dart` plus GoRoute in `lib/routing/router_config.dart`

---

## Layer-by-Layer Rules

### Entities (`lib/models/entities/`)

- Plain Dart classes — no `json_serializable`, no Flutter imports, no external packages
- Immutable with `const` constructors
- Represent the business concept, not the API shape

```dart
// lib/models/entities/product_entity.dart
class ProductEntity {
  final String id;
  final String name;
  final double price;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
  });
}
```

### Models (`lib/models/data_class/`)

Use `json_serializable`. Always include:
- `part '<n>_model.g.dart';`
- `@JsonSerializable()` annotation
- `fromJson` / `toJson`
- `toEntity()` method to convert to domain entity

```dart
// lib/models/data_class/product_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../entities/product_entity.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final String id;
  final String name;
  final double price;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  ProductEntity toEntity() => ProductEntity(
        id: id,
        name: name,
        price: price,
      );
}
```

### Repositories (`lib/repositories/`)

- One file per domain: `<feature>_repositories.dart`
- Calls the API via `lib/network/api_utils.dart` (existing network layer)
- Returns raw models — catches and rethrows typed exceptions
- Never lets raw Dio/http exceptions leak upward

```dart
// lib/repositories/product_repositories.dart
class ProductRepositories {
  Future<List<ProductModel>> getProducts() async {
    final response = await ApiUtil.get('/products');
    return (response.data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

### Services (`lib/services/`)

- One file per domain: `<feature>_service.dart`
- Contains business logic: mapping, filtering, combining repository calls
- Constructor-injected repository
- Returns entities to the cubit layer

```dart
// lib/services/product_service.dart
class ProductService {
  final ProductRepositories _repositories;

  ProductService(this._repositories);

  Future<List<ProductEntity>> getProducts() async {
    final models = await _repositories.getProducts();
    return models.map((m) => m.toEntity()).toList();
  }
}
```

### Cubit + State (`lib/pages/<feature>/`)

**Always Cubit unless explicitly asked for BLoC.** State uses `sealed class` (Dart 3):

```dart
// lib/pages/product/product_state.dart
sealed class ProductState {}
class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<ProductEntity> products;
  const ProductLoaded(this.products);
}
class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
}
```

```dart
// lib/pages/product/product_cubit.dart
class ProductCubit extends Cubit<ProductState> {
  final ProductService _service;

  ProductCubit(this._service) : super(ProductInitial());

  Future<void> load() async {
    emit(ProductLoading());
    try {
      final products = await _service.getProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
```

### Page (`lib/pages/<feature>/`)

- Thin widget: provides Cubit, delegates to a private `_View` widget
- Exhaustive `switch` on sealed state — no unhandled cases
- Use `BlocBuilder` for targeted rebuilds; `BlocListener` for side effects (navigation, snackbars)

```dart
// lib/pages/product/product_page.dart
class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductCubit(
        ProductService(ProductRepositories()),
      )..load(),
      child: const _ProductView(),
    );
  }
}

class _ProductView extends StatelessWidget {
  const _ProductView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) => switch (state) {
          ProductInitial() => const SizedBox.shrink(),
          ProductLoading() => const Center(child: CircularProgressIndicator()),
          ProductLoaded(:final products) => _ProductList(products: products),
          ProductError(:final message) => Center(child: Text(message)),
        },
      ),
    );
  }
}
```

---

## Checklist Before Outputting

- [ ] File tree shown, anchored to `lib/`
- [ ] Files placed in correct project locations (`pages/`, `services/`, `repositories/`, `models/data_class/`, `models/entities/`)
- [ ] All files output in full — no `// TODO`, no truncation
- [ ] `part` directives match filenames exactly
- [ ] No Freezed, no dartz, no new external packages without asking
- [ ] GoRouter snippet included
- [ ] Sealed state is exhaustive
- [ ] `dispose()` called for any controllers
- [ ] No business logic inside page/widget files
- [ ] Assumptions listed at top if any were made

---

## Scripts

Run from your **Flutter project root**. Make executable once:
```bash
chmod +x scripts/*.sh
```

| Script | Purpose | Usage |
|---|---|---|
| `new_feature.sh` | Full scaffold (entity + model + repository + service + cubit + page) | `./scripts/new_feature.sh <feature_name>` |
| `new_page.sh` | Presentation only (page + cubit + state) | `./scripts/new_page.sh <page_name> [path]` |
| `add_model.sh` | Add json_serializable model + entity, runs build_runner | `./scripts/add_model.sh <model_name> <feature_path>` |
| `check_architecture.sh` | Lint all pages for layer violations | `./scripts/check_architecture.sh [--feature name] [--strict]` |

### When to use each
- **New feature with API** → `new_feature.sh`
- **New screen, no data layer** → `new_page.sh`
- **Adding a new data type** → `add_model.sh`
- **Before PR / code review** → `check_architecture.sh`

---

## Reference Files

- `references/state-management.md` — Full boilerplate for Cubit, BLoC, Provider, ValueNotifier
- `references/clean-architecture.md` — Layer rules, dependency directions, folder tree examples

Read these when you need deeper pattern guidance.
