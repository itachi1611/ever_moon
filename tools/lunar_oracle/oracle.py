"""Independent oracle for the Vietnamese lunar calendar (UTC+7).

Plan: docs/plans/0001-lunar-package.md (slice S1). The astronomy comes from the
third-party `astronomy-engine` library, not from our own code, so the fixtures
are independent of the implementation under test.

Rules applied (published at
https://informatik.uni-leipzig.de/~duc/amlich/calrules_en.html):
  * Lunar day 1 of a month is the local (UTC+7) day containing the new moon.
  * The month containing the December solstice is month 11.
  * Between two consecutive month 11s there are 12 or 13 months; with 13 the
    year has a leap month: the first month after month 11 that contains no
    principal term (sun longitude multiple of 30 degrees).

Usage: python3 oracle.py [output_directory]
"""
from __future__ import annotations

import bisect
import json
import math
import sys
from datetime import date
from importlib import metadata
from pathlib import Path

import astronomy as astro

GENERATOR_VERSION = 1
TZ_HOURS = 7
J2000_JD = 2451545.0
FIRST_YEAR = 1800
LAST_YEAR = 2199
# Structural sensitivity: event times are shifted by these many seconds and
# the lunar structure is recomputed; any difference is a boundary case.
SENSITIVITY_SECONDS = (-180, 0, 180)
NEAR_MIDNIGHT_SECONDS = 180
SOLSTICE_LONGITUDE_INDEX = 9  # 9 * 30 = 270 degrees


def jd_ut(time: astro.Time) -> float:
  return time.ut + J2000_JD


def local_day_number(jd: float, shift_seconds: float = 0.0) -> int:
  """Julian day number of the UTC+7 civil date containing `jd` (UT)."""
  return math.floor(jd + shift_seconds / 86400.0 + 0.5 + TZ_HOURS / 24.0)


def margin_seconds(jd: float) -> float:
  """Distance in seconds from `jd` to the nearest UTC+7 midnight."""
  fraction = (jd + 0.5 + TZ_HOURS / 24.0) % 1.0
  seconds = fraction * 86400.0
  return min(seconds, 86400.0 - seconds)


def iso_date(day_number: int) -> str:
  return date.fromordinal(day_number - 1721425).isoformat()


def find_new_moons() -> list[float]:
  """UT Julian dates of every new moon from Sep 1799 to Mar 2201."""
  result: list[float] = []
  cursor = astro.Time.Make(FIRST_YEAR - 1, 9, 1, 0, 0, 0)
  end_jd = jd_ut(astro.Time.Make(LAST_YEAR + 2, 3, 1, 0, 0, 0))
  while True:
    moon = astro.SearchMoonPhase(0, cursor, 40)
    if moon is None or jd_ut(moon) > end_jd:
      break
    result.append(jd_ut(moon))
    cursor = moon.AddDays(20)
  return result


def find_principal_terms() -> dict[int, list[float]]:
  """UT Julian dates of each principal term, keyed by year, index 0..11."""
  terms: dict[int, list[float]] = {}
  for year in range(FIRST_YEAR - 1, LAST_YEAR + 3):
    start = astro.Time.Make(year, 1, 1, 0, 0, 0)
    terms[year] = [
        jd_ut(astro.SearchSunLongitude(index * 30, start, 366))
        for index in range(12)
    ]
  return terms


def derive_months(new_moons: list[float], terms: dict[int, list[float]],
                  shift_seconds: float) -> dict:
  """Apply the published rules; returns months and leap info per lunar year."""
  moon_days = [local_day_number(jd, shift_seconds) for jd in new_moons]
  term_days = sorted(
      local_day_number(jd, shift_seconds)
      for year_terms in terms.values() for jd in year_terms)
  month11 = {}
  for year, year_terms in terms.items():
    solstice_day = local_day_number(year_terms[SOLSTICE_LONGITUDE_INDEX],
                                    shift_seconds)
    index = bisect.bisect_right(moon_days, solstice_day) - 1
    if index >= 0:
      month11[year] = index
  months = []
  leap_months: dict[int, int] = {}
  for year in range(FIRST_YEAR - 1, LAST_YEAR + 1):
    start_index, next_index = month11[year], month11[year + 1]
    count = next_index - start_index
    if count not in (12, 13):
      raise ValueError(f"unexpected month count {count} for year {year}")
    leap_offset = None
    if count == 13:
      for offset in range(1, count):
        first = moon_days[start_index + offset]
        after = moon_days[start_index + offset + 1]
        position = bisect.bisect_left(term_days, first)
        if position >= len(term_days) or term_days[position] >= after:
          leap_offset = offset
          break
      if leap_offset is None:
        raise ValueError(f"no leap month found for year {year}")
    number, lunar_year = 11, year
    for offset in range(count):
      is_leap = offset == leap_offset
      if offset > 0 and not is_leap:
        number = number % 12 + 1
        if number == 1:
          lunar_year += 1
      index = start_index + offset
      if FIRST_YEAR <= lunar_year <= LAST_YEAR:
        months.append([
            lunar_year, number, 1 if is_leap else 0,
            iso_date(moon_days[index]),
            moon_days[index + 1] - moon_days[index]
        ])
        if is_leap:
          leap_months[lunar_year] = number
  return {"months": months, "leap_months": leap_months}


def near_midnight_events(new_moons, terms) -> list[dict]:
  events = []
  for jd in new_moons:
    if margin_seconds(jd) < NEAR_MIDNIGHT_SECONDS:
      events.append(event_record("new_moon", jd))
  for year_terms in terms.values():
    for index, jd in enumerate(year_terms):
      if margin_seconds(jd) < NEAR_MIDNIGHT_SECONDS:
        events.append(event_record(f"term_{index * 30}", jd))
  return sorted(events, key=lambda item: item["jd_ut"])


def event_record(kind: str, jd: float) -> dict:
  return {
      "kind": kind,
      "jd_ut": round(jd, 6),
      "local_date": iso_date(local_day_number(jd)),
      "margin_seconds": round(margin_seconds(jd), 1),
  }


def structural_differences(base: dict, others: dict[int, dict]) -> list[dict]:
  base_by_key = {(m[0], m[1], m[2]): m for m in base["months"]}
  found = []
  for shift, alt in others.items():
    alt_by_key = {(m[0], m[1], m[2]): m for m in alt["months"]}
    for key in sorted(set(base_by_key) | set(alt_by_key)):
      before, after = base_by_key.get(key), alt_by_key.get(key)
      if before != after:
        found.append({"shift_seconds": shift, "month": list(key),
                      "base": before, "shifted": after})
  return found


def build(output_directory: Path) -> None:
  new_moons = find_new_moons()
  terms = find_principal_terms()
  results = {shift: derive_months(new_moons, terms, shift)
             for shift in SENSITIVITY_SECONDS}
  base = results[0]
  meta = {
      "generator_version": GENERATOR_VERSION,
      "astronomy_engine": metadata.version("astronomy-engine"),
      "time_zone_hours": TZ_HOURS,
      "first_lunar_year": FIRST_YEAR,
      "last_lunar_year": LAST_YEAR,
      "month_row": ["lunar_year", "month", "is_leap", "start_date", "days"],
  }
  write_json(output_directory / "oracle_months.json", {
      "meta": meta,
      "leap_months": {str(y): m for y, m in sorted(base["leap_months"].items())},
      "months": base["months"],
  })
  write_json(output_directory / "oracle_events.json", {
      "meta": meta,
      "new_moons_jd_ut": [round(jd, 6) for jd in new_moons],
      "principal_terms_jd_ut": {
          str(y): [round(jd, 6) for jd in values]
          for y, values in sorted(terms.items())
      },
  })
  others = {s: results[s] for s in SENSITIVITY_SECONDS if s != 0}
  write_json(output_directory / "boundary_cases.json", {
      "meta": {**meta, "near_midnight_seconds": NEAR_MIDNIGHT_SECONDS,
               "sensitivity_seconds": list(SENSITIVITY_SECONDS)},
      "events_near_midnight": near_midnight_events(new_moons, terms),
      "structural_differences": structural_differences(base, others),
  })


def write_json(path: Path, payload: dict) -> None:
  path.parent.mkdir(parents=True, exist_ok=True)
  text = json.dumps(payload, ensure_ascii=False, separators=(",", ":"),
                    sort_keys=True)
  path.write_text(text + "\n", encoding="utf-8")


if __name__ == "__main__":
  target = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
      __file__).resolve().parents[2] / "packages/lunar_calendar/test/fixtures"
  build(target)
  print(f"wrote fixtures to {target}")
