// UI/Navigation/AppNavigationView.swift
// Scientific Calculator - Main Navigation

import SwiftUI

struct AppNavigationView: View {
    @StateObject private var notebookViewModel = NotebookViewModel()
    @StateObject private var themeManager = ThemeManager()
    
    @State private var navigationSelection: NavigationItem? = .dashboard
    @State private var showNewNotebookAlert = false
    @State private var newNotebookTitle = ""
    
    enum NavigationItem: Hashable, Equatable {
        case dashboard
        case calculator
        case notebook(UUID)
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $navigationSelection) {
                Section("Tools") {
                    NavigationLink(value: NavigationItem.dashboard) {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                    NavigationLink(value: NavigationItem.calculator) {
                        Label("Calculator", systemImage: "function")
                    }
                }
                
                Section("Notebooks") {
                    ForEach(notebookViewModel.notebooks) { notebook in
                        NavigationLink(value: NavigationItem.notebook(notebook.id)) {
                            Label(notebook.title, systemImage: "book")
                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                notebookViewModel.deleteNotebook(id: notebook.id)
                            }
                        }
                    }
                    
                    Button(action: { showNewNotebookAlert = true }) {
                        Label("New Notebook", systemImage: "plus")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .navigationTitle("SciCalc")
            .listStyle(.sidebar)
            
        } detail: {
            ZStack {
                themeManager.current.background.ignoresSafeArea()
                
                switch navigationSelection {
                case .dashboard:
                    DashboardView()
                        .environmentObject(themeManager)
                    
                case .calculator:
                    ContentView()
                        .environmentObject(themeManager)
                        .environmentObject(notebookViewModel) // Pass for "Save to Notebook"
                    
                case .notebook(let id):
                    NotebookView(viewModel: notebookViewModel, themeManager: themeManager)
                        .onAppear {
                            notebookViewModel.selectNotebook(id: id)
                        }
                        .id(id) // Force refresh on switch
                    
                case .none:
                    Text("Select a tool or notebook")
                        .foregroundColor(.secondary)
                }
            }
        }
        .environmentObject(themeManager)
        .alert("New Notebook", isPresented: $showNewNotebookAlert) {
            TextField("Title", text: $newNotebookTitle)
            Button("Cancel", role: .cancel) { newNotebookTitle = "" }
            Button("Create") {
                if !newNotebookTitle.isEmpty {
                    notebookViewModel.createNotebook(title: newNotebookTitle)
                    if let id = notebookViewModel.notebooks.last?.id {
                        navigationSelection = .notebook(id)
                    }
                    newNotebookTitle = ""
                }
            }
        }
    }
}
