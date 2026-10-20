import Foundation

public enum LGControlGroup: String, CaseIterable, Sendable, Equatable {
    case gameBar = "Game Bar"
    case gameAndHDMI = "Game & HDMI"
    case picture = "Picture"
    case aiPicture = "AI Picture"
    case aspectRatio = "Aspect Ratio"
    case motion = "Motion"
    case sound = "Sound"
    case oledCare = "OLED Care"
    case whiteBalance = "White Balance"
}

public struct LGControlOption: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String

    public init(_ id: String, title: String? = nil) {
        self.id = id
        self.title = title ?? id
    }
}

public struct LGNamedResource: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct LGControlSnapshot: Sendable, Equatable {
    public let values: [String: String]
    public let applications: [LGNamedResource]
    public let inputs: [LGNamedResource]

    public init(
        values: [String: String] = [:],
        applications: [LGNamedResource] = [],
        inputs: [LGNamedResource] = []
    ) {
        self.values = values
        self.applications = applications
        self.inputs = inputs
    }
}

public enum LGControlValueKind: Sendable, Equatable {
    case range(minimum: Int, maximum: Int)
    case options([LGControlOption])
    case integerArray(count: Int, minimum: Int, maximum: Int)
}

/// A typed, UI-independent representation of the retained LG actions built by
/// `LgDevice.AddGenericPictureAction` in the legacy application.
public struct LGControlDescriptor: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let category: String
    public let group: LGControlGroup
    public let valueKind: LGControlValueKind
    public let minimumModelYear: Int?

    public init(
        id: String,
        title: String,
        category: String = "picture",
        group: LGControlGroup,
        valueKind: LGControlValueKind,
        minimumModelYear: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.group = group
        self.valueKind = valueKind
        self.minimumModelYear = minimumModelYear
    }

    public var defaultValue: String {
        switch valueKind {
        case let .range(minimum, maximum):
            return String(min(max(0, minimum), maximum))
        case let .options(options):
            return options.first?.id ?? ""
        case let .integerArray(count, _, _):
            return Array(repeating: "0", count: count).joined(separator: ",")
        }
    }

    public func validatedValue(_ rawValue: String) throws -> JSONValue {
        switch valueKind {
        case let .range(minimum, maximum):
            guard let value = Int(rawValue), (minimum...maximum).contains(value) else {
                throw TVProtocolError.remoteFailure("\(title) requires a value from \(minimum) through \(maximum).")
            }
            // The legacy LG API serializes ordinary setting values as strings.
            return .string(String(value))
        case let .options(options):
            guard options.contains(where: { $0.id == rawValue }) else {
                throw TVProtocolError.remoteFailure("\(title) has an unsupported value.")
            }
            return .string(rawValue)
        case let .integerArray(count, minimum, maximum):
            let values = rawValue.split(separator: ",", omittingEmptySubsequences: false).map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard values.count == count,
                  let integers = Optional(values.compactMap(Int.init)),
                  integers.count == count,
                  integers.allSatisfy({ (minimum...maximum).contains($0) }) else {
                throw TVProtocolError.remoteFailure(
                    "\(title) requires \(count) comma-separated values from \(minimum) through \(maximum)."
                )
            }
            return .array(integers.map { .number(Double($0)) })
        }
    }
}

public enum LGControlCatalog {
    private static let offOn = options("off", "on")
    private static let offToHigh = options("off", "low", "medium", "high")

    public static let controls: [LGControlDescriptor] = {
        var result: [LGControlDescriptor] = [
            range("backlight", "Backlight / OLED Pixel Brightness", 0, 100, .gameBar),
            range("contrast", "Contrast", 0, 100, .gameBar),
            range("brightness", "Brightness / Black Level", 0, 100, .gameBar),
            range("color", "Color", 0, 100, .gameBar),

            choice("pictureMode", "Picture Mode", .picture, options(
                "cinema", "eco", "expert1", "expert2", "game", "normal", "photo", "sports", "technicolor", "vivid", "hdrEffect", "filmMaker",
                "hdrCinema", "hdrCinemaBright", "hdrExternal", "hdrGame", "hdrStandard", "hdrTechnicolor", "hdrVivid", "hdrFilmMaker",
                "dolbyHdrCinema", "dolbyHdrCinemaBright", "dolbyHdrDarkAmazon", "dolbyHdrGame", "dolbyHdrStandard", "dolbyHdrVivid", "dolbyStandard"
            )),
            range("sharpness", "Sharpness", 0, 50, .picture),
            choice("colorGamut", "Color Gamut", .picture, options("auto", "extended", "wide", "srgb", "native")),
            choice("dynamicContrast", "Dynamic Contrast", .picture, offToHigh),
            choice("superResolution", "Super Resolution", .picture, offToHigh),
            choice("gamma", "Gamma", .picture, options("low", "medium", "high1", "high2")),
            range("colorTemperature", "Color Temperature", -50, 50, .picture),
            choice("whiteBalanceColorTemperature", "White Balance Color Temperature", .picture, options("cool", "medium", "warm1", "warm2", "warm3")),
            choice("eyeComfortMode", "Eye Comfort Mode", .picture, offOn),
            choice("peakBrightness", "Peak Brightness", .picture, offToHigh, minimumModelYear: 2019),
            choice("smoothGradation", "Smooth Gradation", .picture, options("off", "on", "low", "medium", "high", "auto"), minimumModelYear: 2019),
            choice("energySaving", "Energy Saving", .picture, options("auto", "off", "min", "med", "max", "screen_off")),
            choice("hdrDynamicToneMapping", "HDR Dynamic Tone Mapping", .picture, options("on", "off", "HGIG")),
            choice("blackLevel", "HDMI Black Level", .picture, options("low", "medium", "high", "limited", "full", "auto")),
            choice("dolbyPrecisionDetail", "Dolby Precision Detail", .picture, offOn, minimumModelYear: 2022),
            choice("noiseReduction", "Noise Reduction", .picture, offToHigh),
            choice("mpegNoiseReduction", "MPEG Noise Reduction", .picture, offToHigh),

            choice("ai_Brightness", "AI Brightness", .aiPicture, offOn, category: "aiPicture", minimumModelYear: 2019),
            choice("ai_Genre", "AI Genre Selection", .aiPicture, offOn, category: "aiPicture", minimumModelYear: 2021),
            choice("ai_Picture", "AI Picture Pro", .aiPicture, offOn, category: "aiPicture", minimumModelYear: 2021),

            choice("arcPerApp", "Aspect Ratio", .aspectRatio, options(
                "_21x9", "_16x9", "_4x3", "_14x9", "_32x9", "_32x12", "just_scan", "original", "full_wide", "limited", "zoom", "zoom2", "cinema_zoom", "vertZoom", "allDirZoom", "twinZoom"
            ), category: "aspectRatio"),
            choice("justScan", "Just Scan", .aspectRatio, options("off", "on", "auto"), category: "aspectRatio"),
            range("allDirZoomHRatio", "All-Direction Zoom Horizontal Ratio", 0, 10, .aspectRatio, category: "aspectRatio"),
            range("allDirZoomVRatio", "All-Direction Zoom Vertical Ratio", 0, 9, .aspectRatio, category: "aspectRatio"),
            range("allDirZoomHPosition", "All-Direction Zoom Horizontal Position", -10, 9, .aspectRatio, category: "aspectRatio"),
            range("allDirZoomVPosition", "All-Direction Zoom Vertical Position", -9, 9, .aspectRatio, category: "aspectRatio"),
            range("vertZoomVPosition", "Vertical Zoom Position", -8, 9, .aspectRatio, category: "aspectRatio"),
            range("vertZoomVRatio", "Vertical Zoom Ratio", 0, 9, .aspectRatio, category: "aspectRatio"),

            choice("truMotionMode", "TruMotion", .motion, options("off", "smooth", "clear", "clearPlus", "cinemaClear", "natural", "user")),
            range("truMotionJudder", "TruMotion Judder", 0, 10, .motion),
            range("truMotionBlur", "TruMotion Blur", 0, 10, .motion),
            choice("motionProOLED", "OLED Motion Pro", .motion, offToHigh, minimumModelYear: 2019),
            choice("motionPro", "Motion Pro", .motion, offOn),
            choice("realCinema", "Real Cinema", .motion, offOn),

            range("lowLevelAdjustment", "Fine Tune Dark Areas", -30, 30, .gameAndHDMI, category: "other", minimumModelYear: 2019),
            range("blackStabilizer", "Black Stabilizer", -30, 30, .gameAndHDMI, category: "other", minimumModelYear: 2021),
            range("whiteStabilizer", "White Stabilizer", -30, 30, .gameAndHDMI, category: "other", minimumModelYear: 2021),
            choice("blueLight", "Reduce Blue Light", .gameAndHDMI, options("off", "level1", "level2"), category: "other", minimumModelYear: 2021),
            choice("darkMode", "Dark Room Mode", .gameAndHDMI, options("off", "level1", "level2"), category: "other", minimumModelYear: 2022),
            choice("gameOptimization", "VRR & G-Sync", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2021),
            choice("inputOptimization", "Prevent Input Delay", .gameAndHDMI, options("auto", "on", "standard", "boost"), category: "other", minimumModelYear: 2021),
            choice("freesync", "AMD FreeSync Premium", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2020),
            choice("enableQFT", "Quick Frame Transport", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2025),
            choice("enable144HzBooster", "144Hz / 165Hz Mode", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2024),
            choice("enableALLM", "ALLM", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2022),
            choice("444BypassHDMINone", "4:4:4 Pass Through (Non-HDMI)", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2023),
            choice("qmsVrr", "QMS-VRR", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2023),
            choice("enableDolbyVisionPC", "Dolby Vision PC", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2024),
            choice("masterLuminanceLevel", "Master Luminance Level", .gameAndHDMI, options("_540nit", "_1000nit", "_4000nit"), category: "other"),

            range("audioVolume", "Volume", 0, 100, .sound, category: "sound"),
            choice("soundMode", "Sound Mode", .sound, options("aiSoundPlus", "aiSound", "standard", "news", "music", "movie", "sports", "game", "pagode", "sertaWego", "brazilianPunk", "asc", "bass"), category: "sound"),
            choice("smartSoundMode", "Adaptive Sound Control", .sound, offOn, category: "sound"),
            choice("soundOutput", "Sound Output", .sound, options("tv_speaker", "external_arc", "external_optical", "bt_soundbar", "mobile_phone", "lineout", "headphone", "tv_speaker_bluetooth", "tv_external_speaker", "tv_speaker_headphone", "wisa_speaker"), category: "sound"),
            choice("autoVolume", "Auto Volume", .sound, offOn, category: "sound"),
            choice("virtualSurround", "Virtual Surround", .sound, offOn, category: "sound"),

            choice("screenShift", "Screen Shift", .oledCare, offOn),
            choice("logoLuminanceAdjust", "Logo Luminance", .oledCare, options("off", "light", "strong")),
            choice("wolwowlOnOff", "Wake-On-LAN", .oledCare, options("false", "true"), category: "network"),

            range("whiteBalanceBlueOffset", "White Balance - Blue Offset", -50, 50, .whiteBalance),
            range("whiteBalanceBlueGain", "White Balance - Blue Gain", -50, 50, .whiteBalance),
            range("whiteBalanceGreenOffset", "White Balance - Green Offset", -50, 50, .whiteBalance),
            range("whiteBalanceGreenGain", "White Balance - Green Gain", -50, 50, .whiteBalance),
            range("whiteBalanceRedOffset", "White Balance - Red Offset", -50, 50, .whiteBalance),
            range("whiteBalanceRedGain", "White Balance - Red Gain", -50, 50, .whiteBalance),
            choice("whiteBalanceMethod", "White Balance - Method", .whiteBalance, options("_2", "_10", "_22"))
        ]

        result.append(contentsOf: [
            integerArray("adjustingLuminance", "Adjusting Luminance (22 point)", count: 22, minimum: -50, maximum: 50),
            integerArray("whiteBalanceBlue", "White Balance Blue (22 point)", count: 22, minimum: -50, maximum: 50),
            integerArray("whiteBalanceGreen", "White Balance Green (22 point)", count: 22, minimum: -50, maximum: 50),
            integerArray("whiteBalanceRed", "White Balance Red (22 point)", count: 22, minimum: -50, maximum: 50),
            integerArray("whiteBalanceBlue10pt", "White Balance Blue (10 point)", count: 10, minimum: -50, maximum: 50),
            integerArray("whiteBalanceGreen10pt", "White Balance Green (10 point)", count: 10, minimum: -50, maximum: 50),
            integerArray("whiteBalanceRed10pt", "White Balance Red (10 point)", count: 10, minimum: -50, maximum: 50)
        ])

        for port in 1...4 {
            result.append(contentsOf: [
                choice("uhdDeepColorHDMI\(port)", "HDMI \(port) Deep Color", .gameAndHDMI, offOn, category: "other"),
                choice("gameMode_hdmi\(port)", "Game Optimizer HDMI \(port)", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2021),
                choice("gameOptimizationHDMI\(port)", "Game Optimization HDMI \(port)", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2019),
                choice("freesyncOLEDHDMI\(port)", "FreeSync OLED HDMI \(port)", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2020),
                choice("444BypassHDMI\(port)", "4:4:4 Pass Through HDMI \(port)", .gameAndHDMI, offOn, category: "other", minimumModelYear: 2023),
                choice("hdmiPcMode_hdmi\(port)", "PC Mode HDMI \(port)", .gameAndHDMI, options("false", "true"), category: "other")
            ])
        }
        return result
    }()

    public static func controls(in group: LGControlGroup) -> [LGControlDescriptor] {
        controls.filter { $0.group == group }
    }

    private static func range(
        _ id: String, _ title: String, _ minimum: Int, _ maximum: Int,
        _ group: LGControlGroup, category: String = "picture", minimumModelYear: Int? = nil
    ) -> LGControlDescriptor {
        LGControlDescriptor(
            id: id, title: title, category: category, group: group,
            valueKind: .range(minimum: minimum, maximum: maximum),
            minimumModelYear: minimumModelYear
        )
    }

    private static func choice(
        _ id: String, _ title: String, _ group: LGControlGroup,
        _ values: [LGControlOption], category: String = "picture", minimumModelYear: Int? = nil
    ) -> LGControlDescriptor {
        LGControlDescriptor(
            id: id, title: title, category: category, group: group,
            valueKind: .options(values), minimumModelYear: minimumModelYear
        )
    }

    private static func integerArray(
        _ id: String, _ title: String, count: Int, minimum: Int, maximum: Int
    ) -> LGControlDescriptor {
        LGControlDescriptor(
            id: id, title: title, group: .whiteBalance,
            valueKind: .integerArray(count: count, minimum: minimum, maximum: maximum)
        )
    }

    private static func options(_ values: String...) -> [LGControlOption] {
        values.map { LGControlOption($0) }
    }
}
