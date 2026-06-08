import WidgetKit
import SwiftUI

struct BloomWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct BloomWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BloomWidgetEntry {
        BloomWidgetEntry(date: Date(), snapshot: placeholderSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (BloomWidgetEntry) -> Void) {
        WidgetDataStore.clearStaleSnapshotIfNeeded()
        let snapshot = WidgetDataStore.normalizedForToday(WidgetDataStore.load())
            ?? placeholderSnapshot
        completion(BloomWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BloomWidgetEntry>) -> Void) {
        WidgetDataStore.clearStaleSnapshotIfNeeded()
        let now = Date()
        let calendar = Calendar.current
        let snapshot = WidgetDataStore.normalizedForToday(WidgetDataStore.load())

        var entries: [BloomWidgetEntry] = [
            BloomWidgetEntry(date: now, snapshot: snapshot),
        ]

        // Refresh at next midnight so the widget clears yesterday without opening the app.
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
            var overnight = snapshot
            if var copy = overnight {
                copy.dateKey = WidgetDataStore.todayDateKey(for: tomorrow)
                copy.supplementDoses = WidgetDataStore.freshSupplementDoses(for: copy)
                copy.poopLogsToday = []
                copy.periodEndedTimeToday = nil
                copy.needsAppSync = false
                overnight = copy
            }
            entries.append(BloomWidgetEntry(date: tomorrow, snapshot: overnight))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private var placeholderSnapshot: WidgetSnapshot {
        WidgetSnapshot(
            updatedAt: "",
            dateKey: WidgetDataStore.todayDateKey(),
            averageCycleLength: 28,
            periodEvents: [],
            supplements: [
                WidgetSnapshotSupplement(id: "1", name: "Iron", dose: "65 mg", slots: ["morning"]),
            ],
            supplementDoses: [
                WidgetSnapshotSupplementDose(supplementId: "1", slot: "morning", taken: false),
            ],
            poopLogsToday: []
        )
    }
}
