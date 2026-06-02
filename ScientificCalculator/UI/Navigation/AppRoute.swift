// UI/Navigation/AppRoute.swift
// Physica - Unified Navigation Routing

import SwiftUI
import Foundation

enum AppRoute: Hashable, Identifiable {
    case calculate
    case physicsLab(scenarioId: String? = nil)
    case tools(toolId: String? = nil)
    case workspace(sessionId: UUID? = nil)
    case explore(lessonId: String? = nil)
    
    var id: String {
        switch self {
        case .calculate: return "calculate"
        case .physicsLab(let sid): return "lab-\(sid ?? "root")"
        case .tools(let tid): return "tools-\(tid ?? "root")"
        case .workspace(let wid): return "ws-\(wid?.uuidString ?? "root")"
        case .explore(let eid): return "explore-\(eid ?? "root")"
        }
    }
}
