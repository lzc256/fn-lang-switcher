import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @State private var launchAtLogin: Bool = {
        SMAppService.mainApp.status == .enabled
    }()
    
    @AppStorage("switchThreshold") private var switchThreshold: Double = 0.50

    var body: some View {
        VStack(spacing: 20) {
            Text("Press the FN key to switch keyboard input source.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Switching Threshold:")
                        Spacer()
                        Text(String(format: "%.2fs", switchThreshold))
                            .monospacedDigit()
                            .foregroundColor(.accentColor)
                    }
                    
                    Slider(value: $switchThreshold, in: 0.2...2.0, step: 0.05) {
                        Text("Threshold")
                    } minimumValueLabel: {
                        Text("0.2s")
                    } maximumValueLabel: {
                        Text("2.0s")
                    }
                    
                    Text("Time interval to trigger 'back-and-forth' vs 'cycle' mode.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(24)
        .frame(width: 400, height: 280)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
