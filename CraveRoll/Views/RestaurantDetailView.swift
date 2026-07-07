import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant

    var body: some View {
        GeometryReader { geometry in
            let metrics = CardMetrics(availableHeight: geometry.size.height)

            VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
                header(metrics: metrics)

                fillingDetailGrid(metrics: metrics)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                actionButtons(metrics: metrics)
            }
            .padding(metrics.padding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .background {
                RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                    .fill(AppTheme.navyPanel.opacity(0.9))
                    .overlay {
                        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                            .strokeBorder(AppTheme.gold.opacity(0.45), lineWidth: 1.25)
                    }
            }
        }
    }

    private var detailItems: [DetailItem] {
        var items: [DetailItem] = [
            DetailItem(
                id: "address",
                icon: "mappin.and.ellipse",
                title: "Address",
                value: restaurant.address
            ),
        ]
        if let price = restaurant.priceLabel {
            items.append(DetailItem(id: "price", icon: "dollarsign.circle", title: "Price", value: price))
        }
        if let open = restaurant.isOpenNow {
            items.append(
                DetailItem(
                    id: "status",
                    icon: "clock",
                    title: "Status",
                    value: open ? "Open" : "Closed",
                    valueColor: open ? AppTheme.gold : AppTheme.closedRed
                )
            )
        }
        if let rating = restaurant.rating {
            items.append(
                DetailItem(
                    id: "rating",
                    icon: "star.fill",
                    title: "Rating",
                    value: String(format: "%.1f", rating)
                )
            )
        }
        return items
    }

    private func header(metrics: CardMetrics) -> some View {
        HStack(alignment: .top, spacing: metrics.headerSpacing) {
            ZStack {
                RoundedRectangle(cornerRadius: metrics.iconCornerRadius, style: .continuous)
                    .fill(AppTheme.navyElevated)
                    .frame(width: metrics.iconSize, height: metrics.iconSize)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: metrics.iconSymbolSize))
                    .foregroundStyle(AppTheme.goldGradient)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Tonight's Winner")
                    .font(metrics.winnerLabelFont)
                    .foregroundStyle(AppTheme.gold.opacity(0.85))
                    .textCase(.uppercase)
                    .tracking(0.6)

                Text(restaurant.name)
                    .font(metrics.nameFont)
                    .foregroundStyle(AppTheme.gold)
                    .lineLimit(metrics.nameLineLimit)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let rating = restaurant.rating {
                    HStack(spacing: 2) {
                        ForEach(0 ..< 5, id: \.self) { i in
                            Image(systemName: i < Int(rating.rounded()) ? "star.fill" : "star")
                                .font(metrics.starFont)
                                .foregroundStyle(AppTheme.gold)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func fillingDetailGrid(metrics: CardMetrics) -> some View {
        GeometryReader { gridGeometry in
            let items = detailItems
            let width = gridGeometry.size.width
            let height = gridGeometry.size.height
            let gap = metrics.gridSpacing
            let halfW = (width - gap) / 2
            let halfH = (height - gap) / 2

            Group {
                switch items.count {
                case 0:
                    Color.clear
                case 1:
                    detailCell(items[0], metrics: metrics)
                        .frame(width: width, height: height)
                case 2:
                    VStack(spacing: gap) {
                        detailCell(items[0], metrics: metrics)
                            .frame(width: width, height: halfH)
                        detailCell(items[1], metrics: metrics)
                            .frame(width: width, height: halfH)
                    }
                case 3:
                    VStack(spacing: gap) {
                        HStack(spacing: gap) {
                            detailCell(items[0], metrics: metrics)
                                .frame(width: halfW, height: halfH)
                            detailCell(items[1], metrics: metrics)
                                .frame(width: halfW, height: halfH)
                        }
                        detailCell(items[2], metrics: metrics)
                            .frame(width: width, height: halfH)
                    }
                default:
                    VStack(spacing: gap) {
                        HStack(spacing: gap) {
                            detailCell(items[0], metrics: metrics)
                                .frame(width: halfW, height: halfH)
                            detailCell(items[1], metrics: metrics)
                                .frame(width: halfW, height: halfH)
                        }
                        HStack(spacing: gap) {
                            detailCell(items[2], metrics: metrics)
                                .frame(width: halfW, height: halfH)
                            if items.count > 3 {
                                detailCell(items[3], metrics: metrics)
                                    .frame(width: halfW, height: halfH)
                            } else {
                                Color.clear.frame(width: halfW, height: halfH)
                            }
                        }
                    }
                }
            }
            .frame(width: width, height: height, alignment: .topLeading)
        }
    }

    private func detailCell(_ item: DetailItem, metrics: CardMetrics) -> some View {
        DetailCell(item: item, metrics: metrics)
    }

    @ViewBuilder
    private func actionButtons(metrics: CardMetrics) -> some View {
        if restaurant.canReserve, let websiteURL = restaurant.websiteURL {
            HStack(spacing: metrics.buttonSpacing) {
                if restaurant.canOpenInMaps {
                    mapsButton(metrics: metrics)
                        .buttonStyle(CompactGhostGoldButtonStyle(verticalPadding: metrics.buttonVerticalPadding))
                }

                Link(destination: websiteURL) {
                    Label("Reserve", systemImage: "calendar.badge.plus")
                        .font(metrics.buttonFont)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CompactPrimaryButtonStyle(verticalPadding: metrics.buttonVerticalPadding))
            }
        } else if restaurant.canOpenInMaps {
            mapsButton(metrics: metrics)
                .buttonStyle(CompactPrimaryButtonStyle(verticalPadding: metrics.buttonVerticalPadding))
        }
    }

    private func mapsButton(metrics: CardMetrics) -> some View {
        Button {
            GoogleMapsLinker.open(restaurant: restaurant)
        } label: {
            Label("Maps", systemImage: "map.fill")
                .font(metrics.buttonFont)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct DetailItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = AppTheme.textPrimary
}

private struct CardMetrics {
    let padding: CGFloat
    let sectionSpacing: CGFloat
    let headerSpacing: CGFloat
    let gridSpacing: CGFloat
    let buttonSpacing: CGFloat
    let iconSize: CGFloat
    let iconSymbolSize: CGFloat
    let iconCornerRadius: CGFloat
    let cornerRadius: CGFloat
    let nameLineLimit: Int
    let valueLineLimit: Int
    let winnerLabelFont: Font
    let nameFont: Font
    let starFont: Font
    let buttonFont: Font
    let buttonVerticalPadding: CGFloat
    let cellPadding: CGFloat

    init(availableHeight: CGFloat) {
        switch availableHeight {
        case ..<220:
            padding = 8
            sectionSpacing = 6
            headerSpacing = 8
            gridSpacing = 6
            buttonSpacing = 6
            cellPadding = 6
            iconSize = 40
            iconSymbolSize = 22
            iconCornerRadius = 10
            cornerRadius = 14
            nameLineLimit = 2
            valueLineLimit = 3
            winnerLabelFont = .system(size: 9, weight: .semibold)
            nameFont = .subheadline.weight(.bold)
            starFont = .system(size: 8)
            buttonFont = .caption.weight(.bold)
            buttonVerticalPadding = 7
        case ..<280:
            padding = 10
            sectionSpacing = 8
            headerSpacing = 10
            gridSpacing = 7
            buttonSpacing = 8
            cellPadding = 7
            iconSize = 48
            iconSymbolSize = 26
            iconCornerRadius = 12
            cornerRadius = 16
            nameLineLimit = 2
            valueLineLimit = 4
            winnerLabelFont = .caption2.weight(.semibold)
            nameFont = .headline.weight(.bold)
            starFont = .caption2
            buttonFont = .caption.weight(.bold)
            buttonVerticalPadding = 8
        case ..<340:
            padding = 12
            sectionSpacing = 10
            headerSpacing = 10
            gridSpacing = 8
            buttonSpacing = 8
            cellPadding = 8
            iconSize = 52
            iconSymbolSize = 28
            iconCornerRadius = 12
            cornerRadius = 18
            nameLineLimit = 3
            valueLineLimit = 5
            winnerLabelFont = .caption2.weight(.semibold)
            nameFont = .headline.weight(.bold)
            starFont = .caption2
            buttonFont = .subheadline.weight(.bold)
            buttonVerticalPadding = 9
        default:
            padding = 12
            sectionSpacing = 10
            headerSpacing = 12
            gridSpacing = 10
            buttonSpacing = 10
            cellPadding = 10
            iconSize = 56
            iconSymbolSize = 30
            iconCornerRadius = 14
            cornerRadius = 18
            nameLineLimit = 3
            valueLineLimit = 6
            winnerLabelFont = .caption.weight(.semibold)
            nameFont = .title3.weight(.bold)
            starFont = .caption
            buttonFont = .subheadline.weight(.bold)
            buttonVerticalPadding = 10
        }
    }
}

private struct DetailCell: View {
    let item: DetailItem
    let metrics: CardMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(item.title, systemImage: item.icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.gold.opacity(0.8))

            Text(item.value)
                .font(.caption2)
                .foregroundStyle(item.valueColor)
                .lineLimit(metrics.valueLineLimit)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(metrics.cellPadding)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.navy.opacity(0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(AppTheme.gold.opacity(0.15), lineWidth: 0.5)
                }
        }
    }
}

private struct CompactPrimaryButtonStyle: ButtonStyle {
    var verticalPadding: CGFloat
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AppTheme.navy)
            .padding(.vertical, verticalPadding)
            .background {
                Capsule(style: .continuous)
                    .fill(AppTheme.spinButtonGradient)
                    .opacity(isEnabled ? 1 : 0.45)
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(AppTheme.goldLight.opacity(0.5), lineWidth: 0.75)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct CompactGhostGoldButtonStyle: ButtonStyle {
    var verticalPadding: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AppTheme.gold)
            .padding(.vertical, verticalPadding)
            .background {
                Capsule(style: .continuous)
                    .strokeBorder(AppTheme.gold.opacity(0.45), lineWidth: 1)
                    .background(Capsule().fill(AppTheme.navyPanel.opacity(0.6)))
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
