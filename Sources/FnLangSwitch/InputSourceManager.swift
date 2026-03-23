import Carbon
import Foundation

final class InputSourceManager {
    private var inputSources: [TISInputSource] = []
    
    private var lastToggleTime: Date = .distantPast
    private var previousSourceID: String?
    private var lastKnownID: String?

    init() {
        reload()
        
        let current = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        lastKnownID = inputSourceID(current)
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleExternalSwitch()
        }
    }

    func reload() {
        guard let cfList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            inputSources = []
            return
        }
        inputSources = cfList.filter { source in
            guard let categoryPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) else { return false }
            let category = Unmanaged<CFString>.fromOpaque(categoryPtr).takeUnretainedValue() as String
            guard category == kTISCategoryKeyboardInputSource as String else { return false }

            guard let selectablePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable) else { return false }
            let selectable = Unmanaged<CFBoolean>.fromOpaque(selectablePtr).takeUnretainedValue()
            return CFBooleanGetValue(selectable)
        }
    }

    private func handleExternalSwitch() {
        let current = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        let currentID = inputSourceID(current)
        
        guard currentID != lastKnownID else { return }
        
        let now = Date()
        if now.timeIntervalSince(lastToggleTime) > 0.1 {
            previousSourceID = lastKnownID
        }
        
        lastKnownID = currentID
    }

    func toggleInputSource() {
        guard inputSources.count > 1 else { return }

        let threshold = UserDefaults.standard.double(forKey: "switchThreshold") == 0 ? 0.75 : UserDefaults.standard.double(forKey: "switchThreshold")

        let now = Date()
        let timeDiff = now.timeIntervalSince(lastToggleTime)
        lastToggleTime = now

        let current = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        let currentID = inputSourceID(current)

        var targetSource: TISInputSource?

        if timeDiff > threshold {
            if let prevID = previousSourceID, 
            prevID != currentID, 
            let prevSource = source(for: prevID) {
                targetSource = prevSource
            } else {
                targetSource = nextCycleSource(currentID: currentID)
            }
            previousSourceID = currentID
        } else {
            targetSource = nextCycleSource(currentID: currentID)
        }

        if let target = targetSource {
            TISSelectInputSource(target)
            lastKnownID = inputSourceID(target)
        }
    }

    private func nextCycleSource(currentID: String) -> TISInputSource? {
        guard let idx = inputSources.firstIndex(where: { inputSourceID($0) == currentID }) else {
            return inputSources.first
        }
        let nextIndex = (idx + 1) % inputSources.count
        return inputSources[nextIndex]
    }

    private func source(for id: String) -> TISInputSource? {
        return inputSources.first(where: { inputSourceID($0) == id })
    }

    private func inputSourceID(_ source: TISInputSource) -> String {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return "" }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }
}