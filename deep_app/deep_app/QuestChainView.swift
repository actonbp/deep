import SwiftUI

// MARK: - Quest Chain View
struct QuestChainView: View {
    let project: ProjectData
    let mission: ProjectMission?
    @State private var selectedTaskId: UUID?
    @State private var showMissionBrief = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Mission Brief Card
                if showMissionBrief, let mission = mission {
                    MissionBriefCard(mission: mission)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Current Quest Focus
                CurrentQuestCard(
                    currentTask: getCurrentTask(),
                    nextTasks: getUpcomingTasks(limit: 2)
                )
                
                // Quest Path Visualization
                QuestPathView(
                    tasks: project.tasks,
                    selectedTaskId: $selectedTaskId
                )
                
                // Progress Overview
                PhaseProgressBar(
                    currentPhase: mission?.currentPhase ?? .planning,
                    completedTasks: project.completedCount,
                    totalTasks: project.totalCount
                )
            }
            .padding()
        }
        .background(
            // Epic fantasy background
            ZStack {
                LinearGradient(
                    colors: [
                        Color.indigo.opacity(0.1),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating particles for ambiance
                ParticleField()
            }
        )
    }
    
    private func getCurrentTask() -> TodoItem? {
        project.tasks
            .filter { !$0.isDone }
            .sorted { ($0.priority ?? Int.max) < ($1.priority ?? Int.max) }
            .first
    }
    
    private func getUpcomingTasks(limit: Int) -> [TodoItem] {
        Array(
            project.tasks
                .filter { !$0.isDone }
                .sorted { ($0.priority ?? Int.max) < ($1.priority ?? Int.max) }
                .dropFirst()
                .prefix(limit)
        )
    }
}

// MARK: - Mission Brief Card
struct MissionBriefCard: View {
    let mission: ProjectMission
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("📜")
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mission Brief")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(mission.projectName)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(.indigo)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Mission Statement
                    Label {
                        Text(mission.missionStatement.isEmpty ? "Define your mission..." : mission.missionStatement)
                            .font(.body)
                            .foregroundColor(mission.missionStatement.isEmpty ? .secondary : .primary)
                    } icon: {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.orange)
                    }
                    
                    // End Goal
                    Label {
                        Text(mission.endGoal.isEmpty ? "Set your end goal..." : mission.endGoal)
                            .font(.body)
                            .foregroundColor(mission.endGoal.isEmpty ? .secondary : .primary)
                    } icon: {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                    }
                    
                    // Estimated Completion
                    if let date = mission.estimatedCompletionDate {
                        Label {
                            Text(date, style: .date)
                                .font(.body)
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Total XP Reward
                    Label {
                        Text("\(mission.totalXPReward) XP")
                            .font(.body)
                            .fontWeight(.semibold)
                    } icon: {
                        Text("💎")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Current Quest Card
struct CurrentQuestCard: View {
    let currentTask: TodoItem?
    let nextTasks: [TodoItem]
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("⚔️ Current Quest")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if currentTask != nil {
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                        )
                }
            }
            
            if let task = currentTask {
                // Main quest display
                VStack(alignment: .leading, spacing: 12) {
                    Text(task.text)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        // Difficulty
                        if let difficulty = task.difficulty {
                            Label {
                                Text(difficulty.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            } icon: {
                                Text(difficulty.icon)
                            }
                        }
                        
                        // Duration
                        if let duration = task.estimatedDuration {
                            Label {
                                Text(duration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } icon: {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Priority
                        if let priority = task.priority, priority <= 3 {
                            Label {
                                Text("Priority \(priority)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    // Action button
                    Button(action: {}) {
                        HStack {
                            Text("Start Quest")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pulseAnimation = true
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.indigo.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.indigo.opacity(0.3), lineWidth: 2)
                        )
                )
                
                // Upcoming quests preview
                if !nextTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next in Queue:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(nextTasks) { task in
                            HStack {
                                Text("→")
                                    .foregroundColor(.secondary)
                                Text(task.text)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Text("🎊")
                        .font(.largeTitle)
                    Text("All quests complete!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Quest Path Visualization
struct QuestPathView: View {
    let tasks: [TodoItem]
    @Binding var selectedTaskId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🗺️ Quest Path")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 40) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        QuestNode(
                            task: task,
                            isSelected: selectedTaskId == task.id,
                            isFirst: index == 0,
                            isLast: index == tasks.count - 1,
                            onTap: { selectedTaskId = task.id }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 40)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.8))
        )
    }
}

// MARK: - Quest Node
struct QuestNode: View {
    let task: TodoItem
    let isSelected: Bool
    let isFirst: Bool
    let isLast: Bool
    let onTap: () -> Void
    
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Connection line
            if !isFirst {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(task.isDone ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 40, height: 3)
                        .offset(x: -20)
                    
                    Spacer()
                }
            }
            
            // Node
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(task.isDone ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    if task.isDone {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Text("\(task.priority ?? 99)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .shadow(color: isSelected ? Color.indigo.opacity(0.5) : .clear, radius: 10)
            }
            
            // Task name
            Text(task.text)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 100)
            
            // Metadata badges
            HStack(spacing: 4) {
                if let difficulty = task.difficulty {
                    Text(difficulty.icon)
                        .font(.caption2)
                }
                if task.estimatedDuration != nil {
                    Text("⏱️")
                        .font(.caption2)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Phase Progress Bar
struct PhaseProgressBar: View {
    let currentPhase: ProjectPhase
    let completedTasks: Int
    let totalTasks: Int
    
    var progress: Double {
        totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Journey Progress")
                    .font(.headline)
                
                Spacer()
                
                Text("\(currentPhase.icon) \(currentPhase.rawValue)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.indigo.opacity(0.2))
                    )
            }
            
            // Phase indicators
            HStack(spacing: 0) {
                ForEach(ProjectPhase.allCases, id: \.self) { phase in
                    PhaseIndicator(
                        phase: phase,
                        isActive: phase == currentPhase,
                        isCompleted: phase.progressPercentage <= progress
                    )
                    
                    if phase != ProjectPhase.allCases.last {
                        Rectangle()
                            .fill(phase.progressPercentage < progress ? Color.green : Color.gray.opacity(0.3))
                            .frame(height: 3)
                    }
                }
            }
            
            // Stats
            HStack {
                Label("\(completedTasks)/\(totalTasks) Quests", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))% Complete")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Phase Indicator
struct PhaseIndicator: View {
    let phase: ProjectPhase
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : (isActive ? Color.indigo : Color.gray.opacity(0.3)))
                    .frame(width: 40, height: 40)
                
                Text(phase.icon)
                    .font(.title3)
            }
            .scaleEffect(isActive ? 1.2 : 1.0)
            
            Text(phase.rawValue)
                .font(.caption2)
                .fontWeight(isActive ? .semibold : .regular)
                .foregroundColor(isActive ? .primary : .secondary)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}

// MARK: - Particle Field
struct ParticleField: View {
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 2...6))
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -400...400)
                    )
                    .blur(radius: CGFloat.random(in: 0...2))
            }
        }
    }
}