// UI/Dashboard/DashboardView.swift
// Scientific Calculator - Scientist's Dashboard (Responsive Bento Grid)

import SwiftUI

struct DashboardView: View {
    @StateObject var viewModel = DashboardViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        GeometryReader { geo in
            let shouldStack = DeviceLayout.dashboardShouldStack(width: geo.size.width)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Top Row: Calculator & Constants
                    if shouldStack {
                        // iPhone: Stack vertically
                        VStack(spacing: 16) {
                            calculatorCard
                            DashboardConstantsCard(viewModel: viewModel)
                            DashboardUnitConverterCard()
                        }
                    } else {
                        // iPad: Side-by-side
                        HStack(alignment: .top, spacing: 16) {
                            calculatorCard
                                .frame(maxWidth: .infinity)
                            
                            VStack(spacing: 16) {
                                DashboardConstantsCard(viewModel: viewModel)
                                DashboardUnitConverterCard()
                            }
                            .frame(width: DeviceLayout.dashboardSidebarWidth(for: geo.size.width))
                        }
                    }
                    
                    // Middle Row: Variables & Live Plot
                    if shouldStack {
                        VStack(spacing: 16) {
                            variablesCard
                            plotOrTipsCard
                        }
                    } else {
                        HStack(alignment: .top, spacing: 16) {
                            variablesCard
                                .frame(maxWidth: .infinity)
                            plotOrTipsCard
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Bottom Row: Physics Lab + History
                    if shouldStack {
                        VStack(spacing: 16) {
                            physicsLabCard
                            historyCard
                        }
                    } else {
                        HStack(alignment: .top, spacing: 16) {
                            physicsLabCard
                                .frame(width: DeviceLayout.dashboardSidebarWidth(for: geo.size.width))
                            historyCard
                        }
                    }
                }
                .padding()
            }
        }
        .background(themeManager.current.background.opacity(0.1))
        .navigationTitle("Scientist's Dashboard")
    }
    
    // MARK: - Card Subviews
    
    private var calculatorCard: some View {
        DashboardCard(title: "Calculator", icon: "function") {
            VStack(spacing: 12) {
                TextField("Enter expression", text: $viewModel.expression)
                    .textFieldStyle(.plain)
                    .font(.system(.title2, design: .monospaced))
                    .padding()
                    .background(themeManager.current.background)
                    .cornerRadius(8)
                    .onSubmit { viewModel.evaluate() }
                
                if !viewModel.result.isEmpty {
                    HStack {
                        Text("= \(viewModel.result)")
                            .font(.title2)
                            .bold()
                            .foregroundColor(themeManager.current.accent)
                        Spacer()
                        Button(action: { viewModel.evaluate() }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title)
                                .foregroundColor(themeManager.current.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                    .onDrag { NSItemProvider(object: viewModel.result as NSString) }
                }
            }
        }
    }
    
    private var variablesCard: some View {
        DashboardCard(title: "Variables", icon: "cube.box") {
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.variables.isEmpty {
                    Text("Drop numbers here to define variables or type 'x = 10'")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .italic()
                } else {
                    ForEach(viewModel.variables.sorted(by: { $0.key < $1.key }), id: \.key) { name, value in
                        Button(action: { viewModel.insertText(name) }) {
                            HStack {
                                Text(name).bold()
                                Spacer()
                                Text("\(value, specifier: "%.4g")")
                                    .foregroundColor(themeManager.current.accent)
                            }
                            .padding(10)
                            .background(themeManager.current.background)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete Variable", role: .destructive) {
                                viewModel.deleteVariable(name: name)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                providers.first?.loadObject(ofClass: NSString.self) { string, _ in
                    if let s = string as? String {
                        DispatchQueue.main.async {
                            viewModel.handleDrop(resultString: s)
                        }
                    }
                }
                return true
            }
        }
    }
    
    @ViewBuilder
    private var plotOrTipsCard: some View {
        if viewModel.showPlotPreview && !viewModel.expression.contains("=") {
            DashboardPlotCard(expression: viewModel.expression)
        } else {
            DashboardCard(title: "Quick Tips", icon: "info.circle") {
                VStack(alignment: .leading, spacing: 10) {
                    TipRow(icon: "cursorarrow.click", text: "Tap variables to insert into your expression.")
                    TipRow(icon: "hand.draw", text: "Drag results into the Variable card.")
                    TipRow(icon: "chart.line.uptrend.xyaxis", text: "Type 'sin(x)' to see a live plot preview.")
                }
            }
        }
    }
    
    private var physicsLabCard: some View {
        DashboardCard(title: "Physics Lab", icon: "flask.fill") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Interactive physics simulations")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    ForEach(["arrow.up.right", "metronome", "waveform.path"], id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundColor(themeManager.current.accent)
                    }
                }
                Text("Projectile · Pendulum · Spring · Orbit")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Open from the sidebar →")
                    .font(.caption2)
                    .italic()
                    .foregroundColor(themeManager.current.accent.opacity(0.7))
            }
        }
    }
    
    private var historyCard: some View {
        DashboardCard(title: "Computational History", icon: "clock.arrow.circlepath") {
            VStack(alignment: .leading, spacing: 10) {
                if viewModel.history.isEmpty {
                    Text("Your recent calculations will appear here.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(viewModel.history) { entry in
                        Button(action: { viewModel.restoreHistory(entry) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.expression)
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Text("= \(entry.result)")
                                        .font(.headline)
                                        .foregroundColor(themeManager.current.accent)
                                }
                                Spacer()
                                Text(entry.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(themeManager.current.background.opacity(0.3))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    @EnvironmentObject var themeManager: ThemeManager
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(themeManager.current.accent)
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.current.textPrimary)
            }
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(themeManager.current.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
