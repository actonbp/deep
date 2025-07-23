/*
Bryan's Brain - Structured Output Example

Abstract:
Demonstrates iOS 26 Beta 4's structured output capabilities using
@Generable models and GeneratedContent(json:) for parsing LLM responses.
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Structured Output Models

@available(iOS 26.0, *)
@Generable
struct TaskAnalysis: Codable {
    @Guide(description: "Estimated time in minutes with ADHD buffer")
    let estimatedMinutes: Int
    
    @Guide(description: "Cognitive difficulty: low, medium, or high")
    let difficulty: String
    
    @Guide(description: "Best time of day to complete: morning, afternoon, evening")
    let optimalTime: String
    
    @Guide(description: "Energy required on scale of 1-10")
    let energyRequired: Int
    
    @Guide(description: "Suggested subtasks if task is complex")
    let subtasks: [String]?
    
    @Guide(description: "ADHD-specific recommendations")
    let adhdTips: String
}

@available(iOS 26.0, *)
@Generable
struct ProjectSummary: Codable {
    @Guide(description: "Project name")
    let name: String
    
    @Guide(description: "Total tasks in project")
    let totalTasks: Int
    
    @Guide(description: "Completed tasks")
    let completedTasks: Int
    
    @Guide(description: "Estimated hours remaining")
    let hoursRemaining: Double
    
    @Guide(description: "Next recommended action")
    let nextAction: String
}

// MARK: - Tools Using Structured Outputs

@available(iOS 26.0, *)
struct AnalyzeTaskTool: Tool {
    let name = "analyzeTask"
    let description = "Provides ADHD-optimized analysis of a task"
    
    @Generable
    struct Arguments {
        @Guide(description: "The task text to analyze")
        let taskText: String
    }
    
    // Now returns TaskAnalysis instead of String
    func call(arguments: Arguments) async -> TaskAnalysis {
        // In a real implementation, this would use the LLM to analyze
        // For now, return a mock analysis
        return TaskAnalysis(
            estimatedMinutes: 30,
            difficulty: "medium",
            optimalTime: "morning",
            energyRequired: 6,
            subtasks: ["Research topic", "Create outline", "Write draft"],
            adhdTips: "Break into 15-min focused sessions with 5-min breaks. Start with the easiest subtask to build momentum."
        )
    }
}

@available(iOS 26.0, *)
struct GetProjectSummaryTool: Tool {
    let name = "getProjectSummary"
    let description = "Gets a summary of a specific project"
    
    @Generable
    struct Arguments {
        @Guide(description: "The project name")
        let projectName: String
    }
    
    // Returns structured ProjectSummary
    func call(arguments: Arguments) async -> ProjectSummary {
        // Get tasks for this project
        let allTasks = await MainActor.run {
            TodoListStore.shared.items.filter { $0.projectOrPath == arguments.projectName }
        }
        
        let completedCount = allTasks.filter { $0.isDone }.count
        let remainingTasks = allTasks.filter { !$0.isDone }
        
        // Calculate estimated hours (mock calculation)
        let hoursRemaining = Double(remainingTasks.count) * 0.5
        
        // Determine next action
        let nextAction = remainingTasks.first?.text ?? "No tasks remaining"
        
        return ProjectSummary(
            name: arguments.projectName,
            totalTasks: allTasks.count,
            completedTasks: completedCount,
            hoursRemaining: hoursRemaining,
            nextAction: nextAction
        )
    }
}

// MARK: - Using GeneratedContent with JSON

@available(iOS 26.0, *)
struct StructuredResponseHandler {
    
    /// Parse JSON response from an LLM into a structured model
    /// This uses the new GeneratedContent(json:) API from iOS 26 Beta 3
    static func parseStructuredResponse<T: Generable & Decodable>(
        json: String,
        as type: T.Type
    ) throws -> T {
        guard let jsonData = json.data(using: .utf8) else {
            throw ParseError.invalidJSON
        }
        
        // iOS 26 Beta 3 feature: GeneratedContent can be created from JSON
        let generatedContent = try GeneratedContent(json: json)
        
        // Convert to our structured type
        // Note: The actual API might differ - this is based on the tweet
        return try type.init(from: generatedContent)
    }
    
    /// Example of handling a tool call response
    static func handleToolCallResponse(toolName: String, jsonResponse: String) async throws -> any PromptRepresentable {
        switch toolName {
        case "analyzeTask":
            let analysis = try parseStructuredResponse(json: jsonResponse, as: TaskAnalysis.self)
            return formatTaskAnalysis(analysis)
            
        case "getProjectSummary":
            let summary = try parseStructuredResponse(json: jsonResponse, as: ProjectSummary.self)
            return formatProjectSummary(summary)
            
        default:
            throw ParseError.unknownTool(toolName)
        }
    }
    
    private static func formatTaskAnalysis(_ analysis: TaskAnalysis) -> String {
        var result = "Task Analysis:\n"
        result += "⏱️ Estimated time: \(analysis.estimatedMinutes) minutes\n"
        result += "🎯 Difficulty: \(analysis.difficulty)\n"
        result += "🌅 Best time: \(analysis.optimalTime)\n"
        result += "⚡ Energy required: \(analysis.energyRequired)/10\n"
        
        if let subtasks = analysis.subtasks, !subtasks.isEmpty {
            result += "\n📝 Suggested subtasks:\n"
            for (index, subtask) in subtasks.enumerated() {
                result += "  \(index + 1). \(subtask)\n"
            }
        }
        
        result += "\n💡 ADHD Tips: \(analysis.adhdTips)"
        return result
    }
    
    private static func formatProjectSummary(_ summary: ProjectSummary) -> String {
        let progress = Double(summary.completedTasks) / Double(summary.totalTasks) * 100
        
        return """
        Project: \(summary.name)
        Progress: \(summary.completedTasks)/\(summary.totalTasks) tasks (\(Int(progress))%)
        Time remaining: \(summary.hoursRemaining) hours
        Next action: \(summary.nextAction)
        """
    }
    
    enum ParseError: LocalizedError {
        case invalidJSON
        case unknownTool(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidJSON:
                return "Invalid JSON format"
            case .unknownTool(let name):
                return "Unknown tool: \(name)"
            }
        }
    }
}

// MARK: - Extension for Decodable from GeneratedContent

@available(iOS 26.0, *)
extension Decodable {
    /// Initialize from GeneratedContent (mock implementation)
    /// The actual API would be provided by Apple
    init(from content: GeneratedContent) throws {
        // This would use the actual GeneratedContent API
        // For now, this is a placeholder showing the concept
        let decoder = JSONDecoder()
        
        // In reality, GeneratedContent would provide a way to get JSON data
        // This is a mock implementation
        let jsonData = Data() // Would come from GeneratedContent
        
        self = try decoder.decode(Self.self, from: jsonData)
    }
}