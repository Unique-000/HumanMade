//
//  VerifyView.swift
//  HumanMade
//
//  Created by unique on 01/05/2026.
//

import SwiftUI
import UIKit

struct VerifyView: View {
    @StateObject private var viewModel = VerifyViewModel()
    @State private var isShowingPhotoLibrary = false

    var body: some View {
        ZStack {
            backgroundImage
                .blur(radius: 10)
                .opacity(0.4)
                .ignoresSafeArea()

            VStack {
                GlassEffectContainer {
                    HStack {
                        TextField(
                            "Code 1H9083",
                            text: Binding(
                                get: { viewModel.code },
                                set: { viewModel.updateCode($0) }
                            )
                        )
                        .font(.system(size: 18, weight: .semibold))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit {
                            viewModel.submitCodeIfPossible()
                        }
                        .padding(15)
                        .padding(.horizontal, 10)
                        .glassEffect()
                        .clipShape(Capsule())

                        Button {
                            isShowingPhotoLibrary = true
                        } label: {
                            Image(systemName: "photo")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(10)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                }

                Spacer()

                VerifiedImageView(
                    record: viewModel.verificationRecord,
                    isLoading: viewModel.isLoadingCode || viewModel.isUploadingImage,
                    infoMessage: viewModel.infoMessage,
                    errorMessage: viewModel.errorMessage
                )
                Spacer()
                Spacer()
            }
            .frame(maxWidth: 350)
            .padding(.horizontal)
        }
        .sheet(isPresented: $isShowingPhotoLibrary) {
            PhotoLibraryPickerView(
                onImagePicked: { image in
                    viewModel.handlePickedImage(image)
                    isShowingPhotoLibrary = false
                },
                onCancel: {
                    isShowingPhotoLibrary = false
                }
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var backgroundImage: some View {
        if let record = viewModel.verificationRecord {
            AsyncImage(url: record.url) { phase in
                switch phase {
                case .empty:
                    Color(.systemBackground)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Color(.systemBackground)
                @unknown default:
                    Color(.systemBackground)
                }
            }
        } else {
            Color(.systemBackground)
        }
    }
}

struct VerifyView_Previews: PreviewProvider {
    static var previews: some View {
        VerifyView()
    }
}
