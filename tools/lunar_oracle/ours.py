"""Our own implementation of the Vietnamese lunar calendar (plan 0001, S2).

Written from published sources only, with no third-party astronomy library:
  * Jean Meeus, "Astronomical Algorithms", 2nd ed.: chapter 49 (new moon),
    chapter 32 / Table 32.A (VSOP87 Earth series, truncated), chapter 25 and
    22 (aberration and nutation, low-accuracy forms).
  * Espenak and Meeus polynomial expressions for Delta T (NASA).
  * The rules published at
    https://informatik.uni-leipzig.de/~duc/amlich/calrules_en.html.
The original JavaScript of the rules' author was not consulted or copied.

This is the executable reference for the Dart port (slice S3). The oracle in
oracle.py is the independent check on it.
"""
from __future__ import annotations

import math
from datetime import date

TZ_HOURS = 7
J2000 = 2451545.0


# ---------------------------------------------------------------- Delta T

def delta_t_seconds(year: float) -> float:
  """Delta T = TT - UT in seconds (Espenak and Meeus polynomials)."""
  y = year
  if y < 1860:
    t = y - 1800
    return (13.72 - 0.332447 * t + 0.0068612 * t**2 + 0.0041116 * t**3
            - 0.00037436 * t**4 + 0.0000121272 * t**5
            - 0.0000001699 * t**6 + 0.000000000875 * t**7)
  if y < 1900:
    t = y - 1860
    return (7.62 + 0.5737 * t - 0.251754 * t**2 + 0.01680668 * t**3
            - 0.0004473624 * t**4 + t**5 / 233174)
  if y < 1920:
    t = y - 1900
    return (-2.79 + 1.494119 * t - 0.0598939 * t**2 + 0.0061966 * t**3
            - 0.000197 * t**4)
  if y < 1941:
    t = y - 1920
    return 21.20 + 0.84493 * t - 0.076100 * t**2 + 0.0020936 * t**3
  if y < 1961:
    t = y - 1950
    return 29.07 + 0.407 * t - t**2 / 233 + t**3 / 2547
  if y < 1986:
    t = y - 1975
    return 45.45 + 1.067 * t - t**2 / 260 - t**3 / 718
  if y < 2005:
    t = y - 2000
    return (63.86 + 0.3345 * t - 0.060374 * t**2 + 0.0017275 * t**3
            + 0.000651814 * t**4 + 0.00002373599 * t**5)
  if y < 2050:
    t = y - 2000
    return 62.92 + 0.32217 * t + 0.005589 * t**2
  if y < 2150:
    return -20 + 32 * ((y - 1820) / 100) ** 2 - 0.5628 * (2150 - y)
  return -20 + 32 * ((y - 1820) / 100) ** 2


def jde_to_jd_ut(jde: float) -> float:
  year = 2000.0 + (jde - J2000) / 365.25
  return jde - delta_t_seconds(year) / 86400.0


# --------------------------------------------------------------- new moon

_PLANETARY = [
    (299.77, 0.107408, 0.000325), (251.88, 0.016321, 0.000165),
    (251.83, 26.651886, 0.000164), (349.42, 36.412478, 0.000126),
    (84.66, 18.206239, 0.00011), (141.74, 53.303771, 0.000062),
    (207.14, 2.453732, 0.00006), (154.84, 7.306860, 0.000056),
    (34.52, 27.261239, 0.000047), (207.19, 0.121824, 0.000042),
    (291.34, 1.844379, 0.00004), (161.72, 24.198154, 0.000037),
    (239.56, 25.513099, 0.000035), (331.55, 3.592518, 0.000023),
]


def new_moon_jde(k: int) -> float:
  """Julian Ephemeris Day of lunation k (k = 0 is the new moon of Jan 2000)."""
  t = k / 1236.85
  jde = (2451550.09766 + 29.530588861 * k + 0.00015437 * t**2
         - 0.000000150 * t**3 + 0.00000000073 * t**4)
  e = 1 - 0.002516 * t - 0.0000074 * t**2
  rad = math.radians
  m = rad(2.5534 + 29.10535670 * k - 0.0000014 * t**2 - 0.00000011 * t**3)
  mp = rad(201.5643 + 385.81693528 * k + 0.0107582 * t**2
           + 0.00001238 * t**3 - 0.000000058 * t**4)
  f = rad(160.7108 + 390.67050284 * k - 0.0016118 * t**2
          - 0.00000227 * t**3 + 0.000000011 * t**4)
  om = rad(124.7746 - 1.56375588 * k + 0.0020672 * t**2 + 0.00000215 * t**3)
  sin = math.sin
  correction = (
      -0.40720 * sin(mp) + 0.17241 * e * sin(m) + 0.01608 * sin(2 * mp)
      + 0.01039 * sin(2 * f) + 0.00739 * e * sin(mp - m)
      - 0.00514 * e * sin(mp + m) + 0.00208 * e * e * sin(2 * m)
      - 0.00111 * sin(mp - 2 * f) - 0.00057 * sin(mp + 2 * f)
      + 0.00056 * e * sin(2 * mp + m) - 0.00042 * sin(3 * mp)
      + 0.00042 * e * sin(m + 2 * f) + 0.00038 * e * sin(m - 2 * f)
      - 0.00024 * e * sin(2 * mp - m) - 0.00017 * sin(om)
      - 0.00007 * sin(mp + 2 * m) + 0.00004 * sin(2 * mp - 2 * f)
      + 0.00004 * sin(3 * m) + 0.00003 * sin(mp + m - 2 * f)
      + 0.00003 * sin(2 * mp + 2 * f) - 0.00003 * sin(mp + m + 2 * f)
      + 0.00003 * sin(mp - m + 2 * f) - 0.00002 * sin(mp - m - 2 * f)
      - 0.00002 * sin(3 * mp + m) + 0.00002 * sin(4 * mp))
  extra = 0.0
  for base, rate, amplitude in _PLANETARY:
    angle = base + rate * k
    if base == 299.77:
      angle -= 0.009173 * t**2
    extra += amplitude * sin(rad(angle))
  return jde + correction + extra


# ------------------------------------------------------------ sun longitude
# VSOP87 Earth heliocentric longitude, truncated (Meeus Table 32.A).
# Each row: amplitude (1e-8 rad), phase (rad), frequency (rad per 1000 years).

_L0 = [
    (175347046, 0, 0), (3341656, 4.6692568, 6283.07585),
    (34894, 4.6261, 12566.1517), (3497, 2.7441, 5753.3849),
    (3418, 2.8289, 3.5231), (3136, 3.6277, 77713.7715),
    (2676, 4.4181, 7860.4194), (2343, 6.1352, 3930.2097),
    (1324, 0.7425, 11506.7698), (1273, 2.0371, 529.691),
    (1199, 1.1096, 1577.3435), (990, 5.233, 5884.927),
    (902, 2.045, 26.298), (857, 3.508, 398.149), (780, 1.179, 5223.694),
    (753, 2.533, 5507.553), (505, 4.583, 18849.228), (492, 4.205, 775.523),
    (357, 2.92, 0.067), (317, 5.849, 11790.629), (284, 1.899, 796.298),
    (271, 0.315, 10977.079), (243, 0.345, 5486.778), (206, 4.806, 2544.314),
    (205, 1.869, 5573.143), (202, 2.458, 6069.777), (156, 0.833, 213.299),
    (132, 3.411, 2942.463), (126, 1.083, 20.775), (115, 0.645, 0.98),
    (103, 0.636, 4694.003), (102, 0.976, 15720.839), (102, 4.267, 7.114),
    (99, 6.21, 2146.17), (98, 0.68, 155.42), (86, 5.98, 161000.69),
    (85, 1.3, 6275.96), (85, 3.67, 71430.7), (80, 1.81, 17260.15),
    (79, 3.04, 12036.46), (75, 1.76, 5088.63), (74, 3.5, 3154.69),
    (74, 4.68, 801.82), (70, 0.83, 9437.76), (62, 3.98, 8827.39),
    (61, 1.82, 7084.9), (57, 2.78, 6286.6), (56, 4.39, 14143.5),
    (56, 3.47, 6279.55), (52, 0.19, 12139.55), (52, 1.33, 1748.02),
    (51, 0.28, 5856.48), (49, 0.49, 1194.45), (41, 5.37, 8429.24),
    (41, 2.4, 19651.05), (39, 6.17, 10447.39), (37, 6.04, 10213.29),
    (37, 2.57, 1059.38), (36, 1.71, 2352.87), (36, 1.78, 6812.77),
    (33, 0.59, 17789.85), (30, 0.44, 83996.85), (30, 2.74, 1349.87),
    (25, 3.16, 4690.48),
]
_L1 = [
    (628331966747, 0, 0), (206059, 2.678235, 6283.07585),
    (4303, 2.6351, 12566.1517), (425, 1.59, 3.523), (119, 5.796, 26.298),
    (109, 2.966, 1577.344), (93, 2.59, 18849.23), (72, 1.14, 529.69),
    (68, 1.87, 398.15), (67, 4.41, 5507.55), (59, 2.89, 5223.69),
    (56, 2.17, 155.42), (45, 0.4, 796.3), (36, 0.47, 775.52),
    (29, 2.65, 7.11), (21, 5.34, 0.98), (19, 1.85, 5486.78),
    (19, 4.97, 213.3), (17, 2.99, 6275.96), (16, 0.03, 2544.31),
    (16, 1.43, 2146.17), (15, 1.21, 10977.08), (12, 2.83, 1748.02),
    (12, 3.26, 5088.63), (12, 5.27, 1194.45), (12, 2.08, 4694),
    (11, 0.77, 553.57), (10, 1.3, 6286.6), (10, 4.24, 1349.87),
    (9, 2.7, 242.73), (9, 5.64, 951.72), (8, 5.3, 2352.87),
    (6, 2.65, 9437.76), (6, 4.67, 4690.48),
]
_L2 = [
    (52919, 0, 0), (8720, 1.0721, 6283.0758), (309, 0.867, 12566.152),
    (27, 0.05, 3.52), (16, 5.19, 26.3), (16, 3.68, 155.42),
    (10, 0.76, 18849.23), (9, 2.06, 77713.77), (7, 0.83, 775.52),
    (5, 4.66, 1577.34), (4, 1.03, 7.11), (4, 3.44, 5573.14),
    (3, 5.14, 796.3), (3, 6.05, 5507.55), (3, 1.19, 242.73),
    (3, 6.12, 529.69), (3, 0.31, 398.15), (3, 2.28, 553.57),
    (2, 4.38, 5223.69), (2, 3.75, 0.98),
]
_L3 = [(289, 5.844, 6283.076), (35, 0, 0), (17, 5.49, 12566.15),
       (3, 5.2, 155.42), (1, 4.72, 3.52), (1, 5.3, 18849.23),
       (1, 5.97, 242.73)]
_L4 = [(114, 3.142, 0), (8, 4.13, 6283.08), (1, 3.84, 12566.15)]
_L5 = [(1, 3.14, 0)]
_R0 = [(100013989, 0, 0), (1670700, 3.0984635, 6283.07585),
       (13956, 3.05525, 12566.1517), (3084, 5.1985, 77713.7715),
       (1628, 1.1739, 5753.3849), (1576, 2.8469, 7860.4194),
       (925, 5.453, 11506.77), (542, 4.564, 3930.21)]
_R1 = [(103019, 1.10749, 6283.07585), (1721, 1.0644, 12566.1517),
       (702, 3.142, 0)]


def _series(terms, tau):
  return sum(a * math.cos(b + c * tau) for a, b, c in terms)


def sun_apparent_longitude(jde: float) -> float:
  """Apparent geocentric longitude of the Sun in degrees [0, 360)."""
  tau = (jde - J2000) / 365250.0
  t = tau * 10.0
  heliocentric = (_series(_L0, tau) + _series(_L1, tau) * tau
                  + _series(_L2, tau) * tau**2 + _series(_L3, tau) * tau**3
                  + _series(_L4, tau) * tau**4
                  + _series(_L5, tau) * tau**5) / 1e8
  longitude = math.degrees(heliocentric) + 180.0
  longitude += -0.09033 / 3600.0                   # to the FK5 frame
  radius = (_series(_R0, tau) + _series(_R1, tau) * tau) / 1e8
  aberration = -20.4898 / radius / 3600.0
  om = math.radians(125.04452 - 1934.136261 * t)
  sun_mean = math.radians(280.4665 + 36000.7698 * t)
  moon_mean = math.radians(218.3165 + 481267.8813 * t)
  nutation = (-17.20 * math.sin(om) - 1.32 * math.sin(2 * sun_mean)
              - 0.23 * math.sin(2 * moon_mean) + 0.21 * math.sin(2 * om)
              ) / 3600.0
  return (longitude + aberration + nutation) % 360.0


def principal_term_jde(year: int, index: int) -> float:
  """JDE when the Sun reaches longitude index * 30 degrees in `year`."""
  target = index * 30.0
  march_equinox = date(year, 3, 20).toordinal() + 1721424.5
  # Terms at 300 and 330 degrees fall in January and February of `year`,
  # before the March equinox; the others follow it within the same year.
  offset_degrees = target - 360.0 if index >= 10 else target
  jde = march_equinox + offset_degrees / 0.9856474
  for _ in range(8):
    diff = (sun_apparent_longitude(jde) - target + 180) % 360 - 180
    jde -= diff / 0.9856474
  return jde


# ------------------------------------------------------------------ rules

def local_day(jd_ut: float) -> int:
  return math.floor(jd_ut + 0.5 + TZ_HOURS / 24.0)


def lunations(first_year: int, last_year: int) -> list[float]:
  """UT Julian dates of new moons from Sep first_year-1 to Mar last_year+2."""
  low = math.floor((first_year - 1 + 0.67 - 2000) * 12.3685)
  high = math.ceil((last_year + 2 + 0.2 - 2000) * 12.3685)
  return [jde_to_jd_ut(new_moon_jde(k)) for k in range(low, high + 1)]


def principal_terms(first_year: int, last_year: int) -> dict[int, list[float]]:
  return {
      year: [jde_to_jd_ut(principal_term_jde(year, i)) for i in range(12)]
      for year in range(first_year - 1, last_year + 3)
  }


def build_months(first_year: int, last_year: int) -> dict:
  """Months [lunar_year, month, is_leap, start_ordinal_jdn, days] plus leaps."""
  moons = [local_day(jd) for jd in lunations(first_year, last_year)]
  term_days = set()
  month11 = {}
  for year, values in principal_terms(first_year, last_year).items():
    days = [local_day(jd) for jd in values]
    term_days.update(days)
    solstice = days[9]
    month11[year] = max(i for i, d in enumerate(moons) if d <= solstice)
  months, leaps = [], {}
  for year in range(first_year - 1, last_year + 1):
    begin, end = month11[year], month11[year + 1]
    span = range(begin, end)
    has_term = [any(moons[i] <= d < moons[i + 1] for d in term_days)
                for i in span]
    leap_at = None
    if end - begin == 13:
      leap_at = next(j for j in range(1, 13) if not has_term[j])
    number, lunar_year = 11, year
    for j, i in enumerate(span):
      is_leap = j == leap_at
      if j and not is_leap:
        number = number % 12 + 1
        lunar_year += number == 1
      if first_year <= lunar_year <= last_year:
        months.append([lunar_year, number, int(is_leap), moons[i],
                       moons[i + 1] - moons[i]])
        if is_leap:
          leaps[lunar_year] = number
  return {"months": months, "leaps": leaps}
