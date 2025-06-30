import Foundation

// MARK: - Project Mission Model
struct ProjectMission: Codable, Identifiable {
    let id: UUID
    let projectName: String
    let missionStatement: String // "Publish groundbreaking paper on X"
    let endGoal: String // "Paper accepted at top conference"
    let currentPhase: ProjectPhase
    let estimatedCompletionDate: Date?
    let milestones: [Milestone]
    let totalXPReward: Int
    let emoji: String
    let createdDate: Date
    
    init(projectName: String, missionStatement: String = "", endGoal: String = "") {
        self.id = UUID()
        self.projectName = projectName
        self.missionStatement = missionStatement
        self.endGoal = endGoal
        self.currentPhase = .planning
        self.estimatedCompletionDate = nil
        self.milestones = []
        self.totalXPReward = 1000 // Base XP for project completion
        self.emoji = "🎯"
        self.createdDate = Date()
    }
}

// MARK: - Project Phases
enum ProjectPhase: String, Codable, CaseIterable {
    case planning = "Planning"
    case earlyStage = "Early Stage"
    case midStage = "Mid Stage"
    case finalStage = "Final Stage"
    case complete = "Complete"
    
    var icon: String {
        switch self {
        case .planning: return "🗺️"
        case .earlyStage: return "🌱"
        case .midStage: return "🚀"
        case .finalStage: return "🎯"
        case .complete: return "🏆"
        }
    }
    
    var progressPercentage: Double {
        switch self {
        case .planning: return 0.1
        case .earlyStage: return 0.25
        case .midStage: return 0.5
        case .finalStage: return 0.75
        case .complete: return 1.0
        }
    }
}

// MARK: - Milestone Model
struct Milestone: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let requiredTasks: [UUID] // Task IDs that must be completed
    let xpReward: Int
    let unlockMessage: String // "You've unlocked: Submit to Conference!"
    let isCompleted: Bool
    let icon: String
    
    init(title: String, description: String = "", requiredTasks: [UUID] = []) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.requiredTasks = requiredTasks
        self.xpReward = 100
        self.unlockMessage = "Milestone achieved: \(title)"
        self.isCompleted = false
        self.icon = "⭐"
    }
}

// MARK: - Enhanced TodoItem Dependencies
extension TodoItem {
    struct TaskDependency: Codable {
        let dependsOn: [UUID] // Other task IDs this depends on
        let unlocks: [UUID] // Task IDs this unlocks when complete
        let sequenceNumber: Int // Order in the quest chain
        let isMilestone: Bool // Is this a major checkpoint?
        let phaseRequirement: ProjectPhase? // Which phase this belongs to
    }
}