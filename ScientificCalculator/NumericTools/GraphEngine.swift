// NumericTools/GraphEngine.swift
// Scientific Calculator - Phase 3: Graph Plotting Engine
// Uses existing Parser + NumericEngine for expression evaluation
// Parses expression once, evaluates N times with variable bindings

import Foundation

/// A single data point for plotting
struct PlotPoint: Identifiable {
    let id: Int
    let x: Double
    let y: Double
}

/// A plotted function with its data
struct PlotFunction: Identifiable {
    let id = UUID()
    let expression: String
    let points: [PlotPoint]
    let color: PlotColor
}

/// Simple color enum for plot lines
enum PlotColor: String, CaseIterable {
    case blue, red, green, orange, purple
    
    var next: PlotColor {
        let all = PlotColor.allCases
        // Use a safe lookup; in practice `self` will always be in `allCases`,
        // but this avoids any possibility of a crash if the enum changes.
        if let idx = all.firstIndex(of: self) {
            return all[(idx + 1) % all.count]
        } else {
            return .blue
        }
    }
}

/// Graph engine that samples f(x) using the existing numeric pipeline
/// Parses the expression once and evaluates with variable bindings per point
final class GraphEngine {
    private let numericEngine = NumericEngine()
    
    /// Sample a function y = f(x) over a given range
    /// The expression should contain "x" as the variable
    func sample(
        expression: String,
        xMin: Double = -10.0,
        xMax: Double = 10.0,
        pointCount: Int = 300
    ) -> NumericToolResult<[PlotPoint]> {
        // Validate user-controlled parameters defensively; on invalid ranges we
        // return an empty result with zeroed metrics rather than crashing.
        guard xMin < xMax, pointCount > 1 else {
            let metrics = NumericToolMetrics(
                executionTimeMs: 0,
                memoryUsageKB: 0,
                dataSize: 0,
                operationType: "Graph Sample"
            )
            return NumericToolResult(value: [], metrics: metrics)
        }
        
        return NumericToolRunner.run(operationType: "Graph Sample", dataSize: pointCount) {
            // Parse once
            let parseResult = Parser.parse(expression)
            
            guard case .success(let ast) = parseResult else {
                return []  // Expression cannot be parsed
            }
            
            let step = (xMax - xMin) / Double(pointCount - 1)
            var points: [PlotPoint] = []
            points.reserveCapacity(pointCount)
            
            for i in 0..<pointCount {
                let x = xMin + Double(i) * step
                
                // Evaluate AST with x binding — no re-parsing
                let context = EvaluationContext.withBindings(["x": x])
                let evalResult = self.numericEngine.evaluate(ast: ast, context: context)
                
                if let y = evalResult.doubleValue, y.isFinite {
                    points.append(PlotPoint(id: i, x: x, y: y))
                }
                // Skip non-finite values (asymptotes, domain errors)
            }
            
            return points
        }
    }
    
    /// Sample multiple functions
    func sampleMultiple(
        expressions: [String],
        xMin: Double = -10.0,
        xMax: Double = 10.0,
        pointCount: Int = 300
    ) -> NumericToolResult<[PlotFunction]> {
        let totalSize = expressions.count * pointCount
        
        return NumericToolRunner.run(operationType: "Graph Multi-Sample", dataSize: totalSize) {
            var functions: [PlotFunction] = []
            var color = PlotColor.blue
            
            for expr in expressions {
                let innerResult = self.sample(
                    expression: expr,
                    xMin: xMin,
                    xMax: xMax,
                    pointCount: pointCount
                )
                
                functions.append(PlotFunction(
                    expression: expr,
                    points: innerResult.value,
                    color: color
                ))
                
                color = color.next
            }
            
            return functions
        }
    }
}
