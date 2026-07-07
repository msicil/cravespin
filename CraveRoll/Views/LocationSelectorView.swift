import SwiftUI

struct LocationSelectorView: View {
    @ObservedObject var location: LocationService
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: location.selectedLocation.isCurrentLocation ? "location.fill" : "mappin.circle.fill")
                    .font(.caption.weight(.bold))

                Text(location.selectedLocation.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                if location.isResolvingCity, location.selectedLocation.isCurrentLocation {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(AppTheme.gold)
                } else {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
            }
            .foregroundStyle(AppTheme.goldLight)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                Capsule(style: .continuous)
                    .fill(AppTheme.navyPanel.opacity(0.95))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(AppTheme.gold.opacity(0.4), lineWidth: 0.85)
                    }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            LocationPickerSheet(location: location) {
                showPicker = false
            }
        }
    }
}

private struct LocationPickerSheet: View {
    @ObservedObject var location: LocationService
    var onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                currentLocationSection

                if location.citySearchQuery.count >= 2 {
                    searchResultsSection
                } else {
                    popularCitiesSection
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.navy)
            .searchable(
                text: $location.citySearchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search for a city"
            )
            .onChange(of: location.citySearchQuery) { _, query in
                location.searchCities(matching: query)
            }
            .navigationTitle("Choose location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                        onDismiss()
                    }
                    .foregroundStyle(AppTheme.gold)
                }
            }
            .toolbarBackground(AppTheme.navyPanel, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var currentLocationSection: some View {
        Section {
            if let gps = location.gpsCoordinate {
                locationRow(
                    SearchLocation.current(title: location.currentCityName, coordinate: gps),
                    isSelected: location.selectedLocation.isCurrentLocation
                )
            } else if location.authorizationStatus == .denied
                || location.authorizationStatus == .restricted {
                Button("Open Settings to enable location") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundStyle(AppTheme.gold)
            } else {
                Button("Use current location") {
                    location.requestAccess()
                    location.refreshLocation()
                }
                .foregroundStyle(AppTheme.gold)
            }
        } header: {
            Text("Your location")
        }
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        Section {
            if location.isSearchingCities {
                HStack {
                    ProgressView()
                        .tint(AppTheme.gold)
                    Text("Searching…")
                        .foregroundStyle(AppTheme.textMuted)
                }
            } else if location.citySearchResults.isEmpty {
                Text("No cities found")
                    .foregroundStyle(AppTheme.textMuted)
            } else {
                ForEach(location.citySearchResults) { city in
                    locationRow(city, isSelected: location.selectedLocation.id == city.id)
                }
            }
        } header: {
            Text("Results")
        }
    }

    @ViewBuilder
    private var popularCitiesSection: some View {
        Section {
            ForEach(SearchLocation.presets) { city in
                locationRow(city, isSelected: location.selectedLocation.id == city.id)
            }
        } header: {
            Text("Popular cities")
        } footer: {
            Text("Type at least 2 characters to search anywhere.")
                .foregroundStyle(AppTheme.textMuted)
        }
    }

    private func locationRow(_ option: SearchLocation, isSelected: Bool) -> some View {
        Button {
            location.select(option)
            dismiss()
            onDismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .foregroundStyle(AppTheme.textPrimary)
                    if option.isCurrentLocation {
                        Text("Based on GPS")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
    }
}
