// ScientificCalculator/UI/Components/ModelImportView.swift
// USDZ Library Bridge: File Import, Property Scaling, and Laboratory Loading

import SwiftUI
import UniformTypeIdentifiers

struct PhysicsModelImportView: View {
    @EnvironmentObject var viewModel: PhysicsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showFilePicker = false
    @State private var importedURL: URL?
    
    // Physics form fields
    @State private var modelName: String = "Unknown Object"
    @State private var mass: Double = 1.0
    @State private var friction: Double = 0.5
    @State private var restitution: Double = 0.8
    @State private var targetScenario: String = "collisions"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("SOURCE FILE") {
                    if let url = importedURL {
                        HStack {
                            Image(systemName: "cube.fill").foregroundColor(themeManager.current.accent)
                            Text(url.lastPathComponent).font(.system(.caption, design: .monospaced))
                            Spacer()
                            Button("Change") { showFilePicker = true }
                        }
                    } else {
                        Button { showFilePicker = true } label: {
                            Label("Select .usdz Model", systemImage: "plus.square.dashed")
                        }
                    }
                }
                
                Section("PHYSICS PROPERTIES") {
                    TextField("Model Name", text: $modelName)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Mass").font(.system(size: 11, weight: .bold))
                            Spacer()
                            Text(String(format: "%.2f kg", mass))
                        }
                        Slider(value: $mass, in: 0.1...100)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Friction").font(.system(size: 11, weight: .bold))
                            Spacer()
                            Text(String(format: "%.2f μ", friction))
                        }
                        Slider(value: $friction, in: 0...1)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Restitution").font(.system(size: 11, weight: .bold))
                            Spacer()
                            Text(String(format: "%.2f e", restitution))
                        }
                        Slider(value: $restitution, in: 0...1)
                    }
                }
                
                Section("LAB ASSIGNMENT") {
                    Picker("Target Scenario", selection: $targetScenario) {
                        ForEach(PhysicsScenario.allCases.filter { $0.rendererType == .realityKit3D || $0.id == "collisions" }) { scenario in
                            Text(scenario.title).tag(scenario.id)
                        }
                    }
                }
                
                Button {
                    loadIntoLab()
                } label: {
                    Text("Load into Laboratory")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(importedURL == nil ? Color.gray : themeManager.current.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(importedURL == nil)
                .listRowBackground(Color.clear)
            }
            .navigationTitle("IMPORT 3D MODEL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType(filenameExtension: "usdz")!],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importedURL = url
                        modelName = url.deletingPathExtension().lastPathComponent
                    }
                case .failure(let error):
                    print("Import failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadIntoLab() {
        guard let url = importedURL else { return }
        // Process model loading in ViewModel
        viewModel.importUSDZModel(url: url, scenarioId: targetScenario)
        dismiss()
    }
}
