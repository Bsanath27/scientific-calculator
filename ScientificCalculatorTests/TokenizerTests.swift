// ScientificCalculatorTests/TokenizerTests.swift
// Scientific Calculator - Tokenizer Unit Tests

import XCTest
@testable import ScientificCalculator

final class TokenizerTests: XCTestCase {
    
    // MARK: - Number Tokenization
    
    func testTokenizeInteger() throws {
        var tokenizer = Tokenizer(input: "42")
        let result = try tokenizer.tokenize().get()
        
        XCTAssertEqual(result.count, 2)  // number + eof
        if case .number(let value) = result[0].token {
            XCTAssertEqual(value, 42.0)
        } else {
            XCTFail("Expected number token")
        }
    }
    
    func testTokenizeDecimal() throws {
        var tokenizer = Tokenizer(input: "3.14159")
        let result = try tokenizer.tokenize().get()
        
        if case .number(let value) = result[0].token {
            XCTAssertEqual(value, 3.14159, accuracy: 0.00001)
        } else {
            XCTFail("Expected number token")
        }
    }
    
    func testTokenizeScientificNotation() throws {
        var tokenizer = Tokenizer(input: "1.5e10")
        let result = try tokenizer.tokenize().get()
        
        if case .number(let value) = result[0].token {
            XCTAssertEqual(value, 1.5e10)
        } else {
            XCTFail("Expected number token")
        }
    }
    
    // MARK: - Operator Tokenization
    
    func testTokenizeOperators() throws {
        var tokenizer = Tokenizer(input: "+ - * / ^")
        let result = try tokenizer.tokenize().get()
        
        XCTAssertEqual(result.count, 6)  // 5 operators + eof
        XCTAssertEqual(result[0].token, .binaryOperator(.add))
        XCTAssertEqual(result[1].token, .binaryOperator(.subtract))
        XCTAssertEqual(result[2].token, .binaryOperator(.multiply))
        XCTAssertEqual(result[3].token, .binaryOperator(.divide))
        XCTAssertEqual(result[4].token, .binaryOperator(.power))
    }
    
    // MARK: - Function Tokenization
    
    func testTokenizeFunctions() throws {
        var tokenizer = Tokenizer(input: "sin cos tan log ln sqrt")
        let result = try tokenizer.tokenize().get()
        
        XCTAssertEqual(result.count, 7)  // 6 functions + eof
        XCTAssertEqual(result[0].token, .function(.sin))
        XCTAssertEqual(result[1].token, .function(.cos))
        XCTAssertEqual(result[2].token, .function(.tan))
        XCTAssertEqual(result[3].token, .function(.log))
        XCTAssertEqual(result[4].token, .function(.ln))
        XCTAssertEqual(result[5].token, .function(.sqrt))
    }
    
    // MARK: - Constant Tokenization
    
    func testTokenizeConstants() throws {
        var tokenizer = Tokenizer(input: "pi e")
        let result = try tokenizer.tokenize().get()
        
        XCTAssertEqual(result.count, 3)  // 2 constants + eof
        XCTAssertEqual(result[0].token, .constant(.pi))
        XCTAssertEqual(result[1].token, .constant(.e))
    }
    
    // MARK: - Parentheses
    
    func testTokenizeParentheses() throws {
        var tokenizer = Tokenizer(input: "(1+2)")
        let result = try tokenizer.tokenize().get()
        
        XCTAssertEqual(result.count, 6)  // ( 1 + 2 ) eof
        XCTAssertEqual(result[0].token, .leftParen)
        XCTAssertEqual(result[4].token, .rightParen)
    }
    
    // MARK: - Complex Expression
    
    func testTokenizeComplexExpression() throws {
        var tokenizer = Tokenizer(input: "sin(pi/4) + 2^10")
        let result = try tokenizer.tokenize().get()
        
        // sin ( pi / 4 ) + 2 ^ 10 eof
        XCTAssertEqual(result.count, 11)
        XCTAssertEqual(result[0].token, .function(.sin))
        XCTAssertEqual(result[1].token, .leftParen)
        XCTAssertEqual(result[2].token, .constant(.pi))
    }
    
    // MARK: - Error Cases
    
    func testTokenizeUnknownIdentifier() throws {
        var tokenizer = Tokenizer(input: "unknown")
        let result = try tokenizer.tokenize().get()
        
        // Unknown identifiers are now treated as variables
        XCTAssertEqual(result.count, 2)  // variable + eof
        XCTAssertEqual(result[0].token, .variable("unknown"))
    }
    
    // MARK: - Position Tracking
    
    func testPositionTracking() throws {
        var tokenizer = Tokenizer(input: "1 + 2")
        let result = try tokenizer.tokenize().get()
        
        XCTAssertEqual(result[0].position.offset, 0)  // '1'
        XCTAssertEqual(result[1].position.offset, 2)  // '+'
        XCTAssertEqual(result[2].position.offset, 4)  // '2'
    }
}
