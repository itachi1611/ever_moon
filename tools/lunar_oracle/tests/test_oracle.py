"""Tests for the lunar oracle (plan 0001, slice S1).

Test IDs are stable and never reused: ORC-001 and so on. They map to the
acceptance criteria LUNAR-AC-2, LUNAR-AC-4 and LUNAR-AC-7 in
docs/plans/0001-lunar-package.md.

Run from tools/lunar_oracle: python3 -m unittest discover -s tests -v
"""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from datetime import date, datetime, timedelta
from pathlib import Path

import astronomy as astro

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import oracle  # noqa: E402

FIXTURES = ROOT.parents[1] / "packages/lunar_calendar/test/fixtures"
GATE_SECONDS = 90  # observed maximum against the author's tables: about 48 s


def load(name: str) -> dict:
  return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


def month_rows() -> list[list]:
  return load("oracle_months.json")["months"]


class AuthorTablesTest(unittest.TestCase):
  """ORC-001..002: the oracle astronomy reproduces the author's tables."""

  def test_orc_001_event_times_match_author_tables(self):
    for event in load("anchors.json")["author_events"]:
      expected = datetime.fromisoformat(event["gmt"])
      start = astro.Time.Make(expected.year, expected.month, expected.day,
                              0, 0, 0).AddDays(-3)
      if event["kind"] == "new_moon":
        found = astro.SearchMoonPhase(0, start, 6)
      else:
        longitude = astro.SunPosition(astro.Time.Make(
            expected.year, expected.month, expected.day, expected.hour,
            expected.minute, expected.second)).elon
        found = astro.SearchSunLongitude(round(longitude / 30) * 30 % 360,
                                         start, 6)
      difference = abs((found.Utc().replace(tzinfo=None) - expected)
                       .total_seconds())
      self.assertLess(difference, GATE_SECONDS, event)

  def test_orc_002_local_day_matches_author_hanoi_dates(self):
    anchors = load("anchors.json")
    known = {item["gmt"] for item in anchors["known_source_inconsistencies"]}
    for event in anchors["author_events"]:
      if event["gmt"] in known:
        continue  # documented source inconsistency, see anchors.json
      expected = datetime.fromisoformat(event["gmt"])
      jd = (expected - datetime(2000, 1, 1, 12)).total_seconds() / 86400 \
          + oracle.J2000_JD
      day = oracle.iso_date(oracle.local_day_number(jd))
      self.assertEqual(day, event["hanoi_date"], event)


  def test_orc_010_known_source_inconsistency_is_real(self):
    """The documented inconsistency really is one under UTC+7 arithmetic."""
    for item in load("anchors.json")["known_source_inconsistencies"]:
      expected = datetime.fromisoformat(item["gmt"])
      jd = (expected - datetime(2000, 1, 1, 12)).total_seconds() / 86400 \
          + oracle.J2000_JD
      self.assertEqual(oracle.iso_date(oracle.local_day_number(jd)),
                       item["utc7_date"])
      self.assertNotEqual(item["utc7_date"], item["published_hanoi_date"])


class AnchorTest(unittest.TestCase):
  """ORC-003..006: published facts hold in the generated months."""

  def setUp(self):
    self.rows = month_rows()

  def span(self, year, month, leap):
    for row in self.rows:
      if row[0] == year and row[1] == month and row[2] == leap:
        start = date.fromisoformat(row[3])
        return row[3], (start + timedelta(days=row[4] - 1)).isoformat()
    self.fail(f"month not found {year} {month} {leap}")

  def test_orc_003_author_month_spans(self):
    for item in load("anchors.json")["month_spans"]:
      got = self.span(item["lunar_year"], item["month"], item["is_leap"])
      self.assertEqual(got, (item["start"], item["end"]), item)

  def test_orc_004_author_leap_month_span(self):
    for item in load("anchors.json")["leap_month_spans_without_number"]:
      leaps = [r for r in self.rows if r[0] == item["lunar_year"] and r[2] == 1]
      self.assertEqual(len(leaps), 1)
      row = leaps[0]
      end = (date.fromisoformat(row[3]) + timedelta(days=row[4] - 1)).isoformat()
      self.assertEqual((row[3], end), (item["start"], item["end"]))

  def test_orc_005_years_without_leap_month(self):
    leap_years = {int(y) for y in load("oracle_months.json")["leap_months"]}
    for year in load("anchors.json")["years_without_leap_month"]:
      self.assertNotIn(year, leap_years)

  def test_orc_006_vietnamese_tet_dates(self):
    for year, expected in load("anchors.json")["tet_vietnam"].items():
      row = [r for r in self.rows if r[0] == int(year) and r[1] == 1
             and r[2] == 0]
      self.assertEqual(row[0][3], expected, year)


class InvariantTest(unittest.TestCase):
  """ORC-007..008: structural properties of the generated months."""

  def test_orc_007_months_are_consecutive_and_29_or_30_days(self):
    rows = month_rows()
    for before, after in zip(rows, rows[1:]):
      expected = date.fromisoformat(before[3]) + timedelta(days=before[4])
      self.assertEqual(after[3], expected.isoformat(), (before, after))
      self.assertIn(before[4], (29, 30))

  def test_orc_008_each_year_has_12_or_13_months(self):
    rows = month_rows()
    leap_years = {int(y) for y in load("oracle_months.json")["leap_months"]}
    for year in range(oracle.FIRST_YEAR, oracle.LAST_YEAR + 1):
      count = sum(1 for r in rows if r[0] == year)
      # Months 11 and 12 of a lunar year belong to the block that also holds
      # months 1..10 of the next year, so the count per labelled year is
      # 12, or 13 when that year has a leap month.
      self.assertEqual(count, 13 if year in leap_years else 12, year)


class ReproducibilityTest(unittest.TestCase):
  """ORC-009: LUNAR-AC-7, regenerating reproduces committed fixtures."""

  def test_orc_009_generator_output_equals_committed_fixtures(self):
    with tempfile.TemporaryDirectory() as directory:
      oracle.build(Path(directory))
      for name in ("oracle_months.json", "oracle_events.json",
                   "boundary_cases.json"):
        self.assertEqual((Path(directory) / name).read_bytes(),
                         (FIXTURES / name).read_bytes(), name)


if __name__ == "__main__":
  unittest.main()
