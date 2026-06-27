import SwiftUI
import WidgetKit

private enum WidgetColors {
    static let navy = Color(red: 0.05, green: 0.07, blue: 0.12)
    static let navyPanel = Color(red: 0.07, green: 0.09, blue: 0.15)
    static let gold = Color(red: 0.92, green: 0.76, blue: 0.32)
    static let goldLight = Color(red: 1.0, green: 0.88, blue: 0.55)
    static let goldDark = Color(red: 0.72, green: 0.55, blue: 0.18)
}

private struct SpinWidgetEntry: TimelineEntry {
    let date: Date
}

private struct SpinWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpinWidgetEntry {
        SpinWidgetEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (SpinWidgetEntry) -> Void) {
        completion(SpinWidgetEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpinWidgetEntry>) -> Void) {
        let entry = SpinWidgetEntry(date: .now)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

private struct SpinWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(spacing: family == .systemMedium ? 10 : 8) {
            tagline
            spinMark
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .widgetURL(URL(string: "cravespin://spin")!)
    }

    private var tagline: some View {
        Text("Find a restaurant")
            .font(.system(family == .systemMedium ? .body : .caption, design: .serif).weight(.semibold))
            .foregroundStyle(WidgetColors.goldLight.opacity(0.92))
            .tracking(0.4)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.85)
            .lineLimit(family == .systemMedium ? 2 : 3)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var spinMark: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(family == .systemMedium ? .title.weight(.bold) : .title2.weight(.bold))
                .foregroundStyle(WidgetColors.goldLight)

            Text("Spin")
                .font(.system(.subheadline, design: .serif).weight(.black))
                .tracking(1.1)
                .textCase(.uppercase)
                .foregroundStyle(
                    LinearGradient(
                        colors: [WidgetColors.goldLight, WidgetColors.gold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}

struct SpinWidget: Widget {
    let kind = "SpinWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpinWidgetProvider()) { _ in
            SpinWidgetView()
                .containerBackground(for: .widget) {
                    ZStack {
                        ContainerRelativeShape()
                            .fill(
                                LinearGradient(
                                    colors: [WidgetColors.navyPanel, WidgetColors.navy],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        ContainerRelativeShape()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [WidgetColors.goldLight, WidgetColors.gold, WidgetColors.goldDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                }
        }
        .configurationDisplayName("Spin")
        .description("Open CraveSpin and spin for a restaurant.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct CraveSpinWidgetBundle: WidgetBundle {
    var body: some Widget {
        SpinWidget()
    }
}
