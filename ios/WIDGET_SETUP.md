# Bloom iOS home screen widget

## One-time Xcode setup

```bash
cd /Users/qiongwu/Project/daily_health/ios
gem install xcodeproj   # if needed
ruby configure_widget.rb
open Runner.xcworkspace
```

In Xcode:

1. Select **Runner** → **Signing & Capabilities** → add **App Groups** → `group.com.dailyhealth.dailyHealth`
2. Select **BloomWidgetExtension** → same App Group
3. Build **Runner** on a device (widgets need a real device or simulator with the app installed)

## Widget features

| Size | Contents |
|------|----------|
| **Small** | Period status (or predicted next start) + Start / End today |
| **Medium** | Period + Bristol 1–7 row |
| **Large** | Period + Bristol + today’s checklist (tap to check off) |

Edits from the widget are saved to the App Group and merged when you open the app.

## Sync

The Flutter app exports a snapshot after every save and on launch (after importing widget changes).
