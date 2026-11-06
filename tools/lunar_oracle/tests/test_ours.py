"""Tests for our own implementation (plan 0001, slice S2).

Stable test IDs ORS-001 and so on; they map to LUNAR-AC-2, LUNAR-AC-3 and
LUNAR-AC-4 in docs/plans/0001-lunar-package.md.

The oracle uses the apparent Sun-Moon conjunction (it includes the Sun's
aberration); the formulas we implement (Meeus, chapter 49) give new moons
about 35 to 40 seconds earlier, which matches the author's published tables.
So differences from the oracle are expected only for the few months whose new
moon or principal term lies within about a minute of local midnight. They are
pinned in convention_differences.json and must be decided (open decision D7).

Run from tools/lunar_oracle: python3 -m unittest discover -s tests -v
"""
from __future__ import annotations

import json
import statistics
import sys
import unittest
from datetime import date, datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import compare  # noqa: E402
import ours  # noqa: E402

FIXTURES = compare.FIXTURES


def load(name):
  return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


class AccuracyTest(unittest.TestCase):

  @classmethod
  def setUpClass(cls):
    cls.moon_errors, cls.term_errors = compare.event_errors()

  def test_ors_001_new_moon_error_against_oracle(self):
    self.assertLess(max(map(abs, self.moon_errors)), 60)
    # The systematic offset is the aberration convention, about -35 s.
    self.assertAlmostEqual(statistics.mean(self.moon_errors), -35, delta=5)

  def test_ors_002_principal_term_error_against_oracle(self):
    self.assertLess(max(map(abs, self.term_errors)), 90)
    self.assertLess(abs(statistics.mean(self.term_errors)), 5)

  def test_ors_003_new_moons_match_author_tables(self):
    for event in load("anchors.json")["author_events"]:
      if event["kind"] != "new_moon":
        continue
      expected = datetime.fromisoformat(event["gmt"])
      jd = (expected - datetime(2000, 1, 1, 12)).total_seconds() / 86400 \
          + ours.J2000
      k = round((jd - 2451550.09766) / 29.530588861)
      mine = ours.jde_to_jd_ut(ours.new_moon_jde(k))
      self.assertLess(abs(mine - jd) * 86400, 5, event)


class MonthTest(unittest.TestCase):

  @classmethod
  def setUpClass(cls):
    cls.mine = ours.build_months(compare.FIRST, compare.LAST)

  def rows(self):
    return {(m[0], m[1], m[2]): (date.fromordinal(m[3] - 1721425).isoformat(),
                                 m[4]) for m in self.mine["months"]}

  def test_ors_004_differences_from_oracle_are_exactly_the_pinned_set(self):
    diffs, _, _ = compare.month_differences()
    got = [{"month": list(k), "ours": a, "oracle": b} for k, a, b in diffs]
    pinned = load("convention_differences.json")["differences"]
    self.assertEqual(
        json.loads(json.dumps(got, sort_keys=True)),
        json.loads(json.dumps(pinned, sort_keys=True)))

  def test_ors_005_every_difference_is_in_a_boundary_case_year(self):
    boundary = load("boundary_cases.json")
    years = {d["month"][0] for d in boundary["structural_differences"]}
    for item in load("convention_differences.json")["differences"]:
      year = item["month"][0]
      self.assertTrue(year in years or year - 1 in years, item)

  def test_ors_006_published_anchors(self):
    rows = self.rows()
    anchors = load("anchors.json")
    for year, expected in anchors["tet_vietnam"].items():
      self.assertEqual(rows[(int(year), 1, 0)][0], expected, year)
    for item in anchors["month_spans"]:
      start, days = rows[(item["lunar_year"], item["month"], item["is_leap"])]
      self.assertEqual(start, item["start"], item)
    for year in anchors["years_without_leap_month"]:
      self.assertNotIn(year, self.mine["leaps"])
    leap = anchors["leap_month_spans_without_number"][0]
    leap_rows = [v for k, v in rows.items()
                 if k[0] == leap["lunar_year"] and k[2] == 1]
    self.assertEqual(leap_rows[0][0], leap["start"])

  def test_ors_007_leap_months_match_oracle_except_pinned_years(self):
    oracle = {int(y): m for y, m in load("oracle_months.json")[
        "leap_months"].items()}
    pinned = {d["month"][0] for d in load(
        "convention_differences.json")["differences"] if d["month"][2] == 1}
    for year in range(compare.FIRST, compare.LAST + 1):
      if year in pinned:
        continue
      self.assertEqual(self.mine["leaps"].get(year), oracle.get(year), year)


if __name__ == "__main__":
  unittest.main()
