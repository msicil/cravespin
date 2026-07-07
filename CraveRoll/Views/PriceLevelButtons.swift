import SwiftUI

/// Segmented-style $ buttons; tap to toggle one or more price levels.
struct PriceLevelButtons: View {
    @Binding var selectedLevels: Set<Int>
    var compact: Bool = false

    private var allLevels: Set<Int> {
        Set(SpinFilters.priceLevels)
    }

    private var treatsAsAnyPrice: Bool {
        selectedLevels.isEmpty || selectedLevels == allLevels
    }

    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            ForEach(SpinFilters.priceLevels, id: \.self) { level in
                priceButton(level: level)
            }
        }
    }

    private func priceButton(level: Int) -> some View {
        let isSelected = treatsAsAnyPrice || selectedLevels.contains(level)

        return Button {
            toggle(level)
        } label: {
            Text(SpinFilters.priceLevelLabel(level))
                .font(compact ? .caption.weight(.bold) : .subheadline.weight(.bold))
                .foregroundStyle(isSelected ? AppTheme.navy : AppTheme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 6 : 8)
                .background {
                    RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous)
                        .fill(isSelected ? AppTheme.gold : AppTheme.navy.opacity(0.55))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous)
                        .strokeBorder(AppTheme.gold.opacity(isSelected ? 0.9 : 0.35), lineWidth: 0.75)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(SpinFilters.priceLevelLabel(level))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func toggle(_ level: Int) {
        if treatsAsAnyPrice {
            selectedLevels = allLevels.subtracting([level])
            return
        }
        if selectedLevels.contains(level) {
            selectedLevels.remove(level)
        } else {
            var next = selectedLevels
            next.insert(level)
            selectedLevels = next == allLevels ? allLevels : next
        }
    }
}
