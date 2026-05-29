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
        let snapshot = WidgetDataStore.normalizedForToday(WidgetDataStore.load())
        completion(Timeline(entries: [BloomWidgetEntry(date: now, snapshot: snapshot)], policy: .after(now.addingTimeInterval(900))))
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
