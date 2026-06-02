// UI/Explore/ExploreView.swift
import SwiftUI

struct PhysicsLesson: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let description: String
    let icon: String
    let moduleColor: Color
    let scenarioId: String? // Link to a simulation
}

struct ExploreView: View {
    let lessonId: String?
    @EnvironmentObject var theme: ThemeManager
    @State private var selectedLesson: PhysicsLesson?
    
    init(lessonId: String? = nil) {
        self.lessonId = lessonId
    }
    
    let lessons = [
        PhysicsLesson(title: "Projectile Motion", category: "Mechanics", description: "Master the trajectory of objects under gravity.", icon: "arrow.up.right.circle", moduleColor: .blue, scenarioId: "projectile"),
        PhysicsLesson(title: "Simple Harmonic Motion", category: "Mechanics", description: "Explore pendulums and mass-spring systems.", icon: "waveform.path.ecg", moduleColor: .blue, scenarioId: "pendulum"),
        PhysicsLesson(title: "Circuit Analysis", category: "Electromagnetism", description: "Understand AC/DC circuits and MNA solvers.", icon: "bolt.ring.closed", moduleColor: .orange, scenarioId: nil),
        PhysicsLesson(title: "Wave Interference", category: "Waves", description: "Visualize the superposition of wave functions.", icon: "wave.3.forward", moduleColor: .purple, scenarioId: "wave_superposition"),
        PhysicsLesson(title: "Bohr Model", category: "Quantum", description: "Study electron transitions and energy levels.", icon: "atom", moduleColor: .red, scenarioId: "bohr_model"),
        PhysicsLesson(title: "Thermodynamics", category: "Fluids", description: "Analyze the behavior of ideal gases.", icon: "thermometer.medium", moduleColor: .green, scenarioId: "ideal_gas")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Explore Physica")
                        .font(.system(.title2, design: .serif))
                        .fontWeight(.bold)
                    Text("Guided Lessons & Calculator Tutorials")
                        .font(.caption)
                        .foregroundColor(theme.current.textSecondary)
                }
                Spacer()
            }
            .padding()
            .background(theme.current.displayBackground)
            
            Divider()
                .background(theme.current.divider)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 20) {
                    ForEach(lessons) { lesson in
                        LessonCard(lesson: lesson, selectedLesson: $selectedLesson)
                    }
                }
                .padding()
            }
        }
        .background(theme.current.background)
        .onAppear {
            if let lessonId = lessonId {
                selectedLesson = lessons.first(where: { $0.title.lowercased().contains(lessonId.lowercased()) })
            }
        }
        .sheet(item: $selectedLesson) { lesson in
            LessonDetailView(lesson: lesson)
        }
    }
}

struct LessonCard: View {
    let lesson: PhysicsLesson
    @Binding var selectedLesson: PhysicsLesson?
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        Button(action: { selectedLesson = lesson }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(lesson.moduleColor.opacity(0.1))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: lesson.icon)
                            .font(.title2)
                            .foregroundColor(lesson.moduleColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lesson.category.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(lesson.moduleColor)
                        Text(lesson.title)
                            .font(.headline)
                            .foregroundColor(theme.current.textPrimary)
                    }
                }
                
                Text(lesson.description)
                    .font(.subheadline)
                    .foregroundColor(theme.current.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text("Start Lesson")
                        .font(.caption.bold())
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                }
                .foregroundColor(lesson.moduleColor)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.current.displayBackground.opacity(0.5))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.current.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
