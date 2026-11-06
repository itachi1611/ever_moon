/// First lunar year the engine supports (plan 0001, decision D2).
const int minLunarYear = 1800;

/// Last lunar year the engine supports (plan 0001, decision D2).
const int maxLunarYear = 2199;

/// Whether [lunarYear] is inside the supported range.
///
/// Callers outside the range get `null` from the engine instead of a guessed
/// date (acceptance criterion LC-4).
bool isSupportedLunarYear(int lunarYear) =>
    lunarYear >= minLunarYear && lunarYear <= maxLunarYear;
