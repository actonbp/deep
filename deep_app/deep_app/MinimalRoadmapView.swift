import SwiftUI

// MARK: - Minimal Roadmap View (Cal Newport Style)
struct MinimalRoadmapView: View {
    @ObservedObject private var todoListStore = TodoListStore.shared
    @State private var selectedProject: String?
    @State private var showAllProjects = false
    @AppStorage("roadmapViewMode") private var viewMode: RoadmapViewMode = .focused
    
    enum RoadmapViewMode: String, CaseIterable {
        case focused = "Focused"
        case overview = "Overview"
        case gamified = "Gamified"
        
        var icon: String {
            switch self {
            case .focused: return "scope"
            case .overview: return "map"
            case .gamified: return "gamecontroller"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle background
                Color.gray.opacity(0.05)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // View Mode Picker
                        ViewModePicker(selectedMode: $viewMode)
                            .padding(.horizontal)
                        
                        switch viewMode {
                        case .focused:
                            FocusedModeView(selectedProject: $selectedProject)
                        case .overview:
                            OverviewModeView()
                        case .gamified:
                            // Use existing gamified view
                            GamifiedContentView()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Roadmap")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - View Mode Picker
struct ViewModePicker: View {
    @Binding var selectedMode: MinimalRoadmapView.RoadmapViewMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(MinimalRoadmapView.RoadmapViewMode.allCases, id: \.self) { mode in
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode 
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.title3)
                        Text(mode.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedMode == mode ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedMode == mode ?
                        Color.indigo : Color.clear
                    )
                }
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Focused Mode View (Minimal, Cal Newport Style)
struct FocusedModeView: View {
    @Binding var selectedProject: String?
    @ObservedObject private var todoListStore = TodoListStore.shared
    
    // Current focus: highest priority incomplete task
    private var currentFocus: (project: String, task: TodoItem)? {
        let incompleteTasks = todoListStore.items.filter { !$0.isDone }
        guard let task = incompleteTasks.min(by: { ($0.priority ?? Int.max) < ($1.priority ?? Int.max) }) else {
            return nil
        }
        let project = task.projectOrPath ?? "Uncategorized"
        return (project, task)
    }
    
    // Active projects with incomplete tasks
    private var activeProjects: [(name: String, taskCount: Int, nextTask: TodoItem?)] {
        let grouped = Dictionary(grouping: todoListStore.items.filter { !$0.isDone }) { 
            $0.projectOrPath ?? "Uncategorized" 
        }
        
        return grouped.map { name, tasks in
            let nextTask = tasks.min(by: { ($0.priority ?? Int.max) < ($1.priority ?? Int.max) })
            return (name, tasks.count, nextTask)
        }.sorted { $0.taskCount > $1.taskCount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // The ONE Thing - Current Focus
            if let focus = currentFocus {
                CurrentFocusCard(project: focus.project, task: focus.task)
                    .padding(.horizontal)
            }
            
            // Project Pipeline - Minimal List
            VStack(alignment: .leading, spacing: 16) {
                Text("Project Pipeline")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(activeProjects.prefix(showAllProjects ? 100 : 3), id: \.name) { project in
                        MinimalProjectRow(
                            projectName: project.name,
                            taskCount: project.taskCount,
                            nextTask: project.nextTask,
                            isSelected: selectedProject == project.name,
                            onTap: {
                                withAnimation {
                                    selectedProject = selectedProject == project.name ? nil : project.name
                                }
                            }
                        )
                    }
                    
                    if activeProjects.count > 3 && !showAllProjects {
                        Button(action: { showAllProjects = true }) {
                            Text("Show \(activeProjects.count - 3) more projects...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Selected Project Deep Dive
            if let selected = selectedProject {
                ProjectDeepDive(projectName: selected)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    @State private var showAllProjects = false
}

// MARK: - Current Focus Card (The ONE Thing)
struct CurrentFocusCard: View {
    let project: String
    let task: TodoItem
    @State private var timeElapsed = 0
    @State private var isTimerRunning = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT FOCUS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(project)
                        .font(.caption)
                        .foregroundColor(.indigo)
                }
                
                Spacer()
                
                // Focus Timer
                HStack(spacing: 8) {
                    Image(systemName: isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.indigo)
                        .onTapGesture {
                            isTimerRunning.toggle()
                        }
                    
                    Text(formatTime(timeElapsed))
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.medium)
                }
            }
            
            // The Task
            Text(task.text)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Metadata Row
            HStack(spacing: 20) {
                if let duration = task.estimatedDuration {
                    Label(duration, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let difficulty = task.difficulty {
                    Label(difficulty.rawValue, systemImage: "speedometer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Deep Work Mode Toggle
                Button(action: {}) {
                    Label("Deep Work", systemImage: "brain.head.profile")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.indigo)
                        .cornerRadius(20)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if isTimerRunning {
                timeElapsed += 1
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Minimal Project Row
struct MinimalProjectRow: View {
    let projectName: String
    let taskCount: Int
    let nextTask: TodoItem?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Project Icon
                Circle()
                    .fill(isSelected ? Color.indigo : Color.gray.opacity(0.2))
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(projectName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .medium)
                        .foregroundColor(.primary)
                    
                    if let task = nextTask {
                        Text(task.text)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Task count
                Text("\(taskCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .indigo : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((isSelected ? Color.indigo : Color.gray).opacity(0.1))
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.indigo.opacity(0.05) : Color.white)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// MARK: - Project Deep Dive
struct ProjectDeepDive: View {
    let projectName: String
    @ObservedObject private var todoListStore = TodoListStore.shared
    @State private var showCompleted = false
    
    private var projectTasks: [TodoItem] {
        todoListStore.items
            .filter { $0.projectOrPath == projectName }
            .sorted { 
                if $0.isDone != $1.isDone {
                    return !$0.isDone && $1.isDone
                }
                return ($0.priority ?? Int.max) < ($1.priority ?? Int.max)
            }
    }
    
    private var incompleteTasks: [TodoItem] {
        projectTasks.filter { !$0.isDone }
    }
    
    private var completedTasks: [TodoItem] {
        projectTasks.filter { $0.isDone }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Project Header with Mission
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(projectName)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Mission Statement Placeholder
                Text("Add a mission statement to clarify your end goal...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding(.top, 12)
            
            // Task List - Numbered for Clear Progression
            VStack(alignment: .leading, spacing: 8) {
                Text("QUEST SEQUENCE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                ForEach(Array(incompleteTasks.enumerated()), id: \.element.id) { index, task in
                    HStack(alignment: .top, spacing: 12) {
                        // Sequence Number
                        Text("\(index + 1).")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.text)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            if task.estimatedDuration != nil || task.difficulty != nil {
                                HStack(spacing: 12) {
                                    if let duration = task.estimatedDuration {
                                        Text(duration)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let difficulty = task.difficulty {
                                        Text(difficulty.rawValue)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(difficulty.color)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    
                    if index < incompleteTasks.count - 1 {
                        HStack {
                            Text("↓")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            Spacer()
                        }
                    }
                }
                
                // Completed tasks toggle
                if !completedTasks.isEmpty {
                    Button(action: { withAnimation { showCompleted.toggle() } }) {
                        HStack {
                            Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                                .font(.caption)
                            Text("\(completedTasks.count) completed")
                                .font(.caption)
                            Spacer()
                        }
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    }
                    
                    if showCompleted {
                        ForEach(completedTasks) { task in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                
                                Text(task.text)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .strikethrough()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
            )
        }
    }
}

// MARK: - Overview Mode
struct OverviewModeView: View {
    @ObservedObject private var todoListStore = TodoListStore.shared
    
    var projectsSummary: [(name: String, progress: Double, phase: String)] {
        let grouped = Dictionary(grouping: todoListStore.items) { 
            $0.projectOrPath ?? "Uncategorized" 
        }
        
        return grouped.map { name, tasks in
            let completed = tasks.filter { $0.isDone }.count
            let total = tasks.count
            let progress = total > 0 ? Double(completed) / Double(total) : 0
            
            // Determine phase based on progress
            let phase: String
            if progress == 0 {
                phase = "Not Started"
            } else if progress < 0.3 {
                phase = "Early Stage"
            } else if progress < 0.7 {
                phase = "Mid Stage"
            } else if progress < 1.0 {
                phase = "Final Stage"
            } else {
                phase = "Complete"
            }
            
            return (name, progress, phase)
        }.sorted { $0.progress > $1.progress }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Summary Stats
            HStack(spacing: 40) {
                StatCard(
                    title: "Active Projects",
                    value: "\(projectsSummary.filter { $0.progress < 1.0 }.count)",
                    color: .indigo
                )
                
                StatCard(
                    title: "In Progress",
                    value: "\(projectsSummary.filter { $0.progress > 0 && $0.progress < 1.0 }.count)",
                    color: .orange
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(projectsSummary.filter { $0.progress >= 1.0 }.count)",
                    color: .green
                )
            }
            .padding(.horizontal)
            
            // Project List with Progress
            VStack(alignment: .leading, spacing: 16) {
                Text("All Projects")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ForEach(projectsSummary, id: \.name) { project in
                    ProjectProgressRow(
                        name: project.name,
                        progress: project.progress,
                        phase: project.phase
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Project Progress Row
struct ProjectProgressRow: View {
    let name: String
    let progress: Double
    let phase: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(phase)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(progress * 100))% Complete")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.7 {
            return .orange
        } else if progress >= 0.3 {
            return .blue
        } else {
            return .gray
        }
    }
}

// MARK: - Gamified Content View Wrapper
struct GamifiedContentView: View {
    var body: some View {
        // This would use the existing RoadmapView content
        // Just wrapped to fit in the new navigation structure
        VStack {
            Text("Gamified view content here")
                .foregroundColor(.secondary)
        }
    }
}