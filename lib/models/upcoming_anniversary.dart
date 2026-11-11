import 'package:equatable/equatable.dart';
import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';

/// An anniversary with its next holding, as the upcoming list shows it.
class UpcomingAnniversary extends Equatable {
  /// Creates the list entry; the upcoming-list Cubit is the producer.
  const UpcomingAnniversary({
    required this.anniversary,
    required this.lunarDate,
    required this.solarDate,
    required this.daysLeft,
  });

  /// The stored record.
  final Anniversary anniversary;

  /// Lunar date of the next holding (may be the leap month or day 29).
  final LunarDate lunarDate;

  /// Gregorian day of the next holding, UTC midnight.
  final DateTime solarDate;

  /// Whole days from today; 0 means the anniversary is today.
  final int daysLeft;

  /// Whether the anniversary falls today.
  bool get isToday => daysLeft == 0;

  @override
  List<Object?> get props => [anniversary, lunarDate, solarDate, daysLeft];
}
