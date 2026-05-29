import AppIntents
import WidgetKit

struct PeriodStartTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Period started today"

    func perform() async throws -> some IntentResult {
        try WidgetDataStore.setPeriodStartToday()
        return .result()
    }
}

struct PeriodEndTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Period ended today"

    func perform() async throws -> some IntentResult {
        try WidgetDataStore.setPeriodEndToday()
        return .result()
    }
}

struct AddBristolLogIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Bristol type"

    /// 1–7; integers encode reliably from widget buttons (string params often arrive empty).
    @Parameter(title: "Type")
    var typeNumber: Int

    init() {
        typeNumber = 4
    }

    init(typeNumber: Int) {
        self.typeNumber = typeNumber
    }

    func perform() async throws -> some IntentResult {
        guard (1...7).contains(typeNumber) else { return .result() }
        try WidgetDataStore.addBristolLog(shape: "type\(typeNumber)")
        return .result()
    }
}

struct ToggleSupplementIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle checklist item"

    /// Index into [WidgetSnapshot.supplementDosesSorted] (integers encode reliably from widget buttons).
    @Parameter(title: "Dose")
    var doseIndex: Int

    init() {
        doseIndex = 0
    }

    init(doseIndex: Int) {
        self.doseIndex = doseIndex
    }

    func perform() async throws -> some IntentResult {
        try WidgetDataStore.toggleSupplement(atSortedIndex: doseIndex)
        return .result()
    }
}

struct OpenBloomIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Bloom"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
