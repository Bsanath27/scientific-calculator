// ScientificCalculatorTests/ASTToSympyConverterTests.swift
// Scientific Calculator - ASTToSympyConverter Unit Tests

import XCTest
@testable import ScientificCalculator

final class ASTToSympyConverterTests: XCTestCase {
    
    let pos = SourcePosition(offset: 0, length: 1)
    
    // MARK: - Numbers
    
    func testConvertInteger() {
        let node = Node.number(42, position: pos)
        XCTAssertEqual(ASTToSympyConverter.convert(node), "42")
    }
    
    func testConvertDecimal() {
        let node = Node.number(3.14, position: pos)
        XCTAssertEqual(ASTToSympyConverter.convert(node), "3.14")
    }
    
    // MARK: - Constants
    
    func testConvertPi() {
        let node = Node.constant(.pi, position: pos)
        XCTAssertEqual(ASTToSympyConverter.convert(node), "pi")
    }
    
    func testConvertE() {
        let node = Node.constant(.e, position: pos)
        XCTAssertEqual(ASTToSympyConverter.convert(node), "E")
    }
    
    // MARK: - Variables
    
    func testConvertVariable() {
        let node = Node.variable("x", position: pos)
        XCTAssertEqual(ASTToSympyConverter.convert(node), "x")
    }
    
    // MARK: - Unary Operations
    
    func testConvertNegation() {
        let node = Node.unary(op: .negate, operand: .number(5, position: pos), position: pos)
        XCTAssertEqual(ASTToSympyConverter.convert(node), "-5")
    }
    
    func testConvertNegationOfBinary() {
        let inner = Node.binary(
            left: .number(1, position: pos), op: .add,
            right: .number(2, position: pos), position: pos
        )
        let node = Node.unary(op: .negate, operand: inner, position: pos)
        XCTAssertEqual(ASTToSympyConverter.convert(node), "-(1 + 2)")
    }
    
    // MARK: - Binary Operations
    
    func testConvertAddition() {
        let node = Node.binary(
            left: .number(1, position: pos), op: .add,
            right: .number(2, position: pos), position: pos
        )
        XCTAssertEqual(ASTToSympyConverter.convert(node), "1 + 2")
    }
    
    func testConvertPower() {
        let node = Node.binary(
            left: .number(2, position: pos), op: .power,
            right: .number(3, position: pos), position: pos
        )
        XCTAssertEqual(ASTToSympyConverter.convert(node), "2**3")
    }
    
    // MARK: - Functions
    
    func testConvertSin() {
        let node = Node.function(name: .sin, argument: .variable("x", position: pos), position: pos)
        XCTAssertEqual(ASTToSympyConverter.convert(node), "sin(x)")
    }
    
    func testConvertLog() {
        let node = Node.function(name: .log, argument: .number(10, position: pos), position: pos)
        XCTAssertEqual(ASTToSympyConverter.convert(node), "log(10, 10)")
    }
    
    func testConvertLn() {
        let node = Node.function(name: .ln, argument: .number(5, position: pos), position: pos)
        XCTAssertEqual(ASTToSympyConverter.convert(node), "log(5)")
    }
    
    func testConvertSqrt() {
        let node = Node.function(name: .sqrt, argument: .number(16, position: pos), position: pos)
        XCTAssertEqual(ASTToSympyConverter.convert(node), "sqrt(16)")
    }
    
    // MARK: - Complex Expressions
    
    func testConvertNestedExpression() {
        // sin(x^2 + 1)
        let innerBinary = Node.binary(
            left: .binary(left: .variable("x", position: pos), op: .power,
                          right: .number(2, position: pos), position: pos),
            op: .add,
            right: .number(1, position: pos),
            position: pos
        )
        let node = Node.function(name: .sin, argument: innerBinary, position: pos)
        let result = ASTToSympyConverter.convert(node)
        XCTAssertTrue(result.contains("sin("), "Should contain sin function")
        XCTAssertTrue(result.contains("**"), "Should use ** for power")
    }
}
