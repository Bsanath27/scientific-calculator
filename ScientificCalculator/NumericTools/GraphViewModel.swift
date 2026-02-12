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
    }
}
