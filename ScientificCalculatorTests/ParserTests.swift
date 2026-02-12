// ScientificCalculatorTests/ParserTests.swift
// Scientific Calculator - Parser Unit Tests

import XCTest
@testable import ScientificCalculator

final class ParserTests: XCTestCase {
    
    // MARK: - Basic Parsing
    
    func testParseNumber() throws {
        let result = Parser.parse("42")
        let node = try result.get()
        
        if case .number(let value, _) = node {
            XCTAssertEqual(value, 42.0)
        } else {
            XCTFail("Expected number node")
        }
    }
    
    func testParseConstant() throws {
        let node = try Parser.parse("pi").get()
        
        if case .constant(let c, _) = node {
            XCTAssertEqual(c, .pi)
        } else {
            XCTFail("Expected constant node")
        }
    }
    
    // MARK: - Binary Operations
    
    func testParseAddition() throws {
        let node = try Parser.parse("1 + 2").get()
        
        if case .binary(let left, let op, let right, _) = node {
            XCTAssertEqual(op, .add)
            if case .number(1, _) = left, case .number(2, _) = right {
                // Success
            } else {
                XCTFail("Expected number operands")
            }
        } else {
            XCTFail("Expected binary node")
        }
    }
    
    // MARK: - Operator Precedence
    
    func testPrecedenceMultiplyOverAdd() throws {
        // 2 + 3 * 4 should parse as 2 + (3 * 4)
        let node = try Parser.parse("2 + 3 * 4").get()
        
        if case .binary(let left, let op, let right, _) = node {
            XCTAssertEqual(op, .add)
            if case .number(2, _) = left {
                // Correct: 2 is left operand of +
            } else {
                XCTFail("Expected 2 as left operand")
            }
            if case .binary(_, .multiply, _, _) = right {
                // Correct: 3*4 is right operand
            } else {
                XCTFail("Expected multiply as right operand")
            }
        } else {
            XCTFail("Expected binary node")
        }
    }
    
    func testPrecedencePowerOverMultiply() throws {
        // 2 * 3 ^ 4 should parse as 2 * (3 ^ 4)
        let node = try Parser.parse("2 * 3 ^ 4").get()
        
        if case .binary(_, let op, let right, _) = node {
            XCTAssertEqual(op, .multiply)
            if case .binary(_, .power, _, _) = right {
                // Correct
            } else {
                XCTFail("Expected power as right operand")
            }
        } else {
            XCTFail("Expected binary node")
        }
    }
    
    func testRightAssociativityOfPower() throws {
        // 2 ^ 3 ^ 4 should parse as 2 ^ (3 ^ 4)
        let node = try Parser.parse("2 ^ 3 ^ 4").get()
        
        if case .binary(let left, let op, let right, _) = node {
            XCTAssertEqual(op, .power)
            if case .number(2, _) = left {
                // Correct: 2 is base
            } else {
                XCTFail("Expected 2 as base")
            }
            if case .binary(_, .power, _, _) = right {
                // Correct: 3^4 is exponent
            } else {
                XCTFail("Expected power as exponent")
            }
        } else {
            XCTFail("Expected binary node")
        }
    }
    
    // MARK: - Parentheses
    
    func testParenthesesOverridePrecedence() throws {
        // (2 + 3) * 4 should multiply sum
        let node = try Parser.parse("(2 + 3) * 4").get()
        
        if case .binary(let left, let op, _, _) = node {
            XCTAssertEqual(op, .multiply)
            if case .binary(_, .add, _, _) = left {
                // Correct: addition is left operand
            } else {
                XCTFail("Expected addition as left operand")
            }
        } else {
            XCTFail("Expected binary node")
        }
    }
    
    // MARK: - Unary Operations
    
    func testUnaryNegation() throws {
        let node = try Parser.parse("-5").get()
        
        if case .unary(let op, let operand, _) = node {
            XCTAssertEqual(op, .negate)
            if case .number(5, _) = operand {
                // Correct
            } else {
                XCTFail("Expected 5 as operand")
            }
        } else {
            XCTFail("Expected unary node")
        }
    }
    
    func testUnaryNegationInExpression() throws {
        // -2 + 3 should parse as (-2) + 3
        let node = try Parser.parse("-2 + 3").get()
        
        if case .binary(let left, .add, _, _) = node {
            if case .unary(.negate, _, _) = left {
                // Correct
            } else {
                XCTFail("Expected unary negation as left operand")
            }
        } else {
            XCTFail("Expected binary add")
        }
    }
    
    // MARK: - Functions
    
    func testParseFunctionCall() throws {
        let node = try Parser.parse("sin(0)").get()
        
        if case .function(let name, let arg, _) = node {
            XCTAssertEqual(name, .sin)
            if case .number(0, _) = arg {
                // Correct
            } else {
                XCTFail("Expected 0 as argument")
            }
        } else {
            XCTFail("Expected function node")
        }
    }
    
    func testNestedFunctions() throws {
        let node = try Parser.parse("sin(cos(0))").get()
        
        if case .function(.sin, let arg, _) = node {
            if case .function(.cos, _, _) = arg {
                // Correct
            } else {
                XCTFail("Expected nested cos")
            }
        } else {
            XCTFail("Expected sin function")
        }
    }
    
    // MARK: - AST Node Count
    
    func testNodeCount() throws {
        let node = try Parser.parse("2 + 3 * 4").get()
        XCTAssertEqual(node.nodeCount, 5)  // 2, 3, 4, *, +
    }
    
    // MARK: - Error Cases
    
    func testEmptyExpression() {
        let result = Parser.parse("")
        if case .failure(let error) = result {
            XCTAssertEqual(error, .emptyExpression)
        } else {
            XCTFail("Expected error")
        }
    }
    
    func testUnmatchedParenthesis() {
        let result = Parser.parse("(1 + 2")
        if case .failure(let error) = result {
            if case .unmatchedParenthesis = error {
                // Correct
            } else {
                XCTFail("Expected unmatchedParenthesis error, got \(error)")
            }
        } else {
            XCTFail("Expected error")
        }
    }
    
    func testMissingFunctionParenthesis() {
        let result = Parser.parse("sin 0")
        if case .failure = result {
            // Correct - should fail
        } else {
            XCTFail("Expected error for missing parenthesis")
        }
    }
    
    // MARK: - Implicit Multiplication
    
    func testImplicitMultiplication() throws {
        // "2n" -> 2 * n
        let node1 = try Parser.parse("2n").get()
        if case .binary(let left, .multiply, let right, _) = node1 {
            if case .number(2, _) = left, case .variable("n", _) = right {
                // Success
            } else {
                XCTFail("Expected 2 * n")
            }
        } else {
            XCTFail("Expected binary multiply for 2n")
        }
        
        // "2(3)" -> 2 * 3
        let node2 = try Parser.parse("2(3)").get()
        if case .binary(let left, .multiply, let right, _) = node2 {
             if case .number(2, _) = left, case .number(3, _) = right {
                 // Success
             } else {
                 XCTFail("Expected 2 * 3")
             }
         } else {
             XCTFail("Expected binary multiply for 2(3)")
         }
         
         // "(2)(3)" -> 2 * 3
         let node3 = try Parser.parse("(2)(3)").get()
         if case .binary(let left, .multiply, let right, _) = node3 {
              if case .number(2, _) = left, case .number(3, _) = right {
                  // Success
              } else {
                  XCTFail("Expected 2 * 3")
              }
          } else {
              XCTFail("Expected binary multiply for (2)(3)")
          }
    }
}
