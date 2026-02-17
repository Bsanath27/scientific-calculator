// ScientificCalculatorTests/NLUTests.swift
// Scientific Calculator - NLU & Spell Check Tests

import XCTest
@testable import ScientificCalculator

final class NLUTests: XCTestCase {
    
    // MARK: - Spell Check Tests
    
    func testSpellCheck() {
        // "inetgrate x" -> "integrate x"
        let misspelled1 = "inetgrate x"
        let corrected1 = NLSyntaxAnalyzer.correct(misspelled1)
        XCTAssertEqual(corrected1, "integrate x")
        
        // "dervative of x^2" -> "derivative of x^2"
        let misspelled2 = "dervative of x^2"
        let corrected2 = NLSyntaxAnalyzer.correct(misspelled2)
        XCTAssertEqual(corrected2, "derivative of x^2")
        
        // "caluclate sin of 45" -> "calculate sin of 45"
        let misspelled3 = "caluclate sin of 45"
        let corrected3 = NLSyntaxAnalyzer.correct(misspelled3)
        XCTAssertEqual(corrected3, "calculate sin of 45")
        
        // "squrt 16" -> "sqrt 16"
        let misspelled4 = "squrt 16"
        let corrected4 = NLSyntaxAnalyzer.correct(misspelled4)
        XCTAssertEqual(corrected4, "sqrt 16")
    }
    
    // MARK: - Vocabulary Translation Tests
    
    func testNewVocabulary() {
        // Factor
        let factor = NLTranslator.translate("factor x^2 - 4")
        XCTAssertEqual(factor.operation, .simplify)
        XCTAssertEqual(factor.expression, "factor(x^2-4)")
        
        // Expand
        let expand = NLTranslator.translate("expand (x+1)^2")
        XCTAssertEqual(expand.operation, .simplify)
        XCTAssertEqual(expand.expression, "expand((x+1)^2)")
        
        // Limit
        let limit = NLTranslator.translate("limit of 1/x as x approaches 0")
        XCTAssertEqual(limit.expression, "limit(1/x, x, 0)")
        
        // Statistics
        let mean = NLTranslator.translate("mean of 1, 2, 3, 4, 5")
        XCTAssertEqual(mean.expression, "mean([1, 2, 3, 4, 5])")
        
        let stddev = NLTranslator.translate("std dev of 1, 2, 3")
        XCTAssertEqual(stddev.expression, "stdev([1, 2, 3])")
        
        // Linear Algebra
        let det = NLTranslator.translate("determinant of [[1, 2], [3, 4]]")
        XCTAssertEqual(det.expression, "det([[1, 2], [3, 4]])")
        
        // Roots (synonym for solve)
        let roots = NLTranslator.translate("roots of x^2 - 1")
        XCTAssertEqual(roots.operation, .solve)
        XCTAssertEqual(roots.expression, "x^2-1")
    }
    
    func testCalculusSynonyms() {
        // "derive" synonym
        let derive = NLTranslator.translate("derive x^2")
        XCTAssertEqual(derive.operation, .differentiate)
        XCTAssertEqual(derive.expression, "x^2")
        
        // "antiderivative" synonym
        let anti = NLTranslator.translate("antiderivative of x")
        XCTAssertEqual(anti.operation, .integrate)
        XCTAssertEqual(anti.expression, "x")
    }
}
