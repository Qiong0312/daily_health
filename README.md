# Bloom

A gentle daily health tracker for period, bowel habits, and supplements — built with Flutter.

## Features (v1)

- **Today** — **period month calendar** (tap days to set start/end/clear; range highlighted), Bristol bowel log, supplement check-offs
- **Summary** — supplement adherence, recent bowel log count, Bristol-type trends, cycle stats
- **Settings** — manage supplements and cycle length
- **iOS widget** — period quick actions, Bristol log, supplement check-offs (see `ios/WIDGET_SETUP.md`)

All data is stored locally on device via `shared_preferences`.

## Run

```bash
cd daily_health
flutter pub get
flutter run
```

## Project location

Sibling to `daily_ticker` at `/Users/qiongwu/Project/daily_health`.
