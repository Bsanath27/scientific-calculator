// UI/Notebook/NotebookModel.swift
// Scientific Calculator - Notebook Data Models

import Foundation

/// Types of blocks in the notebook timeline
enum BlockType: Equatable, Codable {
    /// A mathematical calculation
    case calculation(expression: String, result: String)
    
    /// A markdown-supported text note
    case text(content: String)
    
    /// A variable definition
    case variableDefinition(name: String, value: String, expression: String)
    
    /// An error message
    case error(message: String)
}

/// A single block in the notebook timeline
struct NotebookBlock: Identifiable, Equatable, Codable {
    let id: UUID
    var type: BlockType
    let timestamp: Date
    
    init(type: BlockType, timestamp: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.timestamp = timestamp
    }
}

/// A complete notebook containing a sequence of blocks
struct Notebook: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var blocks: [NotebookBlock]
    let createdAt: Date
    
    init(id: UUID = UUID(), title: String, blocks: [NotebookBlock] = []) {
        self.id = id
        self.title = title
        self.blocks = blocks
        self.createdAt = Date()
    }
}
