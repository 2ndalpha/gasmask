import SwiftUI

// MARK: - General Tab

struct GeneralTab: View {
    @StateObject private var loginItemObserver = LoginItemObserver()
    @AppStorage("overrideExternalModifications") private var overrideExternalModifications = true
    @AppStorage("showNameInStatusBar") private var showNameInStatusBar = false

    var body: some View {
        Form {
            Toggle("Open at Login", isOn: $loginItemObserver.isEnabled)
            Toggle("Override external modifications", isOn: $overrideExternalModifications)
            Toggle("Show Host File Name in Status Bar", isOn: $showNameInStatusBar)
        }
        .padding(20)
    }
}

// MARK: - Editor Tab

struct EditorTab: View {
    @AppStorage("syntaxHighlighting") private var syntaxHighlighting = true

    var body: some View {
        Form {
            Toggle("Syntax Highlighting", isOn: $syntaxHighlighting)
        }
        .padding(20)
    }
}

// MARK: - Remote Tab

struct RemoteTab: View {
    @State private var sliderPosition: Double

    init() {
        let currentMinutes = Int(Preferences.remoteHostsUpdateInterval())
        _sliderPosition = State(initialValue: Double(RemoteIntervalMapper.position(forMinutes: currentMinutes)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Update interval:")

            Slider(value: $sliderPosition, in: 1...9, step: 1)
                .onChange(of: sliderPosition) { newValue in
                    let minutes = RemoteIntervalMapper.minutes(forPosition: Int(newValue))
                    Preferences.setRemoteHostsUpdateInterval(Int32(minutes))
                }

            HStack(spacing: 0) {
                ForEach(Array(RemoteIntervalMapper.labels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
    }
}

// MARK: - Hotkeys Tab

struct HotkeysTab: View {
    var body: some View {
        // Keys match ObjC #define constants in Preferences.h:
        //   ActivatePreviousFilePrefKey = @"activatePreviousHotkey"
        //   ActivateNextFilePrefKey     = @"activateNextHotkey"
        //   UpdateAndSynchronizePrefKey = @"updateAndSynchronizeHotkey"
        Form {
            HStack {
                Text("Activate Previous File:")
                    .frame(width: 160, alignment: .trailing)
                ShortcutRecorderView(prefsKey: "activatePreviousHotkey")
                    .frame(width: 150, height: 22)
            }
            HStack {
                Text("Activate Next File:")
                    .frame(width: 160, alignment: .trailing)
                ShortcutRecorderView(prefsKey: "activateNextHotkey")
                    .frame(width: 150, height: 22)
            }
            HStack {
                Text("Update Remote Files:")
                    .frame(width: 160, alignment: .trailing)
                ShortcutRecorderView(prefsKey: "updateAndSynchronizeHotkey")
                    .frame(width: 150, height: 22)
            }
        }
        .padding(20)
    }
}

// MARK: - Update Tab

struct UpdateTab: View {
    @StateObject private var sparkleObserver = SparkleObserver()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Automatically check for updates", isOn: Binding(
                get: { sparkleObserver.automaticChecksEnabled },
                set: { sparkleObserver.setAutomaticChecks($0) }
            ))

            Text(sparkleObserver.lastCheckDateFormatted)
                .font(.caption)

            Button("Check Now") {
                sparkleObserver.checkForUpdates()
            }
            .disabled(!sparkleObserver.automaticChecksEnabled)
        }
        .padding(20)
    }
}
