// UI/Navigation/AppNavigationView.swift
// Scientific Calculator - Main Navigation with Integrated Quick Action Palette

import SwiftUI
import Combine

struct AppNavigationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var keypadContext: KeypadContextEngine
    @EnvironmentObject var palette: QuickActionPaletteState
    @EnvironmentObject var notebookViewModel: NotebookViewModel
    
    @State private var selectedTab: AppRoute = .calculate
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Calculate
            NavigationStack(path: $navigationPath) {
                ContentView()
                    .navigationDestination(for: AppRoute.self) { (route: AppRoute) in
                        destinationView(for: route)
                    }
                    .quickActionPalette()
            }
            .tabItem {
                Label("Calculate", systemImage: "function")
            }
            .tag(AppRoute.calculate as AppRoute)
            .keyboardShortcut("1", modifiers: .command)
            
            // 2. Physics Lab
            NavigationStack {
                PhysicsLabView()
                    .environmentObject(VariableStore.shared)
                    .quickActionPalette()
            }
            .tabItem {
                Label("Lab", systemImage: "flask.fill")
            }
            .tag(AppRoute.physicsLab(scenarioId: nil) as AppRoute)
            .keyboardShortcut("2", modifiers: .command)
            
            // 3. Tools
            NavigationStack {
                NumericToolsView()
                    .quickActionPalette()
            }
            .tabItem {
                Label("Tools", systemImage: "wrench.and.screwdriver")
            }
            .tag(AppRoute.tools(toolId: nil) as AppRoute)
            .keyboardShortcut("3", modifiers: .command)
            
            // 4. Workspace
            NavigationStack {
                WorkspaceView()
                    .quickActionPalette()
            }
            .tabItem {
                Label("Workspace", systemImage: "doc.text")
            }
            .tag(AppRoute.workspace(sessionId: nil) as AppRoute)
            .keyboardShortcut("4", modifiers: .command)
            
            // 5. Explore
            NavigationStack {
                ExploreView()
                    .quickActionPalette()
            }
            .tabItem {
                Label("Explore", systemImage: "safari")
            }
            .tag(AppRoute.explore(lessonId: nil) as AppRoute)
            .keyboardShortcut("5", modifiers: .command)
        }
        .accentColor(themeManager.current.accent)
        .onAppear {
            setupPalette()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToRoute"))) { notification in
            if let route = notification.object as? AppRoute {
                self.selectedTab = route
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .calculate:
            ContentView()
        case .physicsLab(let scenarioId):
            PhysicsLabView(scenarioId: scenarioId) // Needs update in PhysicsLabView
        case .tools(let toolId):
            NumericToolsView(toolId: toolId)
        case .workspace:
            WorkspaceView()
        case .explore(let lessonId):
            ExploreView(lessonId: lessonId) // Needs update in ExploreView
        }
    }
    
    private func setupPalette() {
        palette.variableStore = VariableStore.shared
        palette.onNavigate = { (route: AppRoute) in
            self.selectedTab = route
        }
        palette.onInsertExpression = { expr in
            NotificationCenter.default.post(name: NSNotification.Name("InsertExpression"), object: expr)
        }
    }
}

// MARK: - Quick Action Models

struct PaletteAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let category: ActionCategory
    let keywords: [String]
    let perform: () -> Void

    enum ActionCategory: String, CaseIterable {
        case navigation  = "Go To"
        case calculator  = "Calculate"
        case physics     = "Physics"
        case variables    = "Variables"
    }
}

@MainActor
final class QuickActionPaletteState: ObservableObject {
    @Published var isVisible: Bool = false
    @Published var query: String = ""
    @Published private(set) var results: [PaletteAction] = []
    @Published private(set) var selectedIndex: Int = 0

    var onNavigate: ((AppRoute) -> Void)?
    var onInsertExpression: ((String) -> Void)?
    var variableStore: VariableStore?

    private var allActions: [PaletteAction] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        $query
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] q in self?.filter(query: q) }
            .store(in: &cancellables)
    }

    func open() {
        buildActions()
        query = ""; results = allActions; selectedIndex = 0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { isVisible = true }
    }

    func close() { withAnimation(.easeOut(duration: 0.2)) { isVisible = false } }
    func moveDown() { if !results.isEmpty { selectedIndex = (selectedIndex + 1) % results.count } }
    func moveUp() { if !results.isEmpty { selectedIndex = (selectedIndex - 1 + results.count) % results.count } }
    func confirmSelected() { if results.indices.contains(selectedIndex) { execute(results[selectedIndex]) } }

    func execute(_ action: PaletteAction) {
        close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { action.perform() }
    }

    private func filter(query: String) {
        if query.isEmpty { results = allActions }
        else {
            let q = query.lowercased()
            results = allActions.filter { $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q) }
        }
        selectedIndex = 0
    }

    private func buildActions() {
        var actions: [PaletteAction] = []
        
        // Navigation
        actions += [
            .init(title: "Calculator", subtitle: "Main keypad", icon: "function", category: .navigation, keywords: ["home"]) { self.onNavigate?(.calculate) },
            .init(title: "Physics Lab", subtitle: "Simulations", icon: "flask.fill", category: .navigation, keywords: ["science"]) { self.onNavigate?(.physicsLab(scenarioId: nil)) },
            .init(title: "Tools Hub", subtitle: "All numeric solvers", icon: "wrench.and.screwdriver", category: .navigation, keywords: ["tools"]) { self.onNavigate?(.tools(toolId: nil)) },
            .init(title: "Workspace", subtitle: "Session timeline", icon: "doc.text.fill", category: .navigation, keywords: ["start"]) { self.onNavigate?(.workspace(sessionId: nil)) },
            .init(title: "Explore", subtitle: "Lessons", icon: "safari", category: .navigation, keywords: ["learn"]) { self.onNavigate?(.explore(lessonId: nil)) }
        ]
        
        // Specialized Tools
        actions += [
            .init(title: "Circuit Simulator", subtitle: "MNA Circuit Analysis", icon: "square.dashed", category: .physics, keywords: ["ee", "circuit"]) { self.onNavigate?(.tools(toolId: "circuit")) },
            .init(title: "Logic Gate Simulator", subtitle: "Bitwise Operations", icon: "cpu", category: .physics, keywords: ["cs", "logic"]) { self.onNavigate?(.tools(toolId: "logic")) },
            .init(title: "Matrix Solver", subtitle: "Linear Algebra", icon: "grid", category: .calculator, keywords: ["math"]) { self.onNavigate?(.tools(toolId: "matrix")) },
            .init(title: "Vector Operations", subtitle: "Dot/Cross Product", icon: "arrow.up.right", category: .calculator, keywords: ["math"]) { self.onNavigate?(.tools(toolId: "vector")) }
        ]
        
        for s in PhysicsScenario.allCases {
            actions.append(.init(title: "Simulate: \(s.title)", subtitle: s.description, icon: s.icon, category: .physics, keywords: ["physics"]) {
                self.onNavigate?(.physicsLab(scenarioId: s.id))
                NotificationCenter.default.post(name: Notification.Name("SelectPhysicsScenario"), object: s)
            })
        }

        allActions = actions
    }
}

// MARK: - View Overlays

struct QuickActionPaletteOverlay: View {
    @EnvironmentObject var state: QuickActionPaletteState
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        if state.isVisible {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { state.close() }
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("Type a command...", text: $state.query).textFieldStyle(.plain)
                            .onSubmit { state.confirmSelected() }
                    }
                    .padding().background(themeManager.current.surface.opacity(0.8))
                    Divider()
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(state.results.enumerated()), id: \.element.id) { index, action in
                                ActionRow(action: action, isSelected: index == state.selectedIndex)
                                    .onTapGesture { state.execute(action) }
                            }
                        }
                    }.frame(maxHeight: 400)
                }
                .frame(maxWidth: 500).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                .padding().shadow(radius: 20).transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

struct ActionRow: View {
    let action: PaletteAction; let isSelected: Bool
    var body: some View {
        HStack {
            Image(systemName: action.icon).frame(width: 24)
            VStack(alignment: .leading) {
                Text(action.title).fontWeight(isSelected ? .bold : .regular)
                Text(action.subtitle).font(.caption).opacity(0.8)
            }
            Spacer()
        }
        .padding(8).background(isSelected ? Color.accentColor : Color.clear).cornerRadius(8)
        .foregroundColor(isSelected ? .white : .primary).contentShape(Rectangle())
    }
}

extension View {
    func quickActionPalette() -> some View { modifier(QuickActionPaletteModifier()) }
}

struct QuickActionPaletteModifier: ViewModifier {
    @EnvironmentObject var state: QuickActionPaletteState
    func body(content: Content) -> some View { content.overlay(QuickActionPaletteOverlay()) }
}
