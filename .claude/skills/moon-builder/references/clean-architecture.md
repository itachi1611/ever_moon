# Clean Architecture Reference

## Dependency Rule

```
Presentation → Domain ← Data
```

- Domain has zero Flutter/external dependencies
- Data depends on Domain (implements its interfaces)
- Presentation depends on Domain (calls use cases)
- Nothing depends on Presentation

---

## Feature Sizes

### Small feature (local state, no network)
```
features/settings/
├── presentation/
│   ├── pages/settings_page.dart
│   └── widgets/settings_tile.dart
```
No domain/data layers needed. Use StatefulWidget or ValueNotifier.

### Medium feature (single data source, simple state)
```
features/profile/
├── data/
│   ├── models/profile_model.dart
│   └── repositories/profile_repository_impl.dart
├── domain/
│   ├── entities/profile_entity.dart
│   ├── repositories/profile_repository.dart
│   └── usecases/get_profile_usecase.dart
└── presentation/
    ├── cubit/
    │   ├── profile_cubit.dart
    │   └── profile_state.dart
    ├── pages/profile_page.dart
    └── widgets/profile_avatar.dart
```

### Large feature (multiple sources, complex events)
```
features/product/
├── data/
│   ├── models/
│   │   ├── product_model.dart
│   │   └── category_model.dart
│   ├── repositories/
│   │   └── product_repository_impl.dart
│   └── sources/
│       ├── product_remote_source.dart
│       └── product_local_source.dart        ← cache
├── domain/
│   ├── entities/
│   │   ├── product_entity.dart
│   │   └── category_entity.dart
│   ├── repositories/
│   │   └── product_repository.dart
│   └── usecases/
│       ├── get_products_usecase.dart
│       ├── get_product_detail_usecase.dart
│       └── search_products_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── product_bloc.dart
    │   ├── product_event.dart
    │   └── product_state.dart
    ├── pages/
    │   ├── product_list_page.dart
    │   └── product_detail_page.dart
    └── widgets/
        ├── product_card.dart
        ├── product_search_bar.dart
        └── product_filter_sheet.dart
```

---

## Layer Responsibilities

### Domain — `entities/`
- Pure Dart classes, immutable, no json/Flutter deps
- Represent business concepts, not API contracts

### Domain — `repositories/`
- Abstract class only (interface)
- Returns domain entities or throws typed domain exceptions
- Never `Map<String, dynamic>`, never model classes

### Domain — `usecases/`
- One public method: `call()` (makes them callable like functions)
- Constructor-injected repository
- Thin orchestration — no business logic beyond what's needed to call the repo

```dart
class GetProductsUseCase {
  final ProductRepository _repository;
  const GetProductsUseCase(this._repository);

  Future<List<ProductEntity>> call() => _repository.getProducts();
}
```

### Data — `models/`
- Mirror API contract exactly (field names match JSON keys, or use `@JsonKey`)
- `toEntity()` converts to domain entity
- Never passed to presentation layer

### Data — `sources/`
- Remote: wraps HTTP client (Dio, http)
- Local: wraps shared_preferences, Hive, Isar, SQLite
- Throws typed exceptions (not raw http errors)

### Data — `repositories/`
- Implements the domain repository interface
- Orchestrates remote + local sources (caching strategy here)
- Converts models to entities via `toEntity()`

### Presentation — pages/
- Thin: provides BLoC/Cubit/Notifier, delegates rendering to widgets
- One `Scaffold` per page
- No business logic

### Presentation — widgets/
- Purely presentational or minimally stateful (local UI state only)
- Receive data via constructor params — no direct BLoC access inside reusable widgets

---

## GoRouter Patterns

### Route constants
```dart
// core/routing/app_routes.dart
abstract class AppRoutes {
  static const String products = '/products';
  static const String productDetail = '/products/:id';
  static const String settings = '/settings';
}
```

### Route definition
```dart
// core/routing/app_router.dart
final appRouter = GoRouter(
  initialLocation: AppRoutes.products,
  routes: [
    GoRoute(
      path: AppRoutes.products,
      builder: (context, state) => const ProductListPage(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ProductDetailPage(productId: id);
          },
        ),
      ],
    ),
  ],
);
```

### Navigation
```dart
// Push
context.push(AppRoutes.productDetail.replaceFirst(':id', product.id));

// Replace (no back)
context.go(AppRoutes.products);

// With extra data
context.push('/modal', extra: {'data': someObject});
```

---

## Dependency Injection

If using `get_it`:

```dart
// injection_container.dart (inside feature or at app level)
void registerProductFeature(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<ProductRemoteSource>(
    () => ProductRemoteSourceImpl(sl<Dio>()),
  );

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl<ProductRemoteSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl<ProductRepository>()));

  // BLoC/Cubit — registerFactory so each page gets a fresh instance
  sl.registerFactory(() => ProductCubit(sl<GetProductsUseCase>()));
}
```

If not using DI — instantiate in the BlocProvider `create:` callback using `context.read<>()`.
