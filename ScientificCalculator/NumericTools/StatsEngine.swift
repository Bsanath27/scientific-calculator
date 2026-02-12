// NumericTools/StatsEngine.swift
// Scientific Calculator - Phase 3: Statistics Engine
// Uses Accelerate vDSP for high-performance statistical computation

import Foundation
import Accelerate

/// Linear regression result
struct LinearRegressionResult {
    let slope: Double
    let intercept: Double
    let rSquared: Double
    
    var description: String {
        "y = \(String(format: "%.6f", slope))x + \(String(format: "%.6f", intercept))  (R² = \(String(format: "%.6f", rSquared)))"
    }
}

/// High-performance statistics engine using vDSP
final class StatsEngine {
    
    // MARK: - Mean
    
    /// Arithmetic mean
    func mean(_ data: [Double]) -> NumericToolResult<Double> {
        precondition(!data.isEmpty, "Data must not be empty")
        
        return NumericToolRunner.run(operationType: "Stats Mean", dataSize: data.count) {
            var result: Double = 0.0
            vDSP_meanvD(data, 1, &result, vDSP_Length(data.count))
            return result
        }
    }
    
    // MARK: - Median
    
    /// Median value (sort-based)
    func median(_ data: [Double]) -> NumericToolResult<Double> {
        precondition(!data.isEmpty, "Data must not be empty")
        
        return NumericToolRunner.run(operationType: "Stats Median", dataSize: data.count) {
            let sorted = data.sorted()
            let n = sorted.count
            if n % 2 == 0 {
                return (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
            } else {
                return sorted[n / 2]
            }
        }
    }
    
    // MARK: - Variance
    
    /// Population variance
    func variance(_ data: [Double]) -> NumericToolResult<Double> {
        precondition(data.count > 1, "Variance requires at least 2 data points")
        
        return NumericToolRunner.run(operationType: "Stats Variance", dataSize: data.count) {
            var m: Double = 0.0
            vDSP_meanvD(data, 1, &m, vDSP_Length(data.count))
            
            // Subtract mean from each element
            var negMean = -m
            var centered = [Double](repeating: 0.0, count: data.count)
            vDSP_vsaddD(data, 1, &negMean, &centered, 1, vDSP_Length(data.count))
            
            // Sum of squares
            var sumSq: Double = 0.0
            vDSP_svesqD(centered, 1, &sumSq, vDSP_Length(data.count))
            
            return sumSq / Double(data.count)
        }
    }
    
    // MARK: - Standard Deviation
    
    /// Population standard deviation
    func standardDeviation(_ data: [Double]) -> NumericToolResult<Double> {
        precondition(data.count > 1, "Std deviation requires at least 2 data points")
        
        return NumericToolRunner.run(operationType: "Stats StdDev", dataSize: data.count) {
            var m: Double = 0.0
            vDSP_meanvD(data, 1, &m, vDSP_Length(data.count))
            
            var negMean = -m
            var centered = [Double](repeating: 0.0, count: data.count)
            vDSP_vsaddD(data, 1, &negMean, &centered, 1, vDSP_Length(data.count))
            
            var sumSq: Double = 0.0
            vDSP_svesqD(centered, 1, &sumSq, vDSP_Length(data.count))
            
            return sqrt(sumSq / Double(data.count))
        }
    }
    
    // MARK: - Correlation
    
    /// Pearson correlation coefficient
    func correlation(_ x: [Double], _ y: [Double]) -> NumericToolResult<Double> {
        precondition(x.count == y.count && x.count > 1, "Equal-length arrays with 2+ elements required")
        let n = x.count
        
        return NumericToolRunner.run(operationType: "Stats Correlation", dataSize: n) {
            // Compute means
            var meanX: Double = 0.0
            var meanY: Double = 0.0
            vDSP_meanvD(x, 1, &meanX, vDSP_Length(n))
            vDSP_meanvD(y, 1, &meanY, vDSP_Length(n))
            
            // Center the data
            var negMeanX = -meanX
            var negMeanY = -meanY
            var centeredX = [Double](repeating: 0.0, count: n)
            var centeredY = [Double](repeating: 0.0, count: n)
            vDSP_vsaddD(x, 1, &negMeanX, &centeredX, 1, vDSP_Length(n))
            vDSP_vsaddD(y, 1, &negMeanY, &centeredY, 1, vDSP_Length(n))
            
            // Numerator: sum(centeredX * centeredY)
            var products = [Double](repeating: 0.0, count: n)
            vDSP_vmulD(centeredX, 1, centeredY, 1, &products, 1, vDSP_Length(n))
            var sumProducts: Double = 0.0
            vDSP_sveD(products, 1, &sumProducts, vDSP_Length(n))
            
            // Denominators: sqrt(sum(centeredX^2)) * sqrt(sum(centeredY^2))
            var sumSqX: Double = 0.0
            var sumSqY: Double = 0.0
            vDSP_svesqD(centeredX, 1, &sumSqX, vDSP_Length(n))
            vDSP_svesqD(centeredY, 1, &sumSqY, vDSP_Length(n))
            
            let denominator = sqrt(sumSqX * sumSqY)
            guard denominator > 0 else { return 0.0 }
            
            return sumProducts / denominator
        }
    }
    
    // MARK: - Linear Regression
    
    /// Simple linear regression: y = slope * x + intercept
    func linearRegression(x: [Double], y: [Double]) -> NumericToolResult<LinearRegressionResult> {
        precondition(x.count == y.count && x.count > 1, "Equal-length arrays with 2+ elements required")
        let n = x.count
        
        return NumericToolRunner.run(operationType: "Stats Linear Regression", dataSize: n) {
            // Compute means
            var meanX: Double = 0.0
            var meanY: Double = 0.0
            vDSP_meanvD(x, 1, &meanX, vDSP_Length(n))
            vDSP_meanvD(y, 1, &meanY, vDSP_Length(n))
            
            // Center data
            var negMeanX = -meanX
            var negMeanY = -meanY
            var centeredX = [Double](repeating: 0.0, count: n)
            var centeredY = [Double](repeating: 0.0, count: n)
            vDSP_vsaddD(x, 1, &negMeanX, &centeredX, 1, vDSP_Length(n))
            vDSP_vsaddD(y, 1, &negMeanY, &centeredY, 1, vDSP_Length(n))
            
            // sum(centeredX * centeredY)
            var products = [Double](repeating: 0.0, count: n)
            vDSP_vmulD(centeredX, 1, centeredY, 1, &products, 1, vDSP_Length(n))
            var sumXY: Double = 0.0
            vDSP_sveD(products, 1, &sumXY, vDSP_Length(n))
            
            // sum(centeredX^2)
            var sumSqX: Double = 0.0
            vDSP_svesqD(centeredX, 1, &sumSqX, vDSP_Length(n))
            
            guard sumSqX > 0 else {
                return LinearRegressionResult(slope: 0, intercept: meanY, rSquared: 0)
            }
            
            let slope = sumXY / sumSqX
            let intercept = meanY - slope * meanX
            
            // R² = 1 - SS_res / SS_tot
            // SS_tot = sum(centeredY^2)
            var sumSqY: Double = 0.0
            vDSP_svesqD(centeredY, 1, &sumSqY, vDSP_Length(n))
            
            // Predicted values: y_hat = slope * x + intercept
            var predicted = [Double](repeating: 0.0, count: n)
            var s = slope
            vDSP_vsmulD(x, 1, &s, &predicted, 1, vDSP_Length(n))
            var inter = intercept
            vDSP_vsaddD(predicted, 1, &inter, &predicted, 1, vDSP_Length(n))
            
            // Residuals: y - predicted
            var residuals = [Double](repeating: 0.0, count: n)
            vDSP_vsubD(predicted, 1, y, 1, &residuals, 1, vDSP_Length(n))
            var ssRes: Double = 0.0
            vDSP_svesqD(residuals, 1, &ssRes, vDSP_Length(n))
            
            let rSquared = sumSqY > 0 ? 1.0 - (ssRes / sumSqY) : 0.0
            
            return LinearRegressionResult(slope: slope, intercept: intercept, rSquared: rSquared)
        }
    }
    
    // MARK: - Moving Average
    
    /// Simple moving average with given window size
    func movingAverage(_ data: [Double], windowSize: Int) -> NumericToolResult<[Double]> {
        precondition(!data.isEmpty, "Data must not be empty")
        precondition(windowSize > 0 && windowSize <= data.count, "Window size must be 1...\(data.count)")
        
        return NumericToolRunner.run(operationType: "Stats Moving Average", dataSize: data.count) {
            let resultCount = data.count - windowSize + 1
            var result = [Double](repeating: 0.0, count: resultCount)
            
            // Use vDSP sliding window mean
            // For each position, compute mean of window
            var runningSum: Double = 0.0
            let windowD = Double(windowSize)
            
            // Initial window sum
            for i in 0..<windowSize {
                runningSum += data[i]
            }
            result[0] = runningSum / windowD
            
            // Slide window
            for i in 1..<resultCount {
                runningSum += data[i + windowSize - 1] - data[i - 1]
                result[i] = runningSum / windowD
            }
            
            return result
        }
    }
    
    // MARK: - Min / Max
    
    /// Minimum value
    func min(_ data: [Double]) -> NumericToolResult<Double> {
        precondition(!data.isEmpty, "Data must not be empty")
        return NumericToolRunner.run(operationType: "Stats Min", dataSize: data.count) {
            var result: Double = 0.0
            vDSP_minvD(data, 1, &result, vDSP_Length(data.count))
            return result
        }
    }
    
    /// Maximum value
    func max(_ data: [Double]) -> NumericToolResult<Double> {
        precondition(!data.isEmpty, "Data must not be empty")
        return NumericToolRunner.run(operationType: "Stats Max", dataSize: data.count) {
            var result: Double = 0.0
            vDSP_maxvD(data, 1, &result, vDSP_Length(data.count))
            return result
        }
    }
}
