import UIKit
import SwiftUI

struct PhotoDetail: View {
    let photo: CapturedPhoto
    let namespace: Namespace.ID
    let onDelete: () -> Void
    let onClose: () -> Void

    @AppStorage(PhotoMarkupSettings.userDefaultsKeys.humanMadeLabel) private var showHumanMadeLabel = PhotoMarkupSettings.default.humanMadeLabel
    @AppStorage(PhotoMarkupSettings.userDefaultsKeys.qrCode) private var showQRCode = PhotoMarkupSettings.default.qrCode
    @AppStorage(PhotoMarkupSettings.userDefaultsKeys.photoID) private var showPhotoID = PhotoMarkupSettings.default.photoID
    @AppStorage(PhotoMarkupSettings.userDefaultsKeys.passwordLocked) private var passwordLocked = PhotoMarkupSettings.default.passwordLocked
    @AppStorage(PhotoMarkupSettings.userDefaultsKeys.localization) private var showLocalization = PhotoMarkupSettings.default.localization
    @State private var copiedMessage: String?

    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
                .opacity(0.92)
                .onTapGesture {
                    onClose()
                }

            VStack(spacing: 16) {
                HStack {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(.red.opacity(0.55), in: Circle())
                    }
                    .glassEffect()

                    Spacer()

                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .glassEffect()
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                imageView
                    .padding(.horizontal, 20)

                VStack(spacing: 10) {
                    HStack {
                        Text("Code: " + (photo.code ?? photo.url.lastPathComponent))
                            .lineLimit(1)
                        Spacer()
                    }

                    HStack {
                        Text(photo.createdAt.formatted(date: .abbreviated, time: .omitted))
                        Text(photo.createdAt.formatted(date: .omitted, time: .shortened))
                        Spacer()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 20)

                Button {
                    copyStyledImage()
                } label: {
                    Text("Copy Photo")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.black)
                        .background(.white, in: Capsule())
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
            .padding(.top, 20)
        }
    }

    @ViewBuilder
    private var imageView: some View {
        if let image = UIImage(contentsOfFile: photo.url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .matchedGeometryEffect(id: photo.id, in: namespace)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.4), radius: 18, y: 10)
        } else {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.secondary.opacity(0.2))
                .overlay {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
                .matchedGeometryEffect(id: photo.id, in: namespace)
                .frame(maxWidth: .infinity)
                .frame(height: 280)
        }
    }

    private func copyStyledImage() {
        guard let image = UIImage(contentsOfFile: photo.url.path) else {
            copiedMessage = "Could not load the photo."
            return
        }

        let settings = PhotoMarkupSettings(
            humanMadeLabel: showHumanMadeLabel,
            qrCode: showQRCode,
            photoID: showPhotoID,
            passwordLocked: passwordLocked,
            localization: showLocalization
        )

        _ = PhotoMarkupComposer.copyStyledImage(from: image, settings: settings, code: photo.code)
        copiedMessage = "Styled image copied to clipboard."
    }
}

struct PhotoDetail_Previews: PreviewProvider {
    static var previews: some View {
        PhotoDetailPreviewHost()
    }
}

private struct PhotoDetailPreviewHost: View {
    @Namespace private var namespace

    var body: some View {
        PhotoDetail(
            photo: CapturedPhoto(url: URL(fileURLWithPath: "/tmp/demo.jpg"), createdAt: Date(), code: "ABC123"),
            namespace: namespace,
            onDelete: {},
            onClose: {}
        )
    }
}
