import XCTest
import SpeakDockCore
@testable import SpeakDockMac

final class ASRCorrectionConfigurationResolverTests: XCTestCase {
    func testDisabledProviderResolvesToDisabledConfiguration() {
        let settings = AppSettings(
            appLanguage: .followSystem,
            inputLanguage: .defaultOption,
            captureRootPath: "/tmp",
            triggerSelection: .fn,
            asrCorrectionProvider: .disabled,
            asrCorrectionBaseURL: "https://example.com/v1",
            asrCorrectionAPIKey: "secret",
            asrCorrectionModel: "gpt-5.3-chat-latest",
            refineEnabled: false,
            refineBaseURL: "",
            refineAPIKey: "",
            refineModel: ""
        )

        let resolved = ASRCorrectionConfigurationResolver.resolve(
            settings: settings,
            runtimeOverride: nil
        )

        XCTAssertEqual(resolved, .disabled)
    }

    func testCustomEndpointProviderResolvesPersistedEndpointConfiguration() {
        let settings = AppSettings(
            appLanguage: .followSystem,
            inputLanguage: .defaultOption,
            captureRootPath: "/tmp",
            triggerSelection: .fn,
            asrCorrectionProvider: .customEndpoint,
            asrCorrectionBaseURL: "https://example.com/v1",
            asrCorrectionAPIKey: "secret",
            asrCorrectionModel: "gpt-5.3-chat-latest",
            refineEnabled: false,
            refineBaseURL: "",
            refineAPIKey: "",
            refineModel: ""
        )

        let resolved = ASRCorrectionConfigurationResolver.resolve(
            settings: settings,
            runtimeOverride: nil
        )

        XCTAssertEqual(
            resolved,
            ASRCorrectionConfiguration(
                provider: .customEndpoint,
                enabled: true,
                baseURL: "https://example.com/v1",
                apiKey: "secret",
                model: "gpt-5.3-chat-latest"
            )
        )
    }

    func testOnDeviceProviderResolvesLoopbackMLXServerDefaults() {
        let settings = AppSettings(
            appLanguage: .followSystem,
            inputLanguage: .defaultOption,
            captureRootPath: "/tmp",
            triggerSelection: .fn,
            asrCorrectionProvider: .onDevice,
            asrCorrectionBaseURL: "",
            asrCorrectionAPIKey: "",
            asrCorrectionModel: "",
            refineEnabled: false,
            refineBaseURL: "",
            refineAPIKey: "",
            refineModel: ""
        )

        let resolved = ASRCorrectionConfigurationResolver.resolve(
            settings: settings,
            runtimeOverride: nil
        )

        XCTAssertEqual(
            resolved,
            ASRCorrectionConfiguration(
                provider: .onDevice,
                enabled: true,
                baseURL: OnDeviceASRCorrectionDefaults.baseURL,
                apiKey: "",
                model: OnDeviceASRCorrectionDefaults.modelIdentifier
            )
        )
    }

    func testRuntimeOverrideStillWinsOverPersistedProvider() {
        let settings = AppSettings(
            appLanguage: .followSystem,
            inputLanguage: .defaultOption,
            captureRootPath: "/tmp",
            triggerSelection: .fn,
            asrCorrectionProvider: .disabled,
            asrCorrectionBaseURL: "",
            asrCorrectionAPIKey: "",
            asrCorrectionModel: "",
            refineEnabled: false,
            refineBaseURL: "",
            refineAPIKey: "",
            refineModel: ""
        )
        let runtimeOverride = ASRCorrectionConfiguration(
            provider: .customEndpoint,
            enabled: true,
            baseURL: "https://override.example.com/v1",
            apiKey: "runtime-secret",
            model: "gpt-5.4-mini"
        )

        let resolved = ASRCorrectionConfigurationResolver.resolve(
            settings: settings,
            runtimeOverride: runtimeOverride
        )

        XCTAssertEqual(resolved, runtimeOverride)
    }
}
