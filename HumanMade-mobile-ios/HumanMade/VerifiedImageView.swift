//
//  VerifiedImageView.swift
//  HumanMade
//
//  Created by unique on 01/05/2026.
//

import SwiftUI
import UIKit

struct VerifiedImageView: View {
    let record: BackendImageRecord?
    let isLoading: Bool
    let infoMessage: String?
    let errorMessage: String?

    var body: some View {
        Group {
            if let record {
                VStack {
                    previewImage(for: record)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(30)
                        .shadow(radius: 10)
                        .padding(.bottom, 10)

                    VStack(spacing: 10) {
                        HStack {
                            Circle()
                                .frame(width: 15, height: 15)
                                .foregroundColor(statusColor)
                            Text(statusTitle)
                            Spacer()
                        }

                        HStack {
                            Text(record.localization ?? "No location")
                            Spacer()
                        }

                        HStack {
                            Text(formattedDate)
                            Spacer()
                        }

                        if record.code != nil || record.sha256 != nil || record.phash != nil || record.txSignature != nil {
                            Divider()
                                .padding(.vertical, 2)

                            VStack(alignment: .leading, spacing: 10) {
                                if let sha256 = record.sha256 {
                                    metadataRow(title: "SHA-256", value: sha256)
                                }

                                if let phash = record.phash {
                                    metadataRow(title: "pHash", value: phash)
                                }

                                if let txSignature = record.txSignature {
                                    metadataRow(title: "Tx ID", value: txSignature)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .glassEffect(in: .rect(cornerRadius: 30.0))
                }
            } else if isLoading {
                loadingView
            } else if let infoMessage {
                infoView(message: infoMessage)
            } else if let errorMessage {
                errorView(message: errorMessage)
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func previewImage(for record: BackendImageRecord) -> some View {
        AsyncImage(url: record.url) { phase in
            switch phase {
            case .empty:
                placeholder
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(30)
            case .failure:
                placeholder
            @unknown default:
                placeholder
            }
        }
    }

    private var loadingView: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.ultraThinMaterial)
            .frame(height: 280)
            .overlay {
                ProgressView()
            }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.secondary.opacity(0.15))
            .frame(height: 280)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.red)

            Text("Check failed")
                .font(.headline)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassEffect(in: .rect(cornerRadius: 30.0))
    }

    private func infoView(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.blue)

            Text("No Match Found")
                .font(.headline)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassEffect(in: .rect(cornerRadius: 30.0))
    }

    private var statusTitle: String {
        if isLoading {
            return "Checking..."
        }

        if errorMessage != nil {
            return "Check failed"
        }

        if let record {
            if let distance = record.distance {
                if distance == 0 {
                    return "Exact match"
                }
                return "\(similarityPercentage(for: distance))% similar image"
            } else {
                return "Matched image"
            }
        }

        return "Ready"
    }

    private var statusColor: Color {
        if isLoading {
            return .orange
        }

        if errorMessage != nil {
            return .red
        }

        if let record {
            if let distance = record.distance {
                return distance == 0 ? .green : .orange
            }
            return .green
        }

        return .orange
    }

    private func similarityPercentage(for distance: Int) -> Int {
        let clampedDistance = min(max(distance, 0), 75)
        return max(0, 75 - clampedDistance)
    }

    private var formattedDate: String {
        guard let takenAt = record?.takenAt else {
            return "No date"
        }

        return takenAt.formatted(date: .abbreviated, time: .shortened)
    }

    private func metadataRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    UIPasteboard.general.string = value
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text(value)
                .font(.footnote.monospaced())
                .foregroundStyle(.primary)
                .lineLimit(2)
                .textSelection(.enabled)
        }
    }
}

struct VerifiedImageView_Previews: PreviewProvider {
    static var previews: some View {
        VerifiedImageView(record: nil, isLoading: false, infoMessage: "No matching image was found for that photo.", errorMessage: nil)
    }
}
