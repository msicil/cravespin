import AppKit
import SwiftUI

// Standalone generator — keep colors in sync with AppTheme.
private enum IconColors {
    static let navy = Color(red: 0.05, green: 0.07, blue: 0.12)
    static let navyPanel = Color(red: 0.07, green: 0.09, blue: 0.15)
    static let gold = Color(red: 0.92, green: 0.76, blue: 0.32)
    static let goldLight = Color(red: 1.0, green: 0.88, blue: 0.55)
    static let goldDark = Color(red: 0.72, green: 0.55, blue: 0.18)
    static let textPrimary = Color(red: 0.95, green: 0.90, blue: 0.75)
}

private struct AppIconView: View {
    private let rowHeight: CGFloat = 32
    private let reelWidth: CGFloat = 280

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.10),
                    IconColors.navy,
                    Color(red: 0.06, green: 0.08, blue: 0.14),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 28) {
                BrandIconReel(
                    reelWidth: reelWidth,
                    rowHeight: rowHeight,
                    visibleRows: 2,
                    scrollOffset: -rowHeight
                )
                .shadow(color: IconColors.gold.opacity(0.35), radius: 20, y: 4)

                Text("CraveSpin")
                    .font(.system(size: 216, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [IconColors.goldLight, IconColors.gold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: IconColors.gold.opacity(0.45), radius: 14, y: 5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 1024, height: 1024)
    }
}

/// Static replica of BrandLogoMark for the icon export script (no app module).
private struct BrandIconReel: View {
    static let names = ["Sushi", "Tacos", "Pizza", "Thai", "Grill", "Diner"]

    let reelWidth: CGFloat
    let rowHeight: CGFloat
    let visibleRows: CGFloat
    let scrollOffset: CGFloat

    var body: some View {
        let copies = 3
        let items = (0 ..< Self.names.count * copies).map { Self.names[$0 % Self.names.count] }
        let cycle = rowHeight * CGFloat(Self.names.count)
        let wrapped = scrollOffset.truncatingRemainder(dividingBy: cycle)
        let normalized = wrapped >= 0 ? wrapped - cycle : wrapped
        let viewportHeight = rowHeight * visibleRows
        let panelHeight = viewportHeight + 28
        let innerWidth = reelWidth - 24

        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(IconColors.navyPanel)
                .overlay {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [IconColors.goldLight, IconColors.gold, IconColors.goldDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 5
                        )
                }
                .frame(width: reelWidth, height: panelHeight)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, name in
                    HStack(spacing: 12) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: rowHeight * 0.34, weight: .bold))
                            .foregroundStyle(IconColors.gold)
                        Text(name)
                            .font(.system(size: rowHeight * 0.36, weight: .bold, design: .rounded))
                            .foregroundStyle(IconColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14)
                    .frame(width: innerWidth, height: rowHeight)
                    .background {
                        Rectangle()
                            .fill(
                                (index % Self.names.count).isMultiple(of: 2)
                                    ? Color(red: 0.12, green: 0.14, blue: 0.20)
                                    : Color(red: 0.09, green: 0.11, blue: 0.17)
                            )
                    }
                }
            }
            .offset(y: rowHeight + normalized)
            .frame(width: innerWidth, height: viewportHeight, alignment: .top)
            .clipped()
            .mask {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .frame(width: innerWidth, height: viewportHeight)
            }
        }
    }
}

@MainActor
private func writeIcon(to path: String) async throws {
    let renderer = ImageRenderer(content: AppIconView())
    renderer.scale = 1
    guard let cgImage = renderer.cgImage else {
        throw NSError(domain: "GenerateAppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to render icon"])
    }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "GenerateAppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }
    try data.write(to: URL(fileURLWithPath: path))
}

@main
struct GenerateAppIconCLI {
    static func main() async {
        let output = CommandLine.arguments.count > 1
            ? CommandLine.arguments[1]
            : "\(FileManager.default.currentDirectoryPath)/CraveSpin/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

        do {
            try await writeIcon(to: output)
            print("Wrote app icon to \(output)")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
