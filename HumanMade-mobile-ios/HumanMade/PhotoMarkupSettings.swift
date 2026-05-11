import Foundation

struct PhotoMarkupSettings: Hashable {
    let humanMadeLabel: Bool
    let qrCode: Bool
    let photoID: Bool
    let passwordLocked: Bool
    let localization: Bool

    static let userDefaultsKeys = (
        humanMadeLabel: "photoSetting.humanMadeLabel",
        qrCode: "photoSetting.qrCode",
        photoID: "photoSetting.photoID",
        passwordLocked: "photoSetting.passwordLocked",
        localization: "photoSetting.localization"
    )

    static let `default` = PhotoMarkupSettings(
        humanMadeLabel: true,
        qrCode: true,
        photoID: true,
        passwordLocked: false,
        localization: true
    )
}

