# Logos

The Evermoon mark (concept E8, chosen by Fox on 2026-11-11) is a page torn from a wall calendar: a dark header with two binder rings, a grid of day cells, and one cell replaced by a reversed crescent moon. It reads as "a day on the lunar calendar that matters": an anniversary, rằm, mùng 1 or Tết, without showing any number. The stack of torn edges at the bottom says the page comes from a calendar people tear daily, a familiar object in Vietnamese homes.

| File | Use |
| --- | --- |
| `evermoon-app-icon.svg` | Master of the launcher icon: `primary` (#5354AD) ground, page in `tertiary-container` (#FFF3E3), header `#3B3B94`, day cells `#D0C5B6`, crescent in `primary`. |
| `evermoon-mark.svg` | The page alone on a transparent ground, for splash and about screens. |
| `evermoon-monochrome.svg` | Single-ink silhouette used for the Android 13 themed icon: the crescent and day cells are cut out. |
| `evermoon-icon.png` | 512 px preview of the production launcher icon. |
| `evermoon-icon-dev.png` | 512 px preview of the dev flavor icon: same mark on `secondary` (#506260), so the two installs are told apart. |

## Android

- Adaptive icon (API 26+): `mipmap-anydpi-v26/ic_launcher.xml` and `ic_launcher_round.xml` with background `@color/ic_launcher_background`, foreground `drawable/ic_launcher_foreground.xml` (vector), and `drawable/ic_launcher_monochrome.xml`.
- The page is scaled to 82 % so its corners and torn edge stay inside the 66 dp safe circle of the 108 dp canvas; every launcher mask keeps it whole.
- Legacy PNGs for each density show the 72 dp visible area; the dev flavor overrides the background color and PNGs under `android/app/src/dev/res/`.
- Play Store icon: `android/app/src/main/ic_launcher-playstore.png` (512 px).

Never add text, numbers, gradients or shadows to the mark.
