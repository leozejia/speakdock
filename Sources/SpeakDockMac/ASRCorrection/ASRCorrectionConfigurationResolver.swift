import Foundation
import SpeakDockCore

enum OnDeviceASRCorrectionDefaults {
    static let baseURL = "http://127.0.0.1:42100/v1"
    static let modelIdentifier = "Qwen3.5-2B-OptiQ-4bit"
}

enum ASRCorrectionConfigurationResolver {
    static func resolve(
        settings: AppSettings,
        runtimeOverride: ASRCorrectionConfiguration?
    ) -> ASRCorrectionConfiguration {
        if let runtimeOverride {
            return runtimeOverride
        }

        switch settings.asrCorrectionProvider {
        case .disabled:
            return .disabled
        case .onDevice:
            return ASRCorrectionConfiguration(
                provider: .onDevice,
                enabled: true,
                baseURL: OnDeviceASRCorrectionDefaults.baseURL,
                apiKey: "",
                model: OnDeviceASRCorrectionDefaults.modelIdentifier
            )
        case .customEndpoint:
            return ASRCorrectionConfiguration(
                provider: .customEndpoint,
                enabled: true,
                baseURL: settings.asrCorrectionBaseURL,
                apiKey: settings.asrCorrectionAPIKey,
                model: settings.asrCorrectionModel
            )
        }
    }
}
