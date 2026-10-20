import XCTest
@testable import VibeScreenCore

final class PresetStepParserTests: XCTestCase {
    func testParsesLegacyActionDelayAndOption() {
        let step = PresetStepParser.parse("Power(ON):250:Hold")

        XCTAssertEqual(step.actionName, "Power")
        XCTAssertEqual(step.actionValue, "ON")
        XCTAssertEqual(step.parameters, ["ON"])
        XCTAssertEqual(step.step, "Power(ON)")
        XCTAssertEqual(step.delayMilliseconds, 250)
        XCTAssertEqual(step.option, "Hold")
        XCTAssertEqual(step.updatedRawValue, "Power(ON):250:Hold")
    }

    func testParsesSimpleLegacyStepWithoutActionParentheses() {
        let step = PresetStepParser.parse("DisplayRefresh:40")

        XCTAssertNil(step.actionName)
        XCTAssertNil(step.actionValue)
        XCTAssertEqual(step.step, "DisplayRefresh")
        XCTAssertEqual(step.delayMilliseconds, 40)
        XCTAssertEqual(step.option, "")
    }

    func testPreservesZeroDelayForSimpleLegacyStep() {
        let step = PresetStepParser.parse("PowerOff:0:Immediate")

        XCTAssertEqual(step.step, "PowerOff")
        XCTAssertEqual(step.delayMilliseconds, 0)
        XCTAssertEqual(step.option, "Immediate")
        XCTAssertEqual(step.action, .legacy(name: "PowerOff", value: nil))
    }

    func testKeepsMalformedDelayAndOriginalKeyForMigrationReview() {
        let step = PresetStepParser.parse("Unknown:not-a-delay", defaultDelayMilliseconds: 15)

        XCTAssertEqual(step.step, "Unknown:not-a-delay")
        XCTAssertEqual(step.delayMilliseconds, 15)
        XCTAssertEqual(step.action, .legacy(name: "Unknown:not-a-delay", value: nil))
    }
}
