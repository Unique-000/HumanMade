import UIKit
import SwiftUI

struct PhotosView: View {
    @ObservedObject var photoStore: CapturedPhotoStore
    @Namespace private var galleryNamespace
    @State private var selectedPhoto: CapturedPhoto?
    @State private var isShowingAccountSheet = false
    @AppStorage(PhotoMarkupSettings.userDefaultsKeys.humanMadeLabel) private var showHumanMadeLabel = PhotoMarkupSettings.default.humanMadeLabel
    @AppStorage(PhotoMarkupSettings.userDefaultsKeys.qrCode) private var showQRCode = PhotoMarkupSettings.default.qrCode
    @AppStorage(PhotoMarkupSettings.userDefaultsKeys.photoID) private var showPhotoID = PhotoMarkupSettings.default.photoID
    @AppStorage(PhotoMarkupSettings.userDefaultsKeys.passwordLocked) private var passwordLocked = PhotoMarkupSettings.default.passwordLocked
    @AppStorage(PhotoMarkupSettings.userDefaultsKeys.localization) private var showLocalization = PhotoMarkupSettings.default.localization
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("userLogin") private var userLogin = ""

    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if photoStore.photos.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(photoStore.photos) { photo in
                                PhotoTile(
                                    photo: photo,
                                    namespace: galleryNamespace,
                                    isHidden: selectedPhoto?.id == photo.id
                                )
                                .opacity(selectedPhoto?.id == photo.id ? 0 : 1)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                                        selectedPhoto = photo
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                .scrollDisabled(selectedPhoto != nil)
                .allowsHitTesting(selectedPhoto == nil)

                if let selectedPhoto {
                    PhotoDetail(
                        photo: selectedPhoto,
                        namespace: galleryNamespace,
                        onDelete: {
                            deleteSelectedPhoto(selectedPhoto)
                        },
                        onClose: closeSelectedPhoto
                    )
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .navigationTitle("Photos")
            .navigationBarHidden(selectedPhoto != nil)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAccountSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Account settings")
                }
            }
            .onAppear {
                photoStore.reload()
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.88), value: selectedPhoto?.id)
            .sheet(isPresented: $isShowingAccountSheet) {
                accountSheet
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var accountSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(userLogin.isEmpty ? "Unknown Login" : userLogin)
                            .font(.system(size: 34, weight: .bold, design: .default))
                            .foregroundStyle(.primary)

                        Text("Account and photo settings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    sectionCard(title: "Subscription") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status")
                                .font(.headline)
                            Text("Free")
                                .font(.title3.weight(.semibold))
                            Text("Upgrade options can live here later.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    sectionCard(title: "Photo Settings") {
                        VStack(spacing: 14) {
                            Toggle("HumanMade label", isOn: $showHumanMadeLabel)
                            Toggle("QR code", isOn: $showQRCode)
                            Toggle("Photo ID", isOn: $showPhotoID)
                            Toggle("Password locked", isOn: $passwordLocked)
                            Toggle("Localization", isOn: $showLocalization)
                        }
                    }

                    Button {
                        logout()
                    } label: {
                        Text("Log Out")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color.red, in: Capsule())
                    }
                    .padding(.top, 6)
                }
                .padding(20)
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func closeSelectedPhoto() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
            selectedPhoto = nil
        }
    }

    private func deleteSelectedPhoto(_ photo: CapturedPhoto) {
        do {
            try photoStore.deletePhoto(photo)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                selectedPhoto = nil
            }
        } catch {
            photoStore.reload()
        }
    }

    private func logout() {
        isShowingAccountSheet = false
        selectedPhoto = nil
        userLogin = ""
        isAuthenticated = false
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.on.rectangle")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("No captured photos yet")
                .font(.headline)

            Text("Photos you capture will appear here.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }
}

struct PhotosView_Previews: PreviewProvider {
    static var previews: some View {
        PhotosView(photoStore: CapturedPhotoStore())
    }
}

struct PhotoTile: View {
    let photo: CapturedPhoto
    let namespace: Namespace.ID
    let isHidden: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnail
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(photo.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .opacity(isHidden ? 0.01 : 1)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = UIImage(contentsOfFile: photo.url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .matchedGeometryEffect(id: photo.id, in: namespace)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.secondary.opacity(0.15))
                .overlay {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .matchedGeometryEffect(id: photo.id, in: namespace)
        }
    }
}
