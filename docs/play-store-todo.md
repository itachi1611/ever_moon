# Google Play release TODO

Status as of 2026-11-26. App: `com.fox.evermoon`, account foxy1611 (personal).

## Done

- App content: privacy policy, ads, content rating (3+), target audience (18+), data safety, government, financial, health, sign-in details, advertising ID.
- Internal testing: release `1.0.0 (2)` (versionCode 2) published.
- Store settings: category Lifestyle, contact email.
- Store listing text (en-US, default and only store language): name, short and full description.
- Feature graphic: `docs/design/store/feature-graphic.png` (1024x500, source SVG next to it).
- Closed testing (Alpha): country Vietnam, release `1.0.0 (2) Closed test` drafted.

## Store listing: assets still to upload

Page: Store presence > Main store listing > Default store listing (en-US).

- [ ] App icon 512x512: `docs/design/icon/evermoon-icon.png`.
- [ ] Feature graphic: `docs/design/store/feature-graphic.png`.
- [ ] Phone screenshots (required): upload the 5 files in `docs/design/store/screenshots/` (Pixel 8, 1080x2400, prod build, English, light theme, sample data): `01-upcoming`, `02-add-anniversary`, `03-calendar`, `04-year`, `05-settings`. Play needs 2 to 8, PNG or JPEG, aspect ratio 16:9 or 9:16.
- [ ] Save as draft, then Next and save in the Review step.
- Optional, leave empty for now: video, tablet, desktop and Android XR assets.

## Closed testing and production access

- [ ] Finish the Alpha release: Next, Save and publish (needs the store listing done first).
- [ ] Collect 12 or more Google account emails; create the tester list or Google group and add it to Alpha.
- [ ] Share the opt-in link. Testers must opt in and stay for 14 continuous days.
- [ ] After 14 days with 12 or more opted-in testers: Dashboard > Apply for production access.
- [ ] Confirm the exact requirements on the dashboard, since Play policy can change.

## Later

- [ ] Vietnamese store listing (add vi in Manage languages once the text is ready).
- [ ] Service account for `release_play.sh` (key stored outside the repo), then validate with `release_play.sh internal --validate`.
- [ ] Check whether Play asks for a `SCHEDULE_EXACT_ALARM` declaration.
- [x] Note in `docs/ci-cd.md` that Play does not reuse version codes.
- [ ] Full description: add back a bullet that the app can remind on the 1st, the 15th and traditional festivals (Settings has toggles for them).
