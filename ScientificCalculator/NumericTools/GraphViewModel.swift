// NumericTools/GraphViewModel.swift
// Scientific Calculator - Phase 3: Graph State Management

import Foundation
import Combine

/// ViewModel for graph plotting UI
final class GraphViewModel: ObservableObject {
    @Published var expression: String = "sin(x)"
    @Published var expressions: [String] = []
    @Published var plotFunctions: [PlotFunction] = []
    @Published var xMin: Double = -10.0
    @Published var xMax: Double = 10.0
    @Published var pointCount: Int = 300
    @Published var isPlotting: Bool = false
    @Published var metricsText: String = ""
    @Published var errorMessage: String = ""
    
    private let graphEngine = GraphEngine()
    
    /// Plot single expression
    func plot() {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isPlotting = true
        errorMessage = ""
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let result = self.graphEngine.sample(
                expression: self.expression,
                xMin: self.xMin,
                xMax: self.xMax,
                pointCount: self.pointCount
            )
            
            DispatchQueue.main.async {
                self.isPlotting = false
                
                if result.value.isEmpty {
                    self.errorMessage = "No valid points generated. Check expression syntax."
                    self.plotFunctions = []
                } else {
                    let fn = PlotFunction(
                        expression: self.expression,
                        points: result.value,
                        color: .blue
                    )
                    self.plotFunctions = [fn]
                    self.metricsText = """
                    Points: \(result.value.count)
                    Time: \(String(format: "%.2f", result.metrics.executionTimeMs)) ms
                    Memory: \(String(format: "%.2f", result.metrics.memoryUsageKB)) KB
                    """
                }
            }
        }
    }
    
    /// Add expression to multi-plot list
    func addExpression() {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty && !expressions.contains(trimmed) else { return }
        expressions.append(trimmed)
    }
    
    /// Remove expression from multi-plot list
    func removeExpression(_ expr: String) {
        expressions.removeAll { $0 == expr }
    }
    
    /// Plot all expressions
    func plotAll() {
        guard !expressions.isEmpty else { return }
        
        isPlotting = true
        errorMessage = ""
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let result = self.graphEngine.sampleMultiple(
                expressions: self.expressions,
                xMin: self.xMin,
                xMax: self.xMax,
                pointCount: self.pointCount
            )
            
            DispatchQueue.main.async {
                self.isPlotting = false
                self.plotFunctions = result.value
                self.metricsText = """
                Functions: \(result.value.count)
                Time: \(String(format: "%.2f", result.metrics.executionTimeMs)) ms
                Memory: \(String(format: "%.2f", result.metrics.memoryUsageKB)) KB
                """
            }
        }
    }
    
    @Published var selectedPoint: GraphAnnotation?
    
    /// Reset to defaults
    func reset() {
        expression = "sin(x)"
        expressions = []
        plotFunctions = []
        xMin = -10.0
        xMax = 10.0
        pointCount = 300
        metricsText = ""
        errorMessage = ""
        selectedPoint = nil
    }
    
    /// Annotate a point at X
    func annotate(at x: Double) {
        guard let firstFn = plotFunctions.first else { return }
        
        // Find closest point in data
        let points = firstFn.points
        guard !points.isEmpty else { return }
        
        let closestIndex = points.enumerated().min(by: { abs($0.1.x - x) < abs($1.1.x - x) })?.offset ?? 0
        let p = points[closestIndex]
        
        // Numerical Differentiation (Central Difference where possible)
        let slope: Double
        if closestIndex > 0 && closestIndex < points.count - 1 {
            let pNext = points[closestIndex + 1]
            let pPrev = points[closestIndex - 1]
            slope = (pNext.y - pPrev.y) / (pNext.x - pPrev.x)
        } else if closestIndex < points.count - 1 {
            let pNext = points[closestIndex + 1]
            slope = (pNext.y - p.y) / (pNext.x - p.x)
        } else if closestIndex > 0 {
            let pPrev = points[closestIndex - 1]
            slope = (p.y - pPrev.y) / (p.x - pPrev.x)
        } else {
            slope = 0
        }
        
        // Numerical Integration (Trapezoidal rule from xMin to current x)
        var area: Double = 0
        for i in 0..<closestIndex {
            let p1 = points[i]
            let p2 = points[i+1]
            area += (p1.y + p2.y) * (p2.x - p1.x) / 2.0
        }
        
        selectedPoint = GraphAnnotation(
            expression: firstFn.expression,
            x: p.x,
            y: p.y,
            slope: slope,
            area: area
        )
    }
}

/// Information about a selected point on the graph
struct GraphAnnotation: Identifiable {
    let id = UUID()
    let expression: String
    let x: Double
    let y: Double
    let slope: Double
    let area: Double
}
