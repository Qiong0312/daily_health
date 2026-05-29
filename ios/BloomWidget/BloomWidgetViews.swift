import SwiftUI
import WidgetKit

private enum BloomWidgetTheme {
    static let rose800 = Color(red: 0.51, green: 0.09, blue: 0.26)
    static let rose700 = Color(red: 0.75, green: 0.09, blue: 0.36)
    static let rose600 = Color(red: 0.86, green: 0.15, blue: 0.47)
    static let rose500 = Color(red: 0.93, green: 0.28, blue: 0.60)
    static let rose300 = Color(red: 0.98, green: 0.66, blue: 0.83)
    static let rose100 = Color(red: 0.99, green: 0.91, blue: 0.96)
}

/// Large widget: week-day, Bristol, and supplement rows share the same cell height.
private enum BloomWidgetMetrics {
    static let largeCellMinHeight: CGFloat = 40
    static let largeCellVPadding: CGFloat = 6
    static let largeCellCornerRadius: CGFloat = 6
    static let largeBodyFontSize: CGFloat = 13
}

struct BloomWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BloomWidgetEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                switch family {
                case .systemSmall:
                    BloomSmallView(snapshot: snapshot)
                case .systemMedium:
                    BloomMediumView(snapshot: snapshot)
                default:
                    BloomLargeView(snapshot: snapshot)
                }
            } else {
                emptyState
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.95, blue: 0.97),
                    Color(red: 0.98, green: 0.97, blue: 1),
                    Color(red: 1, green: 0.97, blue: 0.93),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var emptyState: some View {
        Text("Open the app once to sync")
            .font(.caption2)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding()
    }
}

// MARK: - Small

struct BloomSmallView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            PeriodWeekCalendarView(snapshot: snapshot, compact: true)
            SupplementGridView(
                snapshot: snapshot,
                // Single column; maxRows controls how many appear.
                columns: 1,
                maxRows: 2,
                compact: true
            )
        }
        .padding(10)
    }
}

// MARK: - Medium

struct BloomMediumView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            PeriodWeekCalendarView(snapshot: snapshot, compact: true)
            BristolRowView(snapshot: snapshot, compact: true)
            SupplementGridView(
                snapshot: snapshot,
                columns: 2,
                maxRows: 1,
                compact: true
            )
        }
        .padding(10)
    }
}

// MARK: - Large

struct BloomLargeView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PeriodWeekCalendarView(snapshot: snapshot, compact: false)
            BristolRowView(snapshot: snapshot, compact: false)
            SupplementGridView(
                snapshot: snapshot,
                columns: 2,
                maxRows: 3,
                compact: false
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

// MARK: - Sections

struct PeriodWeekCalendarView: View {
    let snapshot: WidgetSnapshot
    let compact: Bool

    private var weekDays: [WidgetWeekDay] { snapshot.currentWeekDays() }
    private let openAppURL = URL(string: "bloom://today")

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 6) {
            HStack {
                Text("Period")
                    .font(.system(size: compact ? 11 : 13, weight: .heavy))
                    .foregroundStyle(BloomWidgetTheme.rose800)
                Spacer()
                Text(snapshot.todayDisplayLabel())
                    .font(.system(size: compact ? 9 : 11, weight: .semibold))
                    .foregroundStyle(BloomWidgetTheme.rose700)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            calendarStrip
            periodActionButton
        }
    }

    @ViewBuilder
    private var calendarStrip: some View {
        if let url = openAppURL {
            Link(destination: url) {
                HStack(spacing: compact ? 2 : 3) {
                    ForEach(weekDays) { day in
                        WeekDayCellContent(day: day, compact: compact)
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            HStack(spacing: compact ? 2 : 3) {
                ForEach(weekDays) { day in
                    WeekDayCellContent(day: day, compact: compact)
                }
            }
        }
    }

    @ViewBuilder
    private var periodActionButton: some View {
        // Only show Start/End controls on the large widget.
        if !compact {
            if snapshot.shouldShowStartPeriodButton() {
                Button(intent: PeriodStartTodayIntent()) {
                    Text("Start period today")
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(BloomWidgetTheme.rose500)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            } else if snapshot.shouldShowEndPeriodButton() {
                Button(intent: PeriodEndTodayIntent()) {
                    Text("End period today")
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(BloomWidgetTheme.rose100)
                        .foregroundStyle(BloomWidgetTheme.rose800)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(BloomWidgetTheme.rose300, lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct WeekDayCellContent: View {
    let day: WidgetWeekDay
    let compact: Bool

    var body: some View {
        VStack(spacing: compact ? 1 : 2) {
            Text(day.weekdayLabel)
                .font(.system(size: compact ? 7 : 8, weight: .bold))
                .foregroundStyle(BloomWidgetTheme.rose700)
            Text("\(day.dayNumber)")
                .font(.system(size: compact ? 10 : 13, weight: day.isToday ? .heavy : .semibold))
                .foregroundStyle(day.isToday ? BloomWidgetTheme.rose800 : BloomWidgetTheme.rose800.opacity(0.85))
            if let marker = day.marker {
                Text(marker)
                    .font(.system(size: compact ? 6 : 7, weight: .heavy))
                    .foregroundStyle(BloomWidgetTheme.rose600)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 3 : BloomWidgetMetrics.largeCellVPadding)
        .frame(minHeight: compact ? nil : BloomWidgetMetrics.largeCellMinHeight)
        .background(cellBackground)
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 6 : BloomWidgetMetrics.largeCellCornerRadius)
                .stroke(cellBorder, lineWidth: day.isToday ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: compact ? 6 : BloomWidgetMetrics.largeCellCornerRadius))
    }

    private var cellBackground: Color {
        if day.onPeriod { return BloomWidgetTheme.rose300.opacity(0.38) }
        if day.isPredicted { return BloomWidgetTheme.rose100.opacity(0.95) }
        if day.isToday { return BloomWidgetTheme.rose100.opacity(0.9) }
        return Color.white.opacity(0.55)
    }

    private var cellBorder: Color {
        if day.isToday { return BloomWidgetTheme.rose500 }
        if day.onPeriod { return BloomWidgetTheme.rose300.opacity(0.7) }
        if day.isPredicted { return BloomWidgetTheme.rose300.opacity(0.5) }
        return BloomWidgetTheme.rose100
    }
}

struct BristolRowView: View {
    let snapshot: WidgetSnapshot
    let compact: Bool

    private var selectedType: Int? { snapshot.selectedBristolTypeToday() }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Bristol")
                    .font(.system(size: compact ? 10 : 11, weight: .heavy))
                    .foregroundStyle(BloomWidgetTheme.rose800)
                Spacer(minLength: 4)
                if let subtitle = snapshot.bristolStatusSubtitle() {
                    Text(subtitle)
                        .font(.system(size: compact ? 8 : 9, weight: .semibold))
                        .foregroundStyle(BloomWidgetTheme.rose600)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            HStack(spacing: compact ? 2 : 3) {
                ForEach(1...7, id: \.self) { n in
                    BristolTypeButton(
                        typeNumber: n,
                        isSelected: selectedType == n,
                        compact: compact
                    )
                }
            }
        }
    }
}

struct BristolTypeButton: View {
    let typeNumber: Int
    let isSelected: Bool
    let compact: Bool

    var body: some View {
        Button(intent: AddBristolLogIntent(typeNumber: typeNumber)) {
            Text("\(typeNumber)")
                .font(.system(size: compact ? 11 : BloomWidgetMetrics.largeBodyFontSize, weight: .heavy))
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 6 : BloomWidgetMetrics.largeCellVPadding)
                .frame(minHeight: compact ? nil : BloomWidgetMetrics.largeCellMinHeight)
                .background(isSelected ? BloomWidgetTheme.rose500 : Color.white.opacity(0.9))
                .foregroundStyle(isSelected ? Color.white : BloomWidgetTheme.rose800)
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 6 : BloomWidgetMetrics.largeCellCornerRadius)
                        .stroke(
                            isSelected ? BloomWidgetTheme.rose700 : BloomWidgetTheme.rose300.opacity(0.6),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: compact ? 6 : BloomWidgetMetrics.largeCellCornerRadius))
        }
        .buttonStyle(.plain)
    }
}

struct SupplementGridView: View {
    let snapshot: WidgetSnapshot
    let columns: Int
    let maxRows: Int
    let compact: Bool

    private var maxVisible: Int { columns * maxRows }

    private var allDoses: [WidgetSnapshotSupplementDose] {
        snapshot.supplementDosesSorted
    }

    private var visibleDoses: [WidgetSnapshotSupplementDose] {
        Array(allDoses.prefix(maxVisible))
    }

    private var moreCount: Int {
        max(0, allDoses.count - maxVisible)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 6) {
            Text("Checklist")
                .font(.system(size: compact ? 10 : 11, weight: .heavy))
                .foregroundStyle(BloomWidgetTheme.rose800)

            if allDoses.isEmpty {
                Text("None enabled")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            } else {
                let rowCount = (visibleDoses.count + columns - 1) / columns
                ForEach(0..<rowCount, id: \.self) { row in
                    let start = row * columns
                    let countInRow = min(columns, visibleDoses.count - start)
                    HStack(spacing: compact ? 4 : 5) {
                        ForEach(0..<countInRow, id: \.self) { col in
                            let doseIndex = start + col
                            SupplementDoseCell(
                                snapshot: snapshot,
                                doseIndex: doseIndex,
                                compact: compact
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                if moreCount > 0 {
                    Text("\(moreCount) more in app")
                        .font(.system(size: compact ? 8 : 9, weight: .semibold))
                        .foregroundStyle(BloomWidgetTheme.rose700)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

struct SupplementDoseCell: View {
    let snapshot: WidgetSnapshot
    /// Index in `snapshot.supplementDosesSorted` (visible grid uses prefix indices).
    let doseIndex: Int
    let compact: Bool

    private var dose: WidgetSnapshotSupplementDose {
        snapshot.supplementDosesSorted[doseIndex]
    }

    var body: some View {
        Button(intent: ToggleSupplementIntent(doseIndex: doseIndex)) {
            HStack(spacing: compact ? 4 : 6) {
                Image(systemName: dose.taken ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: compact ? 13 : BloomWidgetMetrics.largeBodyFontSize))
                    .foregroundStyle(
                        dose.taken ? BloomWidgetTheme.rose600 : BloomWidgetTheme.rose300
                    )
                Text(snapshot.supplementName(for: dose))
                    .font(.system(size: compact ? 10 : BloomWidgetMetrics.largeBodyFontSize, weight: .semibold))
                    .foregroundStyle(BloomWidgetTheme.rose800)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 6 : BloomWidgetMetrics.largeCellVPadding)
            .frame(minHeight: compact ? nil : BloomWidgetMetrics.largeCellMinHeight)
            .background(
                dose.taken
                    ? BloomWidgetTheme.rose100
                    : Color.white.opacity(0.85)
            )
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 8 : BloomWidgetMetrics.largeCellCornerRadius)
                    .stroke(
                        dose.taken ? BloomWidgetTheme.rose500 : BloomWidgetTheme.rose100,
                        lineWidth: 1.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: compact ? 8 : BloomWidgetMetrics.largeCellCornerRadius))
        }
        .buttonStyle(.plain)
    }
}
