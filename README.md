# Bloom

A gentle daily health tracker for period, bowel habits, and a daily checklist — built with Flutter.

## Features (v1)

- **Today** — **period month calendar** (tap days to set start/end/clear; range highlighted), Bristol bowel log, daily checklist (supplements, habits, errands, etc.)
- **Summary** — checklist completion, recent bowel log count, Bristol-type trends, cycle stats
- **Settings** — manage checklist items and cycle length
- **iOS widget** — period quick actions, Bristol log, checklist check-offs (see `ios/WIDGET_SETUP.md`)

All data is stored locally on device via `shared_preferences`.

## Run

```bash
cd daily_health
flutter pub get
flutter run
```

## Project location

Sibling to `daily_ticker` at `/Users/qiongwu/Project/daily_health`.
