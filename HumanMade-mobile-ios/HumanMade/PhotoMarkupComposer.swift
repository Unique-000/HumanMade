import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum PhotoMarkupComposer {
    static func copyStyledImage(
        from sourceImage: UIImage,
        settings: PhotoMarkupSettings,
        code: String?
    ) -> UIImage {
        let rendered = renderStyledImage(from: sourceImage, settings: settings, code: code)
        UIPasteboard.general.image = rendered
        return rendered
    }

    static func renderStyledImage(
        from sourceImage: UIImage,
        settings: PhotoMarkupSettings,
        code: String?
    ) -> UIImage {
        let baseImage = sourceImage.normalizedForRendering()
        let canvasSize = baseImage.size
        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = baseImage.scale
        rendererFormat.opaque = true

        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: rendererFormat)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: canvasSize)
            baseImage.draw(in: rect)

            let inset = max(20, min(canvasSize.width, canvasSize.height) * 0.04)
            let displayedCode = normalizedCode(from: code)

            if settings.humanMadeLabel {
                drawLabel(
                    "HumanMade.app",
                    in: context.cgContext,
                    at: CGPoint(x: inset, y: inset),
                    fontSize: max(24, canvasSize.width * 0.03),
                    fillColor: .white
                )
            }

            if settings.photoID {
                drawLabel(
                    displayedCode,
                    in: context.cgContext,
                    at: CGPoint(
                        x: inset,
                        y: canvasSize.height - inset - max(28, canvasSize.height * 0.04)
                    ),
                    fontSize: max(24, canvasSize.width * 0.032),
                    fillColor: .white
                )
            }

            if settings.qrCode {
                let size = max(88, min(canvasSize.width, canvasSize.height) * 0.16)
                let rect = CGRect(
                    x: canvasSize.width - inset - size,
                    y: canvasSize.height - inset - size,
                    width: size,
                    height: size
                )
                if let qrImage = makeQRCode(for: "https://human-made-web.vercel.app/photo/\(displayedCode)", size: rect.size) {
                    qrImage.draw(in: rect)
                } else {
                    drawPlaceholderQR(in: context.cgContext, rect: rect)
                }
            }
        }
    }

    static func dummyCode() -> String {
        "ABC123"
    }

    private static func normalizedCode(from code: String?) -> String {
        let value = (code ?? dummyCode()).trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            return dummyCode()
        }
        return String(value.prefix(6))
    }

    private static func makeQRCode(for string: String, size: CGSize) -> UIImage? {
        let context = CIContext(options: nil)
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let transformX = size.width / outputImage.extent.size.width
        let transformY = size.height / outputImage.extent.size.height
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: transformX, y: transformY))

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private static func drawLabel(
        _ text: String,
        in context: CGContext,
        at point: CGPoint,
        fontSize: CGFloat,
        fillColor: UIColor
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: fillColor,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .left
                return style
            }()
        ]

        let attributedText = NSAttributedString(string: text, attributes: attributes)
        attributedText.draw(at: point)
    }

    private static func drawPill(text: String, in context: CGContext, rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2)
        context.saveGState()
        context.setFillColor(UIColor.black.withAlphaComponent(0.55).cgColor)
        context.addPath(path.cgPath)
        context.fillPath()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: rect.height * 0.42, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        let textPoint = CGPoint(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2
        )
        attributedText.draw(at: textPoint)
        context.restoreGState()
    }

    private static func drawPlaceholderQR(in context: CGContext, rect: CGRect) {
        context.saveGState()

        let background = UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.12)
        context.setFillColor(UIColor.white.cgColor)
        context.addPath(background.cgPath)
        context.fillPath()

        let margin = rect.width * 0.08
        let gridRect = rect.insetBy(dx: margin, dy: margin)
        let cellCount = 7
        let cellWidth = gridRect.width / CGFloat(cellCount)
        let cellHeight = gridRect.height / CGFloat(cellCount)
        let seed = dummyCode().unicodeScalars.reduce(0) { $0 + Int($1.value) }

        for row in 0..<cellCount {
            for col in 0..<cellCount {
                if shouldFillCell(row: row, col: col, seed: seed) {
                    let cellRect = CGRect(
                        x: gridRect.minX + CGFloat(col) * cellWidth,
                        y: gridRect.minY + CGFloat(row) * cellHeight,
                        width: cellWidth,
                        height: cellHeight
                    ).insetBy(dx: cellWidth * 0.12, dy: cellHeight * 0.12)
                    context.setFillColor(UIColor.black.cgColor)
                    context.fill(cellRect)
                }
            }
        }

        context.restoreGState()
    }

    private static func shouldFillCell(row: Int, col: Int, seed: Int) -> Bool {
        if row < 2 && col < 2 { return true }
        if row < 2 && col > 4 { return true }
        if row > 4 && col < 2 { return true }

        let value = (row * 31 + col * 17 + seed) % 7
        return value == 0 || value == 2 || value == 5
    }
}

private extension UIImage {
    func normalizedForRendering() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

