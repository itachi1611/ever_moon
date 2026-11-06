# Lunar oracle and reference implementation

Tooling for [plan 0001](../../docs/plans/0001-lunar-package.md). Python 3 only; nothing here ships in the app.

| File | Purpose |
|---|---|
| `oracle.py` | Independent oracle. Uses the third-party `astronomy-engine` library (version pinned in `requirements.txt`) and the published rules to produce lunar months for lunar years 1800 to 2199 in UTC+7. |
| `ours.py` | Our own implementation from published formulas (Meeus, VSOP87 truncated, Espenak and Meeus Delta T). Executable reference for the Dart port. No third-party astronomy library. |
| `compare.py` | Compares `ours.py` with the oracle fixtures. `--write` refreshes `convention_differences.json`. |
| `tests/` | Stable test IDs `ORC-*` (oracle) and `ORS-*` (our implementation). |

Fixtures are written to `packages/lunar_calendar/test/fixtures/` so that the Python and the Dart tests read the same files.

## Commands

Working directory: this folder.

```
pip install -r requirements.txt
python3 oracle.py                      # regenerate oracle_months.json, oracle_events.json, boundary_cases.json
python3 compare.py --write             # regenerate convention_differences.json
python3 -m unittest discover -s tests -v
```

`anchors.json` is hand-transcribed from the author's published tables and is not generated.

## Notes

- Regeneration must reproduce the committed fixtures byte for byte (test `ORC-009`).
- Far-future results (after about 2100) depend on the Delta T model, whose uncertainty grows with the distance from the present.
- The original JavaScript of the rules' author is not used. See the licensing section of the [technical analysis](../../docs/technical-analysis-lunar-engine.md).
