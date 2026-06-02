// UI/Explore/LessonDetailView.swift
// Scientific Calculator - Interactive Physics Lesson Viewer (Luxe UI)

import SwiftUI

struct LessonDetailView: View {
    let lesson: PhysicsLesson
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Hero Section
                        ZStack {
                            lesson.moduleColor.opacity(0.1)
                            
                            VStack(spacing: 16) {
                                Image(systemName: lesson.icon)
                                    .font(.system(size: 60))
                                    .foregroundColor(lesson.moduleColor)
                                
                                Text(lesson.title)
                                    .font(.system(.title, design: .serif))
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .background(theme.current.displayBackground)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            // Objectives
                            SectionView(title: "Overview") {
                                Text(lesson.description)
                                    .font(.body)
                                    .foregroundColor(theme.current.textPrimary)
                            }
                            
                            // Key Concepts
                            SectionView(title: "Key Concepts") {
                                VStack(alignment: .leading, spacing: 12) {
                                    ConceptRow(title: "Theoretical Foundation", icon: "book.fill")
                                    ConceptRow(title: "Mathematical Derivation", icon: "function")
                                    ConceptRow(title: "Real-world Application", icon: "globe")
                                }
                            }
                            
                            // Interactive Prompt
                            if let scenarioId = lesson.scenarioId {
                                VStack(spacing: 16) {
                                    Text("Ready to experiment?")
                                        .font(.headline)
                                    
                                    Button(action: {
                                        // In a real app, this would use a deep link or navigation coordinator
                                        // For this demo, we'll dismiss and suggest simulation
                                        dismiss()
                                    }) {
                                        HStack {
                                            Image(systemName: "play.fill")
                                            Text("Launch Interactive Simulation")
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(lesson.moduleColor)
                                        .cornerRadius(12)
                                        .shadow(color: lesson.moduleColor.opacity(0.3), radius: 10)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(theme.current.displayBackground)
                                .cornerRadius(16)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(theme.current.background)
            .navigationTitle(lesson.category)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.subheadline, design: .serif))
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            content
        }
    }
}

struct ConceptRow: View {
    let title: String
    let icon: String
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.current.accent)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
        }
    }
}
