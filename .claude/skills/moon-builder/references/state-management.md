# State Management Reference

## BLoC (full event-driven)

Use when: multiple distinct events, complex transitions, event transformers (debounce, throttle).

```dart
// bloc/product_event.dart
sealed class ProductEvent {}
class FetchProducts extends ProductEvent {}
class RefreshProducts extends ProductEvent {}
class SearchProducts extends ProductEvent {
  final String query;
  const SearchProducts(this.query);
}

// bloc/product_state.dart
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

// bloc/product_bloc.dart
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase _getProducts;

  ProductBloc(this._getProducts) : super(ProductInitial()) {
    on<FetchProducts>(_onFetch);
    on<SearchProducts>(_onSearch, transformer: debounce(const Duration(milliseconds: 300)));
  }

  Future<void> _onFetch(FetchProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await _getProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
```

BlocProvider in page:
```dart
BlocProvider(
  create: (context) => ProductBloc(context.read<GetProductsUseCase>())..add(FetchProducts()),
  child: const ProductView(),
)
```

BlocBuilder usage:
```dart
BlocBuilder<ProductBloc, ProductState>(
  builder: (context, state) => switch (state) {
    ProductInitial() => const SizedBox.shrink(),
    ProductLoading() => const Center(child: CircularProgressIndicator()),
    ProductLoaded(:final products) => ProductListView(products: products),
    ProductError(:final message) => ErrorView(message: message),
  },
)
```

---

## Cubit (simpler, preferred for CRUD/fetch)

Use when: straightforward fetch/submit/toggle flows with no complex event logic.

```dart
// cubit/product_cubit.dart
class ProductCubit extends Cubit<ProductState> {
  final GetProductsUseCase _getProducts;

  ProductCubit(this._getProducts) : super(ProductInitial());

  Future<void> fetchProducts() async {
    emit(ProductLoading());
    try {
      final products = await _getProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
```

CubitProvider in page:
```dart
BlocProvider(
  create: (context) => ProductCubit(context.read<GetProductsUseCase>())..fetchProducts(),
  child: const ProductView(),
)
```

---

## Provider + ChangeNotifier

Use when: project already uses Provider, or for simple reactive state.

```dart
// notifier/product_notifier.dart
class ProductNotifier extends ChangeNotifier {
  final GetProductsUseCase _getProducts;

  ProductNotifier(this._getProducts);

  List<ProductEntity> _products = [];
  bool _isLoading = false;
  String? _error;

  List<ProductEntity> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _getProducts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // cancel subscriptions, timers, etc.
    super.dispose();
  }
}
```

ChangeNotifierProvider in page:
```dart
ChangeNotifierProvider(
  create: (context) => ProductNotifier(context.read<GetProductsUseCase>())..fetchProducts(),
  child: const ProductView(),
)
```

Consumer usage:
```dart
Consumer<ProductNotifier>(
  builder: (context, notifier, _) {
    if (notifier.isLoading) return const CircularProgressIndicator();
    if (notifier.error != null) return ErrorView(message: notifier.error!);
    return ProductListView(products: notifier.products);
  },
)
```

---

## Flutter Built-in (ValueNotifier / StatefulWidget)

Use when: purely local UI state, no data fetching, no sharing across widgets.

### ValueNotifier + ValueListenableBuilder
```dart
final _counter = ValueNotifier<int>(0);

ValueListenableBuilder<int>(
  valueListenable: _counter,
  builder: (context, value, _) => Text('$value'),
)
```

Always dispose in StatefulWidget:
```dart
@override
void dispose() {
  _counter.dispose();
  super.dispose();
}
```

### StatefulWidget — when to use
- Toggle visibility, tab selection, form field focus
- Animations with AnimationController
- Never for data fetched from network/disk
