// FILE: CodexMobileApp.swift
// Purpose: App entry point and root dependency wiring.
// Layer: App
// Exports: CodexMobileApp

import SwiftUI
import Sentry


@MainActor
@main
struct CodexMobileApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(CodexMobileAppDelegate.self) private var appDelegate
    @State private var codexService: CodexService

    init() {
        SentrySDK.start { options in
            options.dsn = "https://af1bd4118b529a6753af65d94bf6647c@o4505538365030400.ingest.us.sentry.io/4511303057080320"
            options.debug = true // Enabled debug when first installing is always helpful

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
                $0.lifecycle = .trace
            }

            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // This adds a screenshot to the error events
            // options.attachViewHierarchy = true // This adds the view hierarchy to the error events
        }
        Self.captureStartupErrorExample()
        // Remove the next line after confirming that your Sentry integration is working.
        SentrySDK.capture(message: "This app uses Sentry! :)")

        let service = CodexService()
        service.configureNotifications()
        _codexService = State(initialValue: service)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(codexService)
                .onOpenURL { url in
                    Task { @MainActor in
                        guard CodexService.legacyGPTLoginCallbackEnabled else {
                            return
                        }
                        await codexService.handleGPTLoginCallbackURL(url)
                    }
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.didReceiveMemoryWarningNotification
                    )
                ) { _ in
                    TurnCacheManager.resetAll()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .background else { return }
                    TurnCacheManager.resetAll()
                }
        }
    }

    private static func captureStartupErrorExample() {
        do {
            try aMethodThatMightFail()
        } catch {
            SentrySDK.capture(error: error)
        }
    }

    private static func aMethodThatMightFail() throws {
        throw SentryStartupError.example
    }
}

private enum SentryStartupError: Error {
    case example
}
