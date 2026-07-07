import SwiftUI

struct FilterBarView: View {
    @Binding var filters: SpinFilters
    var expanded: Bool = false

    private static let expandedRowSpacing: CGFloat = 16
    private static let compactRowSpacing: CGFloat = 8
    private static let expandedControlPadding = EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)

    var body: some View {
        if expanded {
            expandedBody
        } else {
            compactBody
        }
    }

    private var expandedBody: some View {
        GeometryReader { geometry in
            let rowHeight = expandedRowHeight(in: geometry.size.height)

            VStack(alignment: .leading, spacing: Self.expandedRowSpacing) {
                expandedField(label: "Open Now", rowHeight: rowHeight) {
                    Toggle(isOn: $filters.openNowOnly) {
                        Text(filters.openNowOnly ? "On" : "Off")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .tint(AppTheme.gold)
                }

                expandedField(label: "Distance", rowHeight: rowHeight) {
                    Picker("Radius", selection: $filters.radiusMeters) {
                        ForEach(SpinFilters.radiusOptions, id: \.self) { meters in
                            Text(radiusLabel(for: meters))
                                .font(.subheadline.weight(.semibold))
                                .tag(meters)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                expandedField(label: "Price", rowHeight: rowHeight) {
                    PriceLevelButtons(selectedLevels: $filters.selectedPriceLevels, compact: false)
                }

                expandedField(label: "Min. Rating", rowHeight: rowHeight) {
                    HStack(spacing: 8) {
                        Slider(value: $filters.minRating, in: 0 ... SpinFilters.maxMinRating, step: 0.5)
                            .tint(AppTheme.gold)
                        Text(filters.minRating > 0 ? String(format: "%.1f+", filters.minRating) : "Any")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.gold)
                            .frame(width: 40)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: Self.compactRowSpacing) {
            compactField(label: "Open Now") {
                Toggle(isOn: $filters.openNowOnly) {
                    Text(filters.openNowOnly ? "On" : "Off")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .tint(AppTheme.gold)
            }

            compactField(label: "Distance") {
                Picker("Radius", selection: $filters.radiusMeters) {
                    ForEach(SpinFilters.radiusOptions, id: \.self) { meters in
                        Text(radiusLabel(for: meters))
                            .font(.caption2.weight(.semibold))
                            .tag(meters)
                    }
                }
                .pickerStyle(.segmented)
            }

            compactField(label: "Price") {
                PriceLevelButtons(selectedLevels: $filters.selectedPriceLevels, compact: true)
            }

            compactField(label: "Min. Rating") {
                HStack(spacing: 4) {
                    Slider(value: $filters.minRating, in: 0 ... SpinFilters.maxMinRating, step: 0.5)
                        .tint(AppTheme.gold)
                        .controlSize(.small)
                    Text(filters.minRating > 0 ? String(format: "%.1f+", filters.minRating) : "Any")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.gold)
                        .frame(width: 32)
                }
            }

        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func expandedRowHeight(in availableHeight: CGFloat) -> CGFloat {
        let gapTotal = Self.expandedRowSpacing * 3
        let fitted = (availableHeight - gapTotal) / 4
        return max(58, min(70, fitted))
    }

    @ViewBuilder
    private func expandedField<Content: View>(
        label: String,
        rowHeight: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.gold.opacity(0.85))
                .textCase(.uppercase)
                .tracking(0.7)

            content()
                .padding(Self.expandedControlPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.navyPanel.opacity(0.7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(AppTheme.gold.opacity(0.22), lineWidth: 0.75)
                        }
                }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(height: rowHeight, alignment: .top)
    }

    private func compactField<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.gold.opacity(0.85))
                .textCase(.uppercase)
                .tracking(0.6)

            content()
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.navyPanel.opacity(0.7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(AppTheme.gold.opacity(0.22), lineWidth: 0.75)
                        }
                }
        }
    }

    private func radiusLabel(for meters: Int) -> String {
        let miles = Double(meters) / 1_609.34
        if miles >= 10 { return String(format: "%.0f mi", miles) }
        if miles >= 1 {
            return abs(miles - miles.rounded()) < 0.15
                ? String(format: "%.0f mi", miles.rounded())
                : String(format: "%.1f mi", miles)
        }
        return String(format: "%.1f mi", miles)
    }
}
