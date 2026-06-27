import SwiftUI

/// Jackpot winner card shown after a spin — prominent name, details, and action links.
struct WinnerPopupView: View {
    let restaurant: Restaurant
    var onDismiss: () -> Void

    @State private var cardScale: CGFloat = 0.94
    @State private var titleGlow = false

    var body: some View {
        VStack(spacing: 0) {
            jackpotBanner

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    nameHeader
                    detailRows
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)

            actionButtons
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 4)
        }
        .frame(maxWidth: 420)
        .frame(maxHeight: min(720, UIScreen.main.bounds.height * 0.86))
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.navyPanel, Color(red: 0.06, green: 0.08, blue: 0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [AppTheme.goldLight, AppTheme.gold, AppTheme.goldDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
        }
        .shadow(color: AppTheme.gold.opacity(0.3), radius: 14, y: 6)
        .scaleEffect(cardScale)
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                cardScale = 1
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(0.2)) {
                titleGlow = true
            }
        }
    }

    private var jackpotBanner: some View {
        HStack {
            Image(systemName: "laurel.leading")
                .foregroundStyle(AppTheme.gold)
            Text("Winner")
                .font(AppTheme.brandTitleFont(size: 22))
                .tracking(AppTheme.brandTitleTracking)
                .textCase(.uppercase)
                .foregroundStyle(AppTheme.slotTitleGradient)
            Image(systemName: "laurel.trailing")
                .foregroundStyle(AppTheme.gold)
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.gold.opacity(0.85))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 10)
        .background {
            LinearGradient(
                colors: [AppTheme.gold.opacity(0.18), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var nameHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tonight's Pick")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.gold.opacity(0.85))
                .textCase(.uppercase)
                .tracking(0.8)

            Text(restaurant.name)
                .font(.system(size: 32, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.gold)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .shadow(color: AppTheme.gold.opacity(titleGlow ? 0.55 : 0.25), radius: titleGlow ? 14 : 6)

            if let rating = restaurant.rating {
                HStack(spacing: 3) {
                    ForEach(0 ..< 5, id: \.self) { i in
                        Image(systemName: i < Int(rating.rounded()) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(AppTheme.gold)
                    }
                    Text(String(format: "%.1f", rating))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }

            if restaurant.hasPhotos {
                RestaurantPhotoStrip(photoReferences: restaurant.photoReferences)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var detailRows: some View {
        VStack(spacing: 10) {
            detailRow(icon: "mappin.and.ellipse", title: "Address", value: restaurant.address)

            if let price = restaurant.priceLabel {
                detailRow(icon: "dollarsign.circle", title: "Price", value: price)
            }
            if let open = restaurant.isOpenNow {
                detailRow(
                    icon: "clock",
                    title: "Status",
                    value: open ? "Open now" : "Closed",
                    valueColor: open ? AppTheme.gold : AppTheme.closedRed
                )
            }
            if let rating = restaurant.rating {
                detailRow(icon: "star.fill", title: "Rating", value: String(format: "%.1f stars", rating))
            }
        }
    }

    private func detailRow(
        icon: String,
        title: String,
        value: String,
        valueColor: Color = AppTheme.textPrimary
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.gold)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.gold.opacity(0.75))
                    .textCase(.uppercase)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(valueColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.navy.opacity(0.75))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppTheme.gold.opacity(0.2), lineWidth: 0.75)
                }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 10) {
            if restaurant.canOpenInMaps {
                Button {
                    GoogleMapsLinker.open(restaurant: restaurant)
                } label: {
                    Label("Open in Maps", systemImage: "map.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RomanGoldButtonStyle())
            }

            if restaurant.canReserve, let websiteURL = restaurant.websiteURL {
                Link(destination: websiteURL) {
                    Label("Reserve a Table", systemImage: "calendar.badge.plus")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(WinnerGhostButtonStyle())
            }

            Button("Spin Again", action: onDismiss)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
        .padding(.top, 4)
    }
}

private struct WinnerGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AppTheme.gold)
            .padding(.vertical, 12)
            .background {
                Capsule(style: .continuous)
                    .strokeBorder(AppTheme.gold.opacity(0.45), lineWidth: 1)
                    .background(Capsule().fill(AppTheme.navyPanel.opacity(0.6)))
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
