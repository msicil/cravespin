import SwiftUI

/// Mini slot reel used on the splash screen and as the basis for the home-screen icon.
struct BrandLogoMark: View {
    static let cuisineNames = ["Sushi", "Tacos", "Pizza", "Thai", "Grill", "Diner"]

    var reelWidth: CGFloat = 280
    var rowHeight: CGFloat = 38
    var visibleRows: CGFloat = 3
    var scrollOffset: CGFloat = 0
    var cornerRadius: CGFloat = 20
    var borderOpacity: Double = 0.5

    private var nameCycleHeight: CGFloat { rowHeight * CGFloat(Self.cuisineNames.count) }

    var body: some View {
        let copies = 3
        let items = (0 ..< Self.cuisineNames.count * copies).map { Self.cuisineNames[$0 % Self.cuisineNames.count] }
        let wrappedOffset = scrollOffset.truncatingRemainder(dividingBy: nameCycleHeight)
        let normalizedOffset = wrappedOffset >= 0 ? wrappedOffset - nameCycleHeight : wrappedOffset
        let viewportHeight = rowHeight * visibleRows
        let panelHeight = viewportHeight + 24
        let innerWidth = reelWidth - 20

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppTheme.navyPanel)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(AppTheme.gold.opacity(borderOpacity), lineWidth: 2)
                }
                .frame(width: reelWidth, height: panelHeight)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, name in
                    reelRow(name: name, stripeIndex: index % Self.cuisineNames.count, innerWidth: innerWidth)
                }
            }
            .offset(y: rowHeight + normalizedOffset)
            .frame(width: innerWidth, alignment: .top)
            .frame(height: viewportHeight, alignment: .top)
            .clipped()
            .mask {
                RoundedRectangle(cornerRadius: cornerRadius - 4, style: .continuous)
                    .frame(width: innerWidth, height: viewportHeight)
            }
        }
    }

    private func reelRow(name: String, stripeIndex: Int, innerWidth: CGFloat) -> some View {
        HStack(spacing: 10) {
            Image(systemName: MealTypeIcon.systemName(forName: name))
                .font(.system(size: max(10, rowHeight * 0.32), weight: .bold))
                .foregroundStyle(AppTheme.gold)
                .frame(width: rowHeight * 0.5, alignment: .center)
            Text(name)
                .font(.system(size: max(11, rowHeight * 0.34), weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .frame(width: innerWidth, height: rowHeight)
        .background {
            Rectangle()
                .fill(
                    stripeIndex.isMultiple(of: 2)
                        ? Color(red: 0.12, green: 0.14, blue: 0.20)
                        : Color(red: 0.09, green: 0.11, blue: 0.17)
                )
        }
    }
}
