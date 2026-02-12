// UnitsEngineTests.swift
// Scientific Calculator - Phase 3: Units Engine Tests

import XCTest
@testable import ScientificCalculator

final class UnitsEngineTests: XCTestCase {
    private let engine = UnitsEngine()
    
    // MARK: - Length
    
    func testKilometersToMeters() {
        let result = engine.convert(10, from: .kilometer, to: .meter).value
        XCTAssertEqual(result.toValue, 10000.0, accuracy: 1e-6)
    }
    
    func testMetersToFeet() {
        let result = engine.convert(1, from: .meter, to: .foot).value
        XCTAssertEqual(result.toValue, 3.28084, accuracy: 1e-3)
    }
    
    func testMilesToKilometers() {
        let result = engine.convert(1, from: .mile, to: .kilometer).value
        XCTAssertEqual(result.toValue, 1.609344, accuracy: 1e-4)
    }
    
    func testInchesToCentimeters() {
        let result = engine.convert(1, from: .inch, to: .centimeter).value
        XCTAssertEqual(result.toValue, 2.54, accuracy: 1e-6)
    }
    
    // MARK: - Mass
    
    func testKilogramsToPounds() {
        let result = engine.convert(1, from: .kilogram, to: .pound).value
        XCTAssertEqual(result.toValue, 2.20462, accuracy: 1e-3)
    }
    
    func testGramsToOunces() {
        let result = engine.convert(100, from: .gram, to: .ounce).value
        XCTAssertEqual(result.toValue, 3.5274, accuracy: 1e-2)
    }
    
    // MARK: - Time
    
    func testHoursToMinutes() {
        let result = engine.convert(2, from: .hour, to: .minute).value
        XCTAssertEqual(result.toValue, 120.0, accuracy: 1e-10)
    }
    
    func testDaysToSeconds() {
        let result = engine.convert(1, from: .day, to: .second).value
        XCTAssertEqual(result.toValue, 86400.0, accuracy: 1e-10)
    }
    
    // MARK: - Temperature
    
    func testCelsiusToFahrenheit() {
        let result = engine.convert(100, from: .celsius, to: .fahrenheit).value
        XCTAssertEqual(result.toValue, 212.0, accuracy: 1e-10)
    }
    
    func testFahrenheitToCelsius() {
        let result = engine.convert(32, from: .fahrenheit, to: .celsius).value
        XCTAssertEqual(result.toValue, 0.0, accuracy: 1e-10)
    }
    
    func testCelsiusToKelvin() {
        let result = engine.convert(0, from: .celsius, to: .kelvin).value
        XCTAssertEqual(result.toValue, 273.15, accuracy: 1e-10)
    }
    
    func testKelvinToFahrenheit() {
        let result = engine.convert(373.15, from: .kelvin, to: .fahrenheit).value
        XCTAssertEqual(result.toValue, 212.0, accuracy: 1e-8)
    }
    
    // MARK: - Angle
    
    func testDegreesToRadians() {
        let result = engine.convert(180, from: .degree, to: .radian).value
        XCTAssertEqual(result.toValue, .pi, accuracy: 1e-10)
    }
    
    func testRadiansToDegrees() {
        let result = engine.convert(.pi / 2, from: .radian, to: .degree).value
        XCTAssertEqual(result.toValue, 90.0, accuracy: 1e-10)
    }
    
    func testDegreesToGradians() {
        let result = engine.convert(90, from: .degree, to: .gradian).value
        XCTAssertEqual(result.toValue, 100.0, accuracy: 1e-10)
    }
    
    // MARK: - Identity
    
    func testSameUnitConversion() {
        let result = engine.convert(42, from: .meter, to: .meter).value
        XCTAssertEqual(result.toValue, 42.0, accuracy: 1e-10)
    }
    
    // MARK: - String Parsing
    
    func testParseAndConvert() {
        let result = engine.parseAndConvert("10 km to m")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.value.toValue ?? 0, 10000.0, accuracy: 1e-6)
    }
}
