import AppKit
import SwiftUI

// Standalone generator — matches the original CraveSpin icon layout (laurels + stacked serif).
private enum IconColors {
    static let navy = Color(red: 0.05, green: 0.07, blue: 0.12)
    static let gold = Color(red: 0.92, green: 0.76, blue: 0.32)
    static let goldLight = Color(red: 1.0, green: 0.88, blue: 0.55)
    static let goldDark = Color(red: 0.72, green: 0.55, blue: 0.18)
}

private struct AppIconView: View {
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

            RadialGradient(
                colors: [
                    Color.white.opacity(0.14),
                    Color.white.opacity(0.05),
                    Color.clear,
                ],
                center: .center,
                startRadius: 10,
                endRadius: 340
            )

            RoundedRectangle(cornerRadius: 196, style: .continuous)
                .strokeBorder(IconColors.goldLight.opacity(0.82), lineWidth: 3.5)
                .padding(84)

            HStack(spacing: 18) {
                laurelSymbol("laurel.leading")

                VStack(spacing: -6) {
                    iconTitleLine("CRAVE")
                    iconTitleLine("ROLL")
                }

                laurelSymbol("laurel.trailing")
            }
            .padding(.horizontal, 58)
        }
        .frame(width: 1024, height: 1024)
    }

    private func laurelSymbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 118, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [IconColors.goldLight, IconColors.gold, IconColors.goldDark],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: IconColors.gold.opacity(0.28), radius: 6, y: 2)
            .scaleEffect(x: 0.86, y: 1.55)
            .frame(width: 92)
    }

    private func iconTitleLine(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 168, weight: .black, design: .serif))
            .tracking(0)
            .foregroundStyle(IconColors.goldLight)
            .shadow(color: Color.black.opacity(0.65), radius: 0, x: 0, y: 3)
            .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 5)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
    }
}

@main
struct GenerateAppIconCLI {
    static func main() async {
        let output = CommandLine.arguments.count > 1
            ? CommandLine.arguments[1]
            : "\(FileManager.default.currentDirectoryPath)/CraveRoll/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

        do {
            try await writeIcon(to: output)
            print("Wrote app icon to \(output)")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    @MainActor
    private static func writeIcon(to path: String) async throws {
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
}
