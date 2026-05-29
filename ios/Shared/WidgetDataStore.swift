import Foundation
import WidgetKit

// MARK: - Models

struct WidgetSnapshotPeriodEvent: Codable, Identifiable {
    var id: String
    var startDate: String
    var endDate: String?
}

struct WidgetSnapshotSupplement: Codable, Identifiable {
    var id: String
    var name: String
    var dose: String?
    var slots: [String]
}

struct WidgetSnapshotSupplementDose: Codable {
    var supplementId: String
    var slot: String
    var taken: Bool
}

struct WidgetSnapshotPoopLog: Codable, Identifiable {
    var id: String
    var date: String
    var time: String
    var shape: String
}

/// One day in the Monday–Sunday strip shown on the widget.
struct WidgetWeekDay: Identifiable {
    var id: String { dateKey }
    let dateKey: String
    let weekdayLabel: String
    let dayNumber: Int
    let isToday: Bool
    let onPeriod: Bool
    let isStart: Bool
    let isEnd: Bool
    let isPredicted: Bool

    var marker: String? {
        if isStart && isEnd { return "●" }
        if isStart { return "S" }
        if isEnd { return "E" }
        if isPredicted { return "P" }
        return nil
    }
}

struct WidgetSnapshot: Codable {
    var version: Int = 1
    var updatedAt: String
    var needsAppSync: Bool = false
    var dateKey: String
    var averageCycleLength: Int = 28
    var periodEvents: [WidgetSnapshotPeriodEvent] = []
    var supplements: [WidgetSnapshotSupplement] = []
    var supplementDoses: [WidgetSnapshotSupplementDose] = []
    var poopLogsToday: [WidgetSnapshotPoopLog] = []
    /// Set when period is ended today from the widget (`HH:mm`, for confirmation copy).
    var periodEndedTimeToday: String?
}

// MARK: - Storage

enum WidgetDataStore {
    static let appGroupId = "group.com.dailyhealth.dailyHealth"
    static let fileName = "bloom_widget_snapshot.json"
    /// Posted when widget intents save data that the app should merge (`needsAppSync == true`).
    static let dataChangedDarwinNotification = "com.dailyhealth.widgetDataChanged" as CFString

    static func fileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent(fileName)
    }

    static func readRaw() -> String? {
        guard let url = fileURL(),
              let data = try? Data(contentsOf: url) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func writeRaw(_ json: String) throws {
        guard let url = fileURL() else { throw WidgetStoreError.noContainer }
        try json.write(to: url, atomically: true, encoding: .utf8)
    }

    static func load() -> WidgetSnapshot? {
        guard let raw = readRaw(),
              let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: WidgetSnapshot, markNeedsSync: Bool = false) throws {
        var copy = snapshot
        copy.needsAppSync = markNeedsSync
        copy.updatedAt = ISO8601DateFormatter().string(from: Date())
        let data = try JSONEncoder().encode(copy)
        guard let url = fileURL() else { throw WidgetStoreError.noContainer }
        try data.write(to: url, options: .atomic)
        if markNeedsSync {
            notifyAppToSync()
        }
        reloadTimelines()
    }

    static func notifyAppToSync() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(rawValue: dataChangedDarwinNotification),
            nil,
            nil,
            true
        )
    }

    static func reloadTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func todayDateKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    static func addDaysToDateKey(_ key: String, days: Int) -> String {
        guard let date = parseDateKey(key) else { return key }
        let next = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
        return todayDateKey(for: next)
    }

    static func parseDateKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.date(from: key)
    }

    static func daysBetween(_ startKey: String, _ endKey: String) -> Int {
        guard let start = parseDateKey(startKey),
              let end = parseDateKey(endKey) else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func isDateInPeriod(_ dateKey: String, _ event: WidgetSnapshotPeriodEvent) -> Bool {
        if dateKey < event.startDate { return false }
        let end = event.endDate ?? todayDateKey()
        return dateKey <= end
    }

    static func normalizedForToday(_ snapshot: WidgetSnapshot?) -> WidgetSnapshot? {
        guard var copy = snapshot else { return nil }
        let today = todayDateKey()
        guard copy.dateKey != today else { return copy }
        copy.dateKey = today
        copy.poopLogsToday = []
        copy.supplementDoses = freshSupplementDoses(for: copy)
        copy.needsAppSync = false
        return copy
    }

    static func clearStaleSnapshotIfNeeded() {
        guard let snapshot = load(), snapshot.dateKey != todayDateKey() else { return }
        var fresh = snapshot
        let pendingSync = snapshot.needsAppSync
        fresh.dateKey = todayDateKey()
        fresh.supplementDoses = freshSupplementDoses(for: fresh)
        fresh.poopLogsToday = []
        fresh.periodEndedTimeToday = nil
        try? save(fresh, markNeedsSync: pendingSync)
    }

    private static func loadMutableForToday() throws -> WidgetSnapshot {
        if load() == nil {
            let bootstrap = WidgetSnapshot(
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                dateKey: todayDateKey(),
                averageCycleLength: 28,
                periodEvents: [],
                supplements: [],
                supplementDoses: [],
                poopLogsToday: []
            )
            try save(bootstrap, markNeedsSync: false)
        }
        guard var snapshot = load() else { throw WidgetStoreError.noSnapshot }
        let today = todayDateKey()
        if snapshot.dateKey != today {
            let pendingSync = snapshot.needsAppSync
            snapshot.dateKey = today
            snapshot.supplementDoses = freshSupplementDoses(for: snapshot)
            snapshot.poopLogsToday = []
            snapshot.periodEndedTimeToday = nil
            snapshot.needsAppSync = pendingSync
            try save(snapshot, markNeedsSync: pendingSync)
        }
        return snapshot
    }

    private static func currentTimeHHmm() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private static func freshSupplementDoses(for snapshot: WidgetSnapshot) -> [WidgetSnapshotSupplementDose] {
        snapshot.supplements.flatMap { sup in
            sup.slots.map { slot in
                WidgetSnapshotSupplementDose(
                    supplementId: sup.id,
                    slot: slot,
                    taken: false
                )
            }
        }
    }

    // MARK: Period mutations

    static func setPeriodStartToday() throws {
        try setPeriodStart(on: todayDateKey())
    }

    static func setPeriodEndToday() throws {
        try setPeriodEnd(on: todayDateKey())
    }

    static func setPeriodStart(on dateKey: String) throws {
        var list: [WidgetSnapshotPeriodEvent] = []
        for e in (try loadMutableForToday()).periodEvents {
            if e.startDate > dateKey { continue }
            if let end = e.endDate {
                if end < dateKey {
                    list.append(e)
                    continue
                }
                if e.startDate < dateKey {
                    let prev = addDaysToDateKey(dateKey, days: -1)
                    if prev >= e.startDate {
                        var trimmed = e
                        trimmed.endDate = prev
                        list.append(trimmed)
                    }
                }
                continue
            }
            if dateKey <= e.startDate { continue }
            let prev = addDaysToDateKey(dateKey, days: -1)
            if prev >= e.startDate {
                var trimmed = e
                trimmed.endDate = prev
                list.append(trimmed)
            }
        }
        list.removeAll { $0.startDate == dateKey && $0.endDate == nil }
        list.append(WidgetSnapshotPeriodEvent(id: UUID().uuidString, startDate: dateKey, endDate: nil))
        list.sort { $0.startDate < $1.startDate }
        var snapshot = try loadMutableForToday()
        snapshot.periodEvents = list
        if dateKey == todayDateKey() {
            snapshot.periodEndedTimeToday = nil
        }
        try save(snapshot, markNeedsSync: true)
    }

    static func setPeriodEnd(on dateKey: String) throws {
        var snapshot = try loadMutableForToday()
        var list = snapshot.periodEvents
        var target: WidgetSnapshotPeriodEvent?
        for e in list {
            if e.startDate > dateKey { continue }
            if let end = e.endDate, end < dateKey { continue }
            if target == nil || e.startDate > target!.startDate {
                target = e
            }
        }
        if var t = target, let i = list.firstIndex(where: { $0.id == t.id }) {
            t.endDate = dateKey
            list[i] = t
        } else {
            list.append(
                WidgetSnapshotPeriodEvent(
                    id: UUID().uuidString,
                    startDate: dateKey,
                    endDate: dateKey
                )
            )
        }
        list.sort { $0.startDate < $1.startDate }
        snapshot.periodEvents = list
        if dateKey == todayDateKey() {
            snapshot.periodEndedTimeToday = currentTimeHHmm()
        }
        try save(snapshot, markNeedsSync: true)
    }

    // MARK: Bristol / supplements

    static func addBristolLog(shape: String) throws {
        var snapshot = try loadMutableForToday()
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let time = formatter.string(from: now)
        // One Bristol pick per day on the widget; a new tap replaces the previous.
        snapshot.poopLogsToday = [
            WidgetSnapshotPoopLog(
                id: UUID().uuidString,
                date: snapshot.dateKey,
                time: time,
                shape: shape
            ),
        ]
        try save(snapshot, markNeedsSync: true)
    }

    static func toggleSupplement(atSortedIndex index: Int) throws {
        let snapshot = try loadMutableForToday()
        let doses = snapshot.supplementDosesSorted
        guard index >= 0, index < doses.count else { return }
        let dose = doses[index]
        try toggleSupplement(supplementId: dose.supplementId, slot: dose.slot)
    }

    static func toggleSupplement(supplementId: String, slot: String) throws {
        var snapshot = try loadMutableForToday()
        if let index = snapshot.supplementDoses.firstIndex(where: {
            $0.supplementId == supplementId && $0.slot == slot
        }) {
            snapshot.supplementDoses[index].taken.toggle()
        } else {
            snapshot.supplementDoses.append(
                WidgetSnapshotSupplementDose(
                    supplementId: supplementId,
                    slot: slot,
                    taken: true
                )
            )
        }
        try save(snapshot, markNeedsSync: true)
    }
}

enum WidgetStoreError: Error {
    case noContainer
    case noSnapshot
}

// MARK: - Display helpers

extension WidgetSnapshot {
    func isOnPeriod(on dateKey: String = WidgetDataStore.todayDateKey()) -> Bool {
        periodEvents.contains { WidgetDataStore.isDateInPeriod(dateKey, $0) }
    }

    func cycleDay(on dateKey: String = WidgetDataStore.todayDateKey()) -> Int? {
        for event in periodEvents.reversed() {
            if WidgetDataStore.isDateInPeriod(dateKey, event) {
                return WidgetDataStore.daysBetween(event.startDate, dateKey) + 1
            }
        }
        return nil
    }

    func averageCycleFromHistory() -> Int? {
        guard periodEvents.count >= 2 else { return nil }
        let sorted = periodEvents.sorted { $0.startDate < $1.startDate }
        var sum = 0
        for i in 0..<(sorted.count - 1) {
            sum += WidgetDataStore.daysBetween(sorted[i].startDate, sorted[i + 1].startDate)
        }
        let n = sorted.count - 1
        let avg = Int((Double(sum) / Double(n)).rounded())
        return min(45, max(21, avg))
    }

    func effectiveCycleLength() -> Int {
        averageCycleFromHistory() ?? averageCycleLength
    }

    func predictedNextStartKey() -> String? {
        guard !periodEvents.isEmpty else { return nil }
        let sorted = periodEvents.sorted { $0.startDate < $1.startDate }
        guard let last = sorted.last else { return nil }
        return WidgetDataStore.addDaysToDateKey(last.startDate, days: effectiveCycleLength())
    }

    func endedPeriodToday(on dateKey: String = WidgetDataStore.todayDateKey()) -> Bool {
        periodEvents.contains { $0.endDate == dateKey }
    }

    /// Bleeding today and not yet marked ended today (End button still applies).
    func shouldShowEndPeriodButton(on dateKey: String = WidgetDataStore.todayDateKey()) -> Bool {
        isOnPeriod(on: dateKey) && !endedPeriodToday(on: dateKey)
    }

    func shouldShowStartPeriodButton(on dateKey: String = WidgetDataStore.todayDateKey()) -> Bool {
        if endedPeriodToday(on: dateKey) { return false }
        return !isOnPeriod(on: dateKey)
    }

    func periodStatusLine() -> String {
        let today = WidgetDataStore.todayDateKey()
        if endedPeriodToday(on: today) {
            if let time = periodEndedTimeToday {
                return "Ended in app \(Self.formatPoopLogTime(time))"
            }
            return "Ended in app today"
        }
        if isOnPeriod(on: today), let day = cycleDay(on: today) {
            return "Period · Day \(day)"
        }
        if let predicted = predictedNextStartKey(),
           let date = WidgetDataStore.parseDateKey(predicted) {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            fmt.locale = Locale(identifier: "en_US_POSIX")
            return "Next ~\(fmt.string(from: date))"
        }
        return "Log your cycle"
    }

    private static let mondayWeekdayLabels = ["M", "Tu", "W", "Th", "F", "Sa", "Su"]

    func currentWeekDays() -> [WidgetWeekDay] {
        let todayKey = WidgetDataStore.todayDateKey()
        guard let today = WidgetDataStore.parseDateKey(todayKey) else { return [] }
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }

        let predicted = predictedNextStartKey()
        var result: [WidgetWeekDay] = []
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: monday) else { continue }
            let key = WidgetDataStore.todayDateKey(for: date)
            let onPeriod = isOnPeriod(on: key)
            result.append(
                WidgetWeekDay(
                    dateKey: key,
                    weekdayLabel: Self.mondayWeekdayLabels[offset],
                    dayNumber: calendar.component(.day, from: date),
                    isToday: key == todayKey,
                    onPeriod: onPeriod,
                    isStart: periodEvents.contains { $0.startDate == key },
                    isEnd: periodEvents.contains { $0.endDate == key },
                    isPredicted: predicted == key && !onPeriod
                )
            )
        }
        return result
    }

    func todayDisplayLabel() -> String {
        let todayKey = WidgetDataStore.todayDateKey()
        guard let date = WidgetDataStore.parseDateKey(todayKey) else { return todayKey }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }

    /// Selected Bristol type (1–7) for today, if any.
    func selectedBristolTypeToday() -> Int? {
        guard let log = poopLogsToday.last, log.shape.hasPrefix("type") else { return nil }
        let suffix = log.shape.dropFirst(4)
        guard let n = Int(suffix), (1...7).contains(n) else { return nil }
        return n
    }

    func bristolStatusSubtitle() -> String? {
        guard let log = poopLogsToday.last,
              let typeNumber = selectedBristolTypeToday() else { return nil }
        let label = Self.bristolLabel(forTypeNumber: typeNumber)
        let time = Self.formatPoopLogTime(log.time)
        return "Logged \(label) in app \(time)"
    }

    static func bristolLabel(forTypeNumber type: Int) -> String {
        switch type {
        case 1: return "Hard lumps"
        case 2: return "Lumpy"
        case 3: return "Cracked"
        case 4: return "Smooth"
        case 5: return "Soft blobs"
        case 6: return "Mushy"
        case 7: return "Liquid"
        default: return "Type \(type)"
        }
    }

    /// Converts stored `HH:mm` to e.g. `1:32 PM`.
    static func formatPoopLogTime(_ time24: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "HH:mm"
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: time24) else { return time24 }
        let display = DateFormatter()
        display.dateFormat = "h:mm a"
        display.locale = Locale(identifier: "en_US_POSIX")
        return display.string(from: date)
    }

    var supplementDosesSorted: [WidgetSnapshotSupplementDose] {
        supplementDoses.sorted { a, b in
            let nameA = supplements.first { $0.id == a.supplementId }?.name ?? ""
            let nameB = supplements.first { $0.id == b.supplementId }?.name ?? ""
            if nameA != nameB { return nameA < nameB }
            return a.slot < b.slot
        }
    }

    func supplementName(for dose: WidgetSnapshotSupplementDose) -> String {
        supplements.first { $0.id == dose.supplementId }?.name ?? "Supplement"
    }

    func slotLabel(_ slot: String) -> String {
        switch slot {
        case "morning": return "AM"
        case "noon": return "Noon"
        case "evening": return "PM"
        case "bedtime": return "Bed"
        default: return slot
        }
    }
}
