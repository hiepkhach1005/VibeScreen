import Foundation

/// Parses the legacy `Action(value):delay:option` format while retaining
/// unknown actions for a later device/platform adapter.
public enum PresetStepParser {
    public static func parse(
        _ rawValue: String,
        defaultDelayMilliseconds: Int = 0,
        defaultOption: String = ""
    ) -> PresetStep {
        let raw = rawValue
        let openingIndex = raw.firstIndex(of: "(")
        var actionValue: String? = nil
        var parts: [String] = []

        if let openingIndex,
           let closingIndex = raw.firstIndex(of: ")"),
           closingIndex > openingIndex {
            actionValue = String(raw[raw.index(after: openingIndex)..<closingIndex])
            parts.append(String(raw[...closingIndex]))

            let suffixStart = raw.index(after: closingIndex)
            if suffixStart < raw.endIndex {
                var suffix = String(raw[suffixStart...])
                if suffix.first == ":" {
                    suffix.removeFirst()
                }
                parts.append(contentsOf: suffix.split(separator: ":", omittingEmptySubsequences: false).map(String.init))
            }
        } else {
            parts = raw.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        }

        var delay = max(0, defaultDelayMilliseconds)
        var option = defaultOption
        var key = raw

        if parts.count >= 2,
           let parsedDelay = Int(parts[1]),
           parsedDelay >= 0 {
            delay = parsedDelay
            key = parts[0]
        }

        if parts.count >= 3 {
            option = parts[2]
        }

        let actionName: String
        if let openingIndex = key.firstIndex(of: "("), openingIndex > key.startIndex {
            actionName = String(key[..<openingIndex])
        } else {
            actionName = key
        }

        let parameters: [String]?
        if let parameterStart = key.firstIndex(of: "("),
           let parameterEnd = key.lastIndex(of: ")"),
           parameterEnd > parameterStart {
            let parameterString = key[key.index(after: parameterStart)..<parameterEnd]
            parameters = parameterString.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
        } else {
            parameters = nil
        }

        let typedAction = PresetStepAction.legacy(name: actionName, value: actionValue)

        return PresetStep(
            rawValue: raw,
            step: key,
            actionName: actionValue == nil ? nil : actionName,
            actionValue: actionValue,
            parameters: parameters,
            delayMilliseconds: delay,
            option: option,
            action: typedAction
        )
    }
}
