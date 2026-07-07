import SwiftUI

struct RestaurantPhotoStrip: View {
    let photoReferences: [String]
    var thumbnailSize: CGFloat = 112
    var maxDimension: Int = 480

    @State private var expandedPhoto: ExpandedPhoto?

    var body: some View {
        if !photoReferences.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Photos")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.gold.opacity(0.75))
                    .textCase(.uppercase)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(photoReferences, id: \.self) { reference in
                            Button {
                                expandedPhoto = ExpandedPhoto(name: reference)
                            } label: {
                                GooglePlacesPhotoImage(
                                    photoName: reference,
                                    maxDimension: maxDimension
                                )
                                .frame(width: thumbnailSize, height: thumbnailSize)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(AppTheme.gold.opacity(0.35), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .fullScreenCover(item: $expandedPhoto) { photo in
                RestaurantPhotoDetailView(
                    photoName: photo.name,
                    onDismiss: { expandedPhoto = nil }
                )
            }
        }
    }
}

private struct ExpandedPhoto: Identifiable {
    let id: String
    let name: String

    init(name: String) {
        self.id = name
        self.name = name
    }
}

struct GooglePlacesPhotoImage: View {
    let photoName: String
    var maxDimension: Int = 480

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppTheme.navyElevated
                    ProgressView()
                        .tint(AppTheme.gold)
                }
            }
        }
        .task(id: "\(photoName)-\(maxDimension)") {
            image = await GooglePlacesPhotoService.image(for: photoName, maxDimension: maxDimension)
        }
    }
}

private struct RestaurantPhotoDetailView: View {
    let photoName: String
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GooglePlacesPhotoImage(photoName: photoName, maxDimension: 1200)
                .scaledToFit()
                .padding(20)

            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.gold.opacity(0.9))
                            .shadow(color: .black.opacity(0.4), radius: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(20)
                }
                Spacer()
            }
        }
    }
}
