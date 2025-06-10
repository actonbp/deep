import SwiftUI

struct RoadmapView: View {
    // Access the shared store
    @ObservedObject private var todoListStore = TodoListStore.shared
    @State private var selectedProject: String? = nil
    @State private var expandedProjects: Set<String> = []
    @State private var showLevelUpAnimation = false
    @State private var newlyCompletedTasks: Set<UUID> = []
    
    // Consistent title styling
    let titleFontSize: CGFloat = 22 
    let sciFiFont = "Orbitron"

    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                AnimatedGameBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Hero Stats Section
                        HeroStatsCard(projects: projectData)
                            .padding(.horizontal)
                        
                        // Quest Boards
                        VStack(spacing: 16) {
                            ForEach(projectData.sorted(by: { $0.progress > $1.progress }), id: \.title) { project in
                                QuestBoardCard(
                                    project: project,
                                    isExpanded: expandedProjects.contains(project.title)
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        if expandedProjects.contains(project.title) {
                                            expandedProjects.remove(project.title)
                                        } else {
                                            expandedProjects.insert(project.title)
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
            }
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
            let progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
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
        let xpInCurrentLevel = totalXP - currentLevelXP
        let xpNeededForLevel = 75
        return Double(xpInCurrentLevel) / Double(xpNeededForLevel)
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
                            .frame(width: geometry.size.width * xpProgress, height: 12)
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
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
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
            }
        )
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
                    
                    // Expand chevron
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.title3)
                        .foregroundColor(project.type.color)
                }
                
                // Epic progress bar
                VStack(spacing: 10) {
                    GeometryReader { geometry in
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
                                .frame(width: geometry.size.width * project.progress, height: 16)
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
                                        .offset(x: pulseGlow ? geometry.size.width : -geometry.size.width)
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
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                    
                    // Glowing border for high progress
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
            
            // Expanded quest list
            if isExpanded {
                QuestList(project: project)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Quest List
struct QuestList: View {
    let project: ProjectData
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(project.tasks.sorted(by: { !$0.isDone && $1.isDone })) { task in
                QuestRow(task: task, projectColor: project.type.color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
        .padding(.horizontal, 4)
        .padding(.top, -8)
    }
}

// MARK: - Quest Row
struct QuestRow: View {
    let task: TodoItem
    let projectColor: Color
    @State private var completionGlow = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Epic completion indicator
            ZStack {
                Circle()
                    .fill(task.isDone ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .scaleEffect(completionGlow ? 1.2 : 1.0)
                
                Image(systemName: task.isDone ? "checkmark" : "circle")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(task.isDone ? Color.theme.titleText : Color.theme.secondaryText)
            }
            .onAppear {
                if task.isDone {
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        completionGlow = true
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.text)
                    .font(.subheadline)
                    .fontWeight(task.isDone ? .regular : .medium)
                    .foregroundColor(task.isDone ? .secondary : .primary)
                    .strikethrough(task.isDone)
                
                HStack(spacing: 8) {
                    if let difficulty = task.difficulty {
                        HStack(spacing: 4) {
                            Text(difficulty.icon)
                                .font(.caption2)
                            Text(difficulty.rawValue)
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(difficulty.color.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    if let duration = task.estimatedDuration {
                        HStack(spacing: 2) {
                            Text("⏱️")
                                .font(.caption2)
                            Text(duration)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Priority gems
            if let priority = task.priority, priority <= 3 {
                VStack(spacing: 2) {
                    ForEach(0..<min(3, 4-priority), id: \.self) { _ in
                        Circle()
                            .fill(projectColor)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(task.isDone ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .overlay(
            // Epic border for completed tasks
            Group {
                if task.isDone {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                }
            }
        )
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

#Preview {
    RoadmapView()
}