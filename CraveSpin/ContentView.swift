import SwiftUI

struct ContentView: View {
    @StateObject private var location = LocationService()
    @StateObject private var viewModel = RouletteViewModel()
    @State private var filtersChangedWhileSpinning = false
    @State private var filtersExpanded = false
    @State private var collapsedStageHeight: CGFloat = 520
    @State private var isWheelReady = false
    @State private var widgetSpinTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            let safeBottom = geometry.safeAreaInsets.bottom
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                RomanStageBackground()
                    .ignoresSafeArea()

                mainContent(safeBottom: safeBottom)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, max(8, safeBottom))
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)

                if viewModel.showWinnerPopup, let winner = viewModel.selectedRestaurant {
                    JackpotWinnerOverlay(restaurant: winner) {
                        viewModel.dismissWinner()
                    }
                    .zIndex(10)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AppTheme.gold)
        .onAppear {
            viewModel.configureLivePlacesIfAvailable()
            location.requestAccess()
            SlotSounds.prepare()
        }
        .onChange(of: location.searchCoordinate) { _, coordinate in
            guard let coordinate else { return }
            guard !viewModel.isSpinning else { return }
            Task { await viewModel.loadRestaurants(near: coordinate) }
        }
        .onChange(of: viewModel.filters.radiusMeters) { _, _ in
            reloadRestaurantsFromFilters()
        }
        .onChange(of: viewModel.filters.openNowOnly) { _, _ in
            reloadRestaurantsFromFilters()
        }
        .onChange(of: viewModel.filters.minRating) { _, _ in
            reloadRestaurantsFromFilters()
        }
        .onChange(of: viewModel.filters.selectedPriceLevels) { _, _ in
            reloadRestaurantsFromFilters()
        }
        .onChange(of: viewModel.isSpinning) { _, isSpinning in
            if !isSpinning, filtersChangedWhileSpinning {
                filtersChangedWhileSpinning = false
                reloadRestaurants()
            }
            if !isSpinning {
                handleWidgetSpinRequest()
            }
        }
        #if DEBUG
        .task { await runDebugSpinSimulationIfRequested() }
        #endif
        .onAppear { handleWidgetSpinRequest() }
        .onReceive(NotificationCenter.default.publisher(for: .widgetSpinRequested)) { _ in
            handleWidgetSpinRequest()
        }
        .onChange(of: viewModel.restaurants.map(\.id)) { _, _ in
            isWheelReady = false
            if !viewModel.isLoading, viewModel.restaurants.count >= 2 {
                markWheelReady()
            } else {
                scheduleWidgetSpinIfReady()
            }
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            if isLoading {
                isWheelReady = false
                widgetSpinTask?.cancel()
            } else if viewModel.restaurants.count >= 2 {
                markWheelReady()
            } else {
                scheduleWidgetSpinIfReady()
            }
        }
        .onChange(of: location.isInitialLocationReady) { _, _ in
            scheduleWidgetSpinIfReady()
        }
        .onDisappear {
            widgetSpinTask?.cancel()
        }
    }

    private func handleWidgetSpinRequest() {
        guard WidgetSpinRequest.isPending else { return }
        guard location.isInitialLocationReady else { return }

        if viewModel.isSpinning {
            return
        }

        if viewModel.restaurants.count >= 2, !viewModel.isLoading {
            isWheelReady = true
            if viewModel.showWinnerPopup {
                viewModel.dismissWinner()
            }
            performWidgetSpin(immediate: true)
            return
        }

        scheduleWidgetSpinIfReady()
    }

    private func markWheelReady() {
        guard viewModel.restaurants.count >= 2, !viewModel.isLoading else { return }

        Task { @MainActor in
            // Let the reel finish its first layout pass before spinning.
            try? await Task.sleep(for: .milliseconds(120))
            guard viewModel.restaurants.count >= 2, !viewModel.isLoading else { return }
            isWheelReady = true
            scheduleWidgetSpinIfReady()
        }
    }

    private func scheduleWidgetSpinIfReady() {
        guard WidgetSpinRequest.isPending else { return }
        guard viewModel.restaurants.count >= 2,
              !viewModel.isSpinning,
              !viewModel.isLoading,
              isWheelReady,
              location.isInitialLocationReady else { return }

        performWidgetSpin(immediate: false)
    }

    private func performWidgetSpin(immediate: Bool) {
        guard WidgetSpinRequest.isPending else { return }
        guard viewModel.restaurants.count >= 2,
              !viewModel.isSpinning,
              !viewModel.isLoading,
              location.isInitialLocationReady else { return }

        if !immediate {
            guard isWheelReady else { return }
        }

        widgetSpinTask?.cancel()
        widgetSpinTask = Task { @MainActor in
            if !immediate {
                try? await Task.sleep(for: .milliseconds(150))
            }
            guard !Task.isCancelled else { return }
            guard WidgetSpinRequest.isPending,
                  viewModel.restaurants.count >= 2,
                  !viewModel.isSpinning,
                  !viewModel.isLoading,
                  location.isInitialLocationReady else { return }

            WidgetSpinRequest.clear()
            viewModel.spin(pullStrength: .full)
        }
    }

    #if DEBUG
    private func runDebugSpinSimulationIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains("-simulateFullPullSpin") else { return }
        try? await Task.sleep(for: .seconds(3))
        for _ in 0 ..< 40 {
            if viewModel.restaurants.count >= 2 { break }
            try? await Task.sleep(for: .milliseconds(150))
        }
        guard viewModel.restaurants.count >= 2, !viewModel.isSpinning else { return }
        try? await Task.sleep(for: .milliseconds(300))
        viewModel.spin(pullStrength: .full)
    }
    #endif

    // MARK: - Main layout

    private func mainContent(safeBottom: CGFloat) -> some View {
        VStack(spacing: 10) {
            if viewModel.isLoading, viewModel.restaurants.count < 2 {
                borderedCabinet {
                    ProgressView("Finding restaurants…")
                        .tint(AppTheme.gold)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                playArea(safeBottom: safeBottom)
            }

            errorSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private static let stageControlsInset: CGFloat = 24
    private static let laurelBandHeight: CGFloat = 92
    private static let stageAnimation = Animation.easeInOut(duration: 0.44)

    private func playArea(safeBottom: CGFloat) -> some View {
        GeometryReader { geo in
            let topInset = filtersExpanded
                ? 0
                : max(0, (geo.size.height - collapsedStageHeight) / 2)

            VStack(spacing: 0) {
                Color.clear
                    .frame(height: topInset)

                stageColumn

                cabinetDivider
                    .opacity(filtersExpanded ? 1 : 0)
                    .frame(height: filtersExpanded ? 1 : 0)
                    .clipped()

                expandedFiltersPanel(safeBottom: safeBottom)
                    .frame(maxHeight: filtersExpanded ? .infinity : 0, alignment: .top)
                    .opacity(filtersExpanded ? 1 : 0)
                    .clipped()
                    .allowsHitTesting(filtersExpanded)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .background {
            cabinetChrome()
                .clipShape(cabinetBorderShape())
                .opacity(filtersExpanded ? 1 : 0)
        }
        .overlay {
            cabinetBorderShape()
                .strokeBorder(AppTheme.gold.opacity(filtersExpanded ? 0.4 : 0), lineWidth: 1.25)
                .allowsHitTesting(false)
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(filtersExpanded ? 0.35 : 0.25)
                    ProgressView("Updating…")
                        .tint(AppTheme.gold)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .allowsHitTesting(false)
            }
        }
        .shadow(color: .black.opacity(filtersExpanded ? 0.4 : 0), radius: 14, y: 6)
        .onPreferenceChange(StageColumnHeightKey.self) { height in
            guard height > 0, !filtersExpanded else { return }
            collapsedStageHeight = height
        }
    }

    private var stageColumn: some View {
        VStack(spacing: 10) {
            StageLaurelArch(placement: .top)
                .opacity(filtersExpanded ? 0 : 1)
                .frame(height: filtersExpanded ? 0 : Self.laurelBandHeight)
                .clipped()
                .allowsHitTesting(false)

            stageTagline
            stageContent
            spinSection
            filtersDropdown

            StageLaurelArch(placement: .bottom)
                .opacity(filtersExpanded ? 0 : 1)
                .frame(height: filtersExpanded ? 0 : Self.laurelBandHeight)
                .clipped()
                .allowsHitTesting(false)
        }
        .padding(.vertical, filtersExpanded ? 0 : 8)
        .padding(.top, filtersExpanded ? 10 : 0)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: StageColumnHeightKey.self, value: proxy.size.height)
            }
        }
    }

    private var stageTagline: some View {
        Text("Find a meal in one spin")
            .font(.system(.subheadline, design: .serif).weight(.semibold))
            .foregroundStyle(AppTheme.goldLight.opacity(0.92))
            .tracking(0.6)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
    }

    @ViewBuilder
    private var stageContent: some View {
        if viewModel.restaurants.count >= 2 {
            SlotMachineView(
                restaurants: viewModel.restaurants,
                colors: viewModel.segmentColors(count: viewModel.restaurants.count),
                scrollOffset: viewModel.wheelScrollOffset,
                isSpinning: viewModel.isSpinning,
                jackpotFlash: viewModel.jackpotFlash,
                onSpin: { viewModel.spin(pullStrength: $0) }
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            .onAppear { markWheelReady() }
        } else {
            noResultsNotice
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: WheelLayout.viewportHeight, alignment: .center)
        }
    }

    @ViewBuilder
    private var spinSection: some View {
        if viewModel.restaurants.count >= 2 {
            Button {
                viewModel.spin(pullStrength: .full)
            } label: {
                Label(
                    viewModel.isSpinning ? "Spinning…" : "Spin",
                    systemImage: viewModel.isSpinning ? "bolt.fill" : "sparkles"
                )
            }
            .buttonStyle(SlotSpinButtonStyle(isSpinning: viewModel.isSpinning))
            .disabled(viewModel.isSpinning)
            .padding(.horizontal, Self.stageControlsInset)
            .padding(.vertical, 4)
        } else {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(AppTheme.gold)
                Text("Open filters to find more restaurants")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    private var filtersDropdown: some View {
        Button {
            withAnimation(Self.stageAnimation) {
                filtersExpanded.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "laurel.leading")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.gold.opacity(0.75))
                Text("Filters")
                    .font(.system(.subheadline, design: .serif).weight(.bold))
                    .foregroundStyle(AppTheme.goldLight)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.gold.opacity(0.85))
                    .rotationEffect(.degrees(filtersExpanded ? 180 : 0))
                Image(systemName: "laurel.trailing")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.gold.opacity(0.75))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: WheelChrome.cornerRadius, style: .continuous)
                    .fill(WheelChrome.fillGradient)
            }
            .overlay {
                RoundedRectangle(cornerRadius: WheelChrome.cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [AppTheme.goldLight, AppTheme.gold, AppTheme.goldDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.75
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: WheelChrome.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Self.stageControlsInset)
    }

    private func expandedFiltersPanel(safeBottom: CGFloat) -> some View {
        ZStack(alignment: .top) {
            AppTheme.navyElevated.opacity(0.5)

            FilterBarView(filters: $viewModel.filters, expanded: true)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, max(8, safeBottom))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .layoutPriority(1)
    }

    private var cabinetDivider: some View {
        Rectangle()
            .fill(AppTheme.gold.opacity(0.18))
            .frame(height: 1)
    }

    private func borderedCabinet<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                GeometryReader { proxy in
                    cabinetChrome()
                        .clipShape(cabinetBorderShape())
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .overlay {
                GeometryReader { proxy in
                    cabinetBorderShape()
                        .strokeBorder(AppTheme.gold.opacity(0.4), lineWidth: 1.25)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
    }

    private func cabinetChrome() -> some View {
        cabinetBorderShape()
            .fill(
                LinearGradient(
                    colors: [AppTheme.navyPanel, Color(red: 0.05, green: 0.06, blue: 0.11)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private func cabinetBorderShape() -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 20,
            bottomLeadingRadius: 20,
            bottomTrailingRadius: 20,
            topTrailingRadius: 20,
            style: .continuous
        )
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .font(.footnote)
                .foregroundStyle(AppTheme.closedRed.opacity(0.95))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .glassCard(cornerRadius: 14)
        }
    }

    private var noResultsNotice: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.gold.opacity(0.9))
            Text("No restaurants match these filters")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Try widening distance or lowering rating.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    private func reloadRestaurantsFromFilters() {
        if viewModel.isSpinning {
            filtersChangedWhileSpinning = true
            return
        }
        reloadRestaurants()
    }

    private func reloadRestaurants() {
        guard let coordinate = location.searchCoordinate else {
            location.refreshLocation()
            return
        }
        Task { await viewModel.loadRestaurants(near: coordinate) }
    }
}

private struct StageColumnHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    ContentView()
}
