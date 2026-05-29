import SwiftUI
import WidgetKit

@main
struct BloomWidgetBundle: WidgetBundle {
    var body: some Widget {
        BloomWidget()
    }
}

struct BloomWidget: Widget {
    let kind: String = "BloomWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BloomWidgetProvider()) { entry in
            BloomWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bloom")
        .description("Period, Bristol log, and today's supplements.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
