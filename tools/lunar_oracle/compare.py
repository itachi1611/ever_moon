"""Compare our implementation (ours.py) with the oracle fixtures (plan 0001, S2).

Usage: python3 compare.py
Prints event-time errors and every month that differs from the oracle, and
whether each difference is explained by a boundary case (an event closer to
local midnight than the margin used by the oracle).
"""
from __future__ import annotations

import bisect
import json
from datetime import date
from pathlib import Path

import ours

FIXTURES = Path(__file__).resolve().parents[2] / (
    "packages/lunar_calendar/test/fixtures")
FIRST, LAST = 1800, 2199


def load(name):
  return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


def event_errors():
  events = load("oracle_events.json")
  moon_oracle = events["new_moons_jd_ut"]
  moons = ours.lunations(FIRST, LAST)
  errors = []
  for jd in moons:
    i = bisect.bisect_left(moon_oracle, jd)
    near = [moon_oracle[j] for j in (i - 1, i) if 0 <= j < len(moon_oracle)]
    best = min(((jd - o) * 86400 for o in near), key=abs)
    if abs(best) < 10 * 86400:  # skip lunations outside the oracle range
      errors.append(best)
  term_errors = []
  for year, values in ours.principal_terms(FIRST, LAST).items():
    oracle_values = events["principal_terms_jd_ut"][str(year)]
    term_errors += [(a - b) * 86400 for a, b in zip(values, oracle_values)]
  return errors, term_errors


def describe(name, errs):
  worst = max(errs, key=abs)
  mean = sum(errs) / len(errs)
  print(f"{name}: n={len(errs)} mean={mean:+.1f}s max|err|={abs(worst):.1f}s")


def month_differences():
  mine = ours.build_months(FIRST, LAST)["months"]
  theirs = load("oracle_months.json")["months"]
  mine_rows = {(m[0], m[1], m[2]): (date.fromordinal(m[3] - 1721425)
                                    .isoformat(), m[4]) for m in mine}
  oracle_rows = {(m[0], m[1], m[2]): (m[3], m[4]) for m in theirs}
  diffs = []
  for key in sorted(set(mine_rows) | set(oracle_rows)):
    if mine_rows.get(key) != oracle_rows.get(key):
      diffs.append((key, mine_rows.get(key), oracle_rows.get(key)))
  return diffs, len(mine_rows), len(oracle_rows)


def write_differences(path: Path) -> None:
  """Persist the known differences so tests can pin them exactly."""
  diffs, _, _ = month_differences()
  rows = [{"month": list(key), "ours": mine, "oracle": theirs}
          for key, mine, theirs in diffs]
  text = json.dumps({"differences": rows}, ensure_ascii=False,
                    separators=(",", ":"), sort_keys=True)
  path.write_text(text + "\n", encoding="utf-8")


def main():
  import sys
  if "--write" in sys.argv:
    write_differences(FIXTURES / "convention_differences.json")
    print("wrote convention_differences.json")
  moon_errors, term_errors = event_errors()
  describe("new moon (ours - oracle)", moon_errors)
  describe("principal term (ours - oracle)", term_errors)
  boundary = load("boundary_cases.json")
  affected_years = {d["month"][0]
                    for d in boundary["structural_differences"]}
  diffs, n_mine, n_oracle = month_differences()
  print(f"months ours={n_mine} oracle={n_oracle} differing={len(diffs)}")
  unexplained = [d for d in diffs if d[0][0] not in affected_years
                 and d[0][0] - 1 not in affected_years]
  print(f"differences not in a boundary-affected year: {len(unexplained)}")
  for item in unexplained[:30]:
    print("  UNEXPLAINED", item)
  for item in diffs[:30]:
    print("  diff", item)


if __name__ == "__main__":
  main()
