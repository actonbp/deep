import SwiftUI

struct RoadmapView: View {
    // Access the shared store
    @ObservedObject private var todoListStore = TodoListStore.shared
    @State private var selectedProject: String? = nil
    @State private var showLevelUpAnimation = false
    @State private var newlyCompletedTasks: Set<UUID> = []
    @State private var showingQuestMap = false
    @State private var questMapProject: ProjectData? = nil
    // NEW: Advanced editing functionality
    @AppStorage(AppSettings.advancedRoadmapEditingKey) private var advancedRoadmapEditing: Bool = false
    @State private var showingProjectEditor = false
    @State private var editingProject: ProjectData? = nil
    @State private var showingProjectCreator = false
    
    // Consistent title styling
    let titleFontSize: CGFloat = 22 
    let sciFiFont = "Orbitron"

    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                AnimatedGameBackground()
                
                ScrollView {
                    // Consistent layout for all iOS versions - simplified for stability
                    VStack(spacing: 20) {
                        // Hero Stats Section
                        HeroStatsCard(projects: projectData)
                            .padding(.horizontal)
                        
                        // Quest Boards
                        VStack(spacing: 16) {
                            ForEach(projectData.sorted(by: { $0.progress > $1.progress }), id: \.title) { project in
                                QuestBoardCard(
                                    project: project,
                                    isExpanded: false // No longer using expand functionality
                                )
                                .onTapGesture {
                                    // Open quest map for this project
                                    questMapProject = project
                                    showingQuestMap = true
                                }
                                .onLongPressGesture {
                                    // Long press to edit project (if advanced editing enabled)
                                    if advancedRoadmapEditing {
                                        editingProject = project
                                        showingProjectEditor = true
                                    }
                                }
                                .contextMenu {
                                    if advancedRoadmapEditing {
                                        Button {
                                            editingProject = project
                                            showingProjectEditor = true
                                        } label: {
                                            Label("Edit Project", systemImage: "pencil")
                                        }
                                        
                                        Button {
                                            questMapProject = project
                                            showingQuestMap = true
                                        } label: {
                                            Label("View Quest Map", systemImage: "map")
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Empty state
                        if projectData.isEmpty {
                            EmptyQuestState()
                                .padding(.top, 40)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .onAppear {
                // Generate smart emojis for projects that don't have them
                self.generateSmartEmojisIfNeeded()
            }
            .navigationTitle("Quest Hub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.indigo, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar) 
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("⚔️")
                            .font(.title2)
                        Text("Quest Hub")
                            .font(.custom(sciFiFont, size: titleFontSize))
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.titleText)
                    }
                }
                
                if advancedRoadmapEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingProjectCreator = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingQuestMap) {
            if let project = questMapProject {
                QuestMapView(project: project)
            }
        }
        .sheet(isPresented: $showingProjectEditor) {
            if let project = editingProject {
                ProjectEditorView(project: project, todoListStore: todoListStore)
            }
        }
        .sheet(isPresented: $showingProjectCreator) {
            ProjectCreatorView(todoListStore: todoListStore)
        }
    }
    
    // Convert tasks into project data
    private var projectData: [ProjectData] {
        let groupedByProject = Dictionary(grouping: todoListStore.items) { item in
            item.projectOrPath ?? "Uncategorized Quests"
        }
        
        return groupedByProject.map { projectName, tasks in
            let completedTasks = tasks.filter { $0.isDone }.count
            let totalTasks = tasks.count
            let progress = totalTasks > 0 ? max(0.0, min(1.0, Double(completedTasks) / Double(totalTasks))) : 0.0
            let level = min(15, max(1, (completedTasks / 2) + 1))
            let xp = completedTasks * 15
            let projectType = tasks.first?.projectType ?? .personal
            
            // Get AI-generated emoji or fall back to type icon
            let customEmoji = UserDefaults.standard.string(forKey: "projectEmoji_\(projectName)")
            let emoji = customEmoji ?? projectType.icon
            
            // Debug emoji selection
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [RoadmapView]: Project '\(projectName)' using emoji: \(emoji) (custom: \(customEmoji ?? "none"), type: \(projectType.icon))")
            }
            
            // Next task is the highest priority incomplete task
            let nextTask = tasks
                .filter { !$0.isDone }
                .sorted { ($0.priority ?? Int.max) < ($1.priority ?? Int.max) }
                .first
            
            // Calculate rank based on progress and level
            let rank = calculateRank(level: level, progress: progress)
            
            return ProjectData(
                title: projectName,
                type: projectType,
                tasks: tasks,
                completedCount: completedTasks,
                totalCount: totalTasks,
                progress: progress,
                level: level,
                xp: xp,
                nextTask: nextTask,
                emoji: emoji,
                rank: rank
            )
        }
    }
    
    private func calculateRank(level: Int, progress: Double) -> String {
        switch level {
        case 1...3: return progress > 0.8 ? "🥉 Bronze" : "⚪ Novice"
        case 4...6: return progress > 0.8 ? "🥈 Silver" : "🟡 Apprentice"
        case 7...10: return progress > 0.8 ? "🥇 Gold" : "🔵 Expert"
        case 11...15: return progress > 0.8 ? "💎 Platinum" : "🟣 Master"
        default: return "🏆 Legend"
        }
    }
    
    // Generate smart emojis for projects that don't have custom ones
    private func generateSmartEmojisIfNeeded() {
        let uniqueProjects = Set(todoListStore.items.compactMap { $0.projectOrPath })
        var projectsNeedingEmojis: [String] = []
        
        for project in uniqueProjects {
            let key = "projectEmoji_\(project)"
            if UserDefaults.standard.string(forKey: key) == nil {
                projectsNeedingEmojis.append(project)
            }
        }
        
        if !projectsNeedingEmojis.isEmpty {
            // Generate suggested emojis based on project names
            var suggestions: [(String, String)] = []
            
            for project in projectsNeedingEmojis {
                let emoji = suggestEmoji(for: project)
                suggestions.append((project, emoji))
                // Store the suggestion immediately so it shows up
                UserDefaults.standard.set(emoji, forKey: "projectEmoji_\(project)")
            }
            
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [RoadmapView]: Generated smart emojis for projects: \(suggestions)")
            }
        }
    }
    
    // Regenerate all project emojis (useful for asking AI to update them)
    private func regenerateAllEmojis() {
        let uniqueProjects = Set(todoListStore.items.compactMap { $0.projectOrPath })
        
        // Clear existing emojis
        for project in uniqueProjects {
            let key = "projectEmoji_\(project)"
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Generate new ones
        generateSmartEmojisIfNeeded()
        
        print("DEBUG [RoadmapView]: Regenerated emojis for all projects")
    }
    
    // Smart emoji suggestion based on project name
    private func suggestEmoji(for projectName: String) -> String {
        let name = projectName.lowercased()
        
        // Academic/Research patterns
        if name.contains("paper") || name.contains("manuscript") || name.contains("journal") || name.contains("publication") {
            return "📄"
        }
        if name.contains("nsf") || name.contains("grant") || name.contains("award") || name.contains("funding") {
            return "🏆"
        }
        if name.contains("course") || name.contains("class") || name.contains("teaching") || name.contains("student") {
            return "🎓"
        }
        if name.contains("conference") || name.contains("presentation") || name.contains("talk") {
            return "🎤"
        }
        if name.contains("research") || name.contains("study") || name.contains("analysis") {
            return "🔬"
        }
        
        // Personal/Life patterns
        if name.contains("friend") || name.contains("social") || name.contains("relationship") {
            return "👥"
        }
        if name.contains("health") || name.contains("fitness") || name.contains("medical") || name.contains("doctor") {
            return "💚"
        }
        if name.contains("travel") || name.contains("vacation") || name.contains("trip") {
            return "✈️"
        }
        if name.contains("shopping") || name.contains("grocery") || name.contains("buy") {
            return "🛒"
        }
        if name.contains("home") || name.contains("house") || name.contains("apartment") {
            return "🏠"
        }
        if name.contains("car") || name.contains("vehicle") || name.contains("transport") {
            return "🚗"
        }
        
        // Work patterns
        if name.contains("work") || name.contains("job") || name.contains("career") || name.contains("office") {
            return "💼"
        }
        if name.contains("meeting") || name.contains("client") || name.contains("business") {
            return "🤝"
        }
        if name.contains("project") || name.contains("development") || name.contains("software") {
            return "💻"
        }
        
        // Learning patterns
        if name.contains("learn") || name.contains("skill") || name.contains("tutorial") || name.contains("book") {
            return "📚"
        }
        
        // Financial patterns
        if name.contains("finance") || name.contains("money") || name.contains("budget") || name.contains("tax") {
            return "💰"
        }
        
        // Creative patterns
        if name.contains("art") || name.contains("design") || name.contains("creative") || name.contains("music") {
            return "🎨"
        }
        
        // Default fallback based on project type
        return "🚀"
    }
    
}

// MARK: - Data Models
struct ProjectData {
    let title: String
    let type: ProjectType
    let tasks: [TodoItem]
    let completedCount: Int
    let totalCount: Int
    let progress: Double
    let level: Int
    let xp: Int
    let nextTask: TodoItem?
    let emoji: String
    let rank: String
}

// MARK: - Animated Background
struct AnimatedGameBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.indigo.opacity(0.1),
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.1)
                ]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            // Floating particles
            ForEach(0..<5, id: \.self) { i in
                FloatingParticle(delay: Double(i) * 0.8)
            }
        }
    }
}

struct FloatingParticle: View {
    let delay: Double
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.05))
            .frame(width: 3, height: 3)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 4).delay(delay).repeatForever(autoreverses: true)) {
                    offset = -60
                    opacity = 0.3
                }
            }
    }
}

// MARK: - Hero Stats Card
struct HeroStatsCard: View {
    let projects: [ProjectData]
    @State private var animateXP = false
    
    private var totalXP: Int {
        projects.reduce(0) { $0 + $1.xp }
    }
    
    private var totalCompleted: Int {
        projects.reduce(0) { $0 + $1.completedCount }
    }
    
    private var totalTasks: Int {
        projects.reduce(0) { $0 + $1.totalCount }
    }
    
    private var overallLevel: Int {
        min(25, max(1, totalXP / 75))
    }
    
    private var nextLevelXP: Int {
        (overallLevel + 1) * 75
    }
    
    private var xpProgress: Double {
        let currentLevelXP = overallLevel * 75
        let xpInCurrentLevel = max(0, totalXP - currentLevelXP)
        let xpNeededForLevel = 75
        guard xpNeededForLevel > 0 else { return 0.0 }
        return max(0.0, min(1.0, Double(xpInCurrentLevel) / Double(xpNeededForLevel)))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Hero Level Badge
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.yellow.opacity(0.3),
                                Color.orange.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 30,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateXP ? 1.1 : 1.0)
                
                // Main badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.yellow,
                                    Color.orange,
                                    Color.red
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    VStack(spacing: 2) {
                        Text("Lv")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.titleText)
                        Text("\(overallLevel)")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(Color.theme.titleText)
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateXP = true
                }
            }
            
            // XP Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("⚡ \(totalXP) XP")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("Next: \(nextLevelXP)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // Animated progress bar
                GeometryReader { geometry in
                    // Ensure geometry has valid dimensions
                    let safeWidth = max(1, geometry.size.width)
                    let safeHeight = max(1, geometry.size.height)
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.yellow,
                                        Color.orange
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, safeWidth * max(0, min(1, xpProgress))), height: 12)
                            .overlay(
                                // Shimmer effect
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.0),
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.0)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .mask(RoundedRectangle(cornerRadius: 8))
                            )
                    }
                }
                .frame(height: 12)
            }
            
            // Achievement Stats
            HStack(spacing: 24) {
                StatBadge(icon: "🏆", value: "\(totalCompleted)", label: "Completed")
                StatBadge(icon: "🎯", value: "\(totalTasks)", label: "Total Quests")
                StatBadge(icon: "📈", value: "\(projects.count)", label: "Active Boards")
            }
        }
        .padding(20)
        .conditionalGlassBackground(Color.white, opacity: 0.1, in: RoundedRectangle(cornerRadius: 20))
        .conditionalGlassEffect(in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            // Border glow
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.yellow.opacity(0.5),
                            Color.orange.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quest Board Card
struct QuestBoardCard: View {
    let project: ProjectData
    let isExpanded: Bool
    @State private var pulseGlow = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main quest board
            VStack(spacing: 16) {
                // Header with smart emoji
                HStack(alignment: .top) {
                    // AI-generated emoji icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        project.type.color.opacity(0.3),
                                        project.type.color.opacity(0.1)
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)
                            .scaleEffect(pulseGlow ? 1.1 : 1.0)
                        
                        Text(project.emoji)
                            .font(.title)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            pulseGlow = true
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.title)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            // Level with metallic effect
                            HStack(spacing: 4) {
                                Text("⚔️")
                                    .font(.caption)
                                Text("Lv \(project.level)")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.black)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                project.type.color,
                                                project.type.color.opacity(0.7)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .foregroundColor(Color.theme.titleText)
                            .shadow(color: project.type.color.opacity(0.5), radius: 2, x: 0, y: 1)
                            
                            // Rank badge
                            Text(project.rank)
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    
                    Spacer()
                    
                    // XP with glow
                    VStack {
                        Text("💎")
                            .font(.title3)
                        Text("\(project.xp)")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(project.type.color)
                    }
                    
                    // Quest Map indicator
                    VStack(spacing: 2) {
                        Image(systemName: "map")
                            .font(.title3)
                            .foregroundColor(project.type.color)
                        Text("Quest Map")
                            .font(.caption2)
                            .foregroundColor(project.type.color)
                    }
                }
                
                // Epic progress bar
                VStack(spacing: 10) {
                    GeometryReader { geometry in
                        // Ensure geometry has valid dimensions
                        let safeWidth = max(1, geometry.size.width)
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 16)
                            
                            // Progress fill with animation
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            project.type.color,
                                            project.type.color.opacity(0.8),
                                            project.type.color
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, safeWidth * max(0, min(1, project.progress))), height: 16)
                                .overlay(
                                    // Animated shimmer
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.0),
                                                    Color.white.opacity(0.6),
                                                    Color.white.opacity(0.0)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .offset(x: pulseGlow ? safeWidth : -safeWidth)
                                        .mask(RoundedRectangle(cornerRadius: 8))
                                )
                        }
                    }
                    .frame(height: 16)
                    
                    // Progress stats
                    HStack {
                        HStack(spacing: 6) {
                            Text("⚡")
                                .font(.system(.caption, design: .rounded))
                            Text("\(project.completedCount)/\(project.totalCount) Quests")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(project.progress * 100))% Complete")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.titleText)
                    }
                }
                
                // Next quest preview
                if !isExpanded, let nextTask = project.nextTask {
                    HStack(spacing: 8) {
                        Text("🎯")
                            .font(.caption)
                        Text("Next Quest:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(nextTask.text)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(12)
                    .background(project.type.color.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(20)
            .conditionalGlassBackground(Color.white, opacity: 0.08, in: RoundedRectangle(cornerRadius: 20))
            .conditionalGlassEffect(in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                // Glowing border for high progress
                Group {
                    if project.progress > 0.8 {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.yellow.opacity(0.8),
                                        Color.orange.opacity(0.6),
                                        Color.yellow.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .shadow(color: Color.yellow.opacity(0.5), radius: 8, x: 0, y: 0)
                    }
                }
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}


// MARK: - Empty State
struct EmptyQuestState: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🗺️")
                .font(.system(size: 80))
            
            Text("No Active Quests")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add tasks with projects to begin your epic journey!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Extensions
extension ProjectType {
    var color: Color {
        switch self {
        case .work: return Color("ProjectBlue")
        case .personal: return Color("ProjectPurple")
        case .health: return Color("ProjectGreen")
        case .learning: return Color("ProjectYellow")
        }
    }
}

extension Difficulty {
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟡"  
        case .high: return "🔴"
        }
    }
}

// MARK: - Quest Map View (Adventure Game Style)
struct QuestMapView: View {
    let project: ProjectData
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTaskId: UUID?
    
    // Sort tasks by priority to create logical progression (adventure game style)
    private var questSequence: [TodoItem] {
        project.tasks.sorted { task1, task2 in
            // Sort by priority to show logical progression, regardless of completion
            return (task1.priority ?? Int.max) < (task2.priority ?? Int.max)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adventure map background
                LinearGradient(
                    colors: [
                        Color.indigo.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.blue.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    // Simple consistent layout for all iOS versions
                    VStack(spacing: 32) {
                        // Project header
                        VStack(spacing: 16) {
                            Text(project.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("\(project.tasks.filter { $0.isDone }.count) of \(project.tasks.count) completed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        // Quest path - simple chronological list
                        VStack(spacing: 16) {
                            ForEach(Array(questSequence.enumerated()), id: \.element.id) { index, quest in
                                HStack(spacing: 16) {
                                    // Quest number
                                    Text("\(index + 1)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(quest.isDone ? .green : .blue)
                                        )
                                    
                                    // Quest details
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(quest.text)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                            .strikethrough(quest.isDone)
                                        
                                        if let duration = quest.estimatedDuration {
                                            Text("⏱️ \(duration)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if quest.isDone {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title2)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                                .onTapGesture {
                                    selectedTaskId = quest.id
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Current focus
                        if let nextQuest = questSequence.first(where: { !$0.isDone }) {
                            VStack(spacing: 12) {
                                Text("🎯 Current Quest")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text(nextQuest.text)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.blue.opacity(0.1))
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Quest Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.indigo)
                }
            }
        }
    }
}

// MARK: - Project Header
struct ProjectHeader: View {
    let project: ProjectData
    
    var body: some View {
        VStack(spacing: 16) {
            // Project icon and title
            HStack(spacing: 16) {
                Text(project.emoji)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Mission: [Add your end goal here]")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Spacer()
            }
            
            // Progress overview
            HStack(spacing: 24) {
                StatPill(
                    icon: "🎯",
                    label: "Progress",
                    value: "\(Int(project.progress * 100))%"
                )
                
                StatPill(
                    icon: "⚡",
                    label: "Completed",
                    value: "\(project.completedCount)/\(project.totalCount)"
                )
                
                StatPill(
                    icon: "🏆",
                    label: "Level",
                    value: "\(project.level)"
                )
            }
        }
        .padding(20)
        .conditionalGlassBackground(Color.white, opacity: 0.1, in: RoundedRectangle(cornerRadius: 16))
        .conditionalGlassEffect(in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title3)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quest Path (Adventure Game Style)
struct QuestPath: View {
    let quests: [TodoItem]
    @Binding var selectedTaskId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🗺️ Quest Sequence")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                ForEach(Array(quests.enumerated()), id: \.element.id) { index, quest in
                    QuestStep(
                        quest: quest,
                        stepNumber: index + 1,
                        isSelected: selectedTaskId == quest.id,
                        isLast: index == quests.count - 1,
                        allQuests: quests,
                        onTap: { selectedTaskId = quest.id }
                    )
                }
            }
        }
        .padding(20)
        .conditionalGlassBackground(Color.white, opacity: 0.05, in: RoundedRectangle(cornerRadius: 16))
        .conditionalGlassEffect(in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Quest Step
struct QuestStep: View {
    let quest: TodoItem
    let stepNumber: Int
    let isSelected: Bool
    let isLast: Bool
    let allQuests: [TodoItem]
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Quest node and info
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // Step number/status circle
                    ZStack {
                        Circle()
                            .fill(quest.isDone ? Color.green : Color.indigo)
                            .frame(width: 40, height: 40)
                        
                        if quest.isDone {
                            Image(systemName: "checkmark")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        } else {
                            Text("\(stepNumber)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .shadow(color: isSelected ? Color.indigo.opacity(0.5) : .clear, radius: 8)
                    
                    // Quest details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quest.text)
                            .font(.subheadline)
                            .fontWeight(quest.isDone ? .regular : .semibold)
                            .foregroundColor(quest.isDone ? .secondary : .primary)
                            .strikethrough(quest.isDone)
                            .multilineTextAlignment(.leading)
                        
                        // Metadata
                        HStack(spacing: 12) {
                            if let difficulty = quest.difficulty {
                                Label(difficulty.rawValue, systemImage: "speedometer")
                                    .font(.caption2)
                                    .foregroundColor(difficulty.color)
                            }
                            
                            if let duration = quest.estimatedDuration {
                                Label(duration, systemImage: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    if quest.isDone {
                        Text("✅ Complete")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    } else if !quest.isDone && allQuests.first(where: { !$0.isDone })?.id == quest.id {
                        Text("🔥 Current")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    } else {
                        Text("⏳ Upcoming")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Connection line to next quest
            if !isLast {
                HStack {
                    Spacer()
                        .frame(width: 20) // Align with circle center
                    
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 2, height: 20)
                    }
                    
                    Spacer()
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Current Quest Focus
struct CurrentQuestFocus: View {
    let quest: TodoItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 Current Quest")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(quest.text)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                if let difficulty = quest.difficulty {
                    Label {
                        Text(difficulty.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    } icon: {
                        Text(difficulty.icon)
                    }
                }
                
                if let duration = quest.estimatedDuration {
                    Label {
                        Text(duration)
                            .font(.caption)
                    } icon: {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Text("💡 Tip: Focus on this one quest. Complete it before moving to the next!")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(20)
        .conditionalGlassBackground(Color.orange, opacity: 0.05, in: RoundedRectangle(cornerRadius: 16))
        .conditionalGlassEffect(in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.4), lineWidth: 2)
        )
    }
}

// MARK: - Project Editor View
struct ProjectEditorView: View {
    let project: ProjectData
    let todoListStore: TodoListStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName: String
    @State private var projectDescription: String = ""
    @State private var missionStatement: String = ""
    @State private var selectedType: ProjectType
    @State private var showingDeleteConfirmation = false
    
    init(project: ProjectData, todoListStore: TodoListStore) {
        self.project = project
        self.todoListStore = todoListStore
        self._projectName = State(initialValue: project.title)
        self._selectedType = State(initialValue: project.type)
        // Initialize with placeholder values
        self._projectDescription = State(initialValue: "")
        self._missionStatement = State(initialValue: "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $projectName)
                        .autocapitalization(.words)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(ProjectType.allCases) { type in
                            HStack {
                                Text(type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Mission & Purpose") {
                    TextField("Mission Statement", text: $missionStatement, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Project Description", text: $projectDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Project Statistics") {
                    HStack {
                        Label("Tasks", systemImage: "checklist")
                        Spacer()
                        Text("\(project.completedCount) of \(project.totalCount) completed")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Progress", systemImage: "chart.bar")
                        Spacer()
                        Text("\(Int(project.progress * 100))%")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Level", systemImage: "star")
                        Spacer()
                        Text("Level \(project.level)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Advanced") {
                    Button("Delete Project", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    
                    Button("Rename Project Tasks", role: .destructive) {
                        // TODO: Implement batch task renaming
                    }
                    .disabled(true) // Placeholder for future feature
                    
                    Button("Archive Completed Tasks", role: .destructive) {
                        // TODO: Implement task archiving
                    }
                    .disabled(true) // Placeholder for future feature
                }
            }
            .conditionalFormStyle()
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Project", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteProject()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete '\(project.title)'? This will remove all \(project.totalCount) tasks in this project. This action cannot be undone.")
            }
        }
    }
    
    private func saveChanges() {
        // Trim whitespace
        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only proceed if name is valid
        guard !trimmedName.isEmpty && trimmedName.count <= 30 else { return }
        
        // Update all tasks in this project with new name and type
        let tasksInProject = todoListStore.items.filter { 
            $0.projectOrPath == project.title 
        }
        
        for task in tasksInProject {
            if trimmedName != project.title {
                todoListStore.updateTaskProjectOrPath(
                    description: task.text, 
                    projectOrPath: trimmedName
                )
            }
            
            // Update project type if it changed
            if selectedType != project.type {
                let index = todoListStore.items.firstIndex { $0.id == task.id }
                if let index = index {
                    todoListStore.items[index].projectType = selectedType
                }
            }
        }
        
        // Save changes
        todoListStore.saveItems()
        
        // TODO: Save mission statement and description to UserDefaults with project key
        // UserDefaults.standard.set(missionStatement, forKey: "projectMission_\(trimmedName)")
        // UserDefaults.standard.set(projectDescription, forKey: "projectDescription_\(trimmedName)")
        
        print("DEBUG [ProjectEditor]: Updated project '\(project.title)' to '\(trimmedName)'")
    }
    
    private func deleteProject() {
        // Find all tasks in this project
        let tasksToDelete = todoListStore.items.filter { 
            $0.projectOrPath == project.title 
        }
        
        // Remove tasks from the store
        for task in tasksToDelete {
            if let index = todoListStore.items.firstIndex(where: { $0.id == task.id }) {
                todoListStore.items.remove(at: index)
                
                // Sync deletion to CloudKit
                todoListStore.cloudKitManager.deleteTodoItem(task)
            }
        }
        
        // Save changes
        todoListStore.saveItems()
        
        // TODO: Remove project metadata from UserDefaults
        // UserDefaults.standard.removeObject(forKey: "projectMission_\(project.title)")
        // UserDefaults.standard.removeObject(forKey: "projectDescription_\(project.title)")
        
        print("DEBUG [ProjectEditor]: Deleted project '\(project.title)' and \(tasksToDelete.count) tasks")
    }
}

// MARK: - Project Creator View
struct ProjectCreatorView: View {
    let todoListStore: TodoListStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName: String = ""
    @State private var projectDescription: String = ""
    @State private var missionStatement: String = ""
    @State private var selectedType: ProjectType = .personal
    @State private var createWithSampleTask: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $projectName)
                        .autocapitalization(.words)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(ProjectType.allCases) { type in
                            HStack {
                                Text(type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Mission & Purpose") {
                    TextField("Mission Statement", text: $missionStatement, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Project Description", text: $projectDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Initial Setup") {
                    Toggle("Create sample task", isOn: $createWithSampleTask)
                    
                    if createWithSampleTask {
                        Text("A sample task will be created to get you started with this project.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .conditionalFormStyle()
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createProject()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createProject() {
        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty && trimmedName.count <= 30 else { return }
        
        // Create a sample task for the new project if requested
        if createWithSampleTask {
            let sampleTaskText = "First task for \(trimmedName)"
            
            // Add the task using the store's addItem method
            let newTask = TodoItem(
                text: sampleTaskText,
                projectOrPath: trimmedName,
                projectType: selectedType
            )
            
            todoListStore.items.append(newTask)
            todoListStore.saveItems()
            
            // Sync to CloudKit
            todoListStore.cloudKitManager.saveTodoItem(newTask)
        }
        
        // TODO: Save mission statement and description to UserDefaults
        // UserDefaults.standard.set(missionStatement, forKey: "projectMission_\(trimmedName)")
        // UserDefaults.standard.set(projectDescription, forKey: "projectDescription_\(trimmedName)")
        
        print("DEBUG [ProjectCreator]: Created new project '\(trimmedName)' of type \(selectedType.rawValue)")
    }
}

#Preview {
    RoadmapView()
}