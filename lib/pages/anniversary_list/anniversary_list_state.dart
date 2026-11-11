import 'package:equatable/equatable.dart';
import 'package:ever_moon/models/upcoming_anniversary.dart';

/// State of the upcoming anniversaries list (plan 0005, U2).
sealed class AnniversaryListState extends Equatable {
  const AnniversaryListState();

  @override
  List<Object?> get props => [];
}

/// Waiting for the first emission from the repository.
final class AnniversaryListLoading extends AnniversaryListState {
  /// Creates the loading state.
  const AnniversaryListLoading();
}

/// No anniversary is stored yet.
final class AnniversaryListEmpty extends AnniversaryListState {
  /// Creates the empty state.
  const AnniversaryListEmpty();
}

/// Anniversaries ordered by their next holding (UI-1).
final class AnniversaryListLoaded extends AnniversaryListState {
  /// Creates the loaded state from [items] in display order.
  const AnniversaryListLoaded(this.items);

  /// Entries in display order: soonest first, ties by name.
  final List<UpcomingAnniversary> items;

  /// Entries that fall today.
  List<UpcomingAnniversary> get today =>
      items.where((item) => item.isToday).toList();

  /// Entries after today.
  List<UpcomingAnniversary> get upcoming =>
      items.where((item) => !item.isToday).toList();

  @override
  List<Object?> get props => [items];
}

/// Reading the list failed; the page offers a retry.
final class AnniversaryListFailure extends AnniversaryListState {
  /// Creates the failure state.
  const AnniversaryListFailure();
}
