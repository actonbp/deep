/*
Bryan's Brain - Direct Task Tool

Abstract:
Ultra-simple tool that directly shows tasks without requiring any parameters.
Designed to avoid Apple Foundation Models getting stuck asking for input.
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct DirectTaskTool: Tool {
    let name = "showTasks"
    let description = "Immediately shows the user's productivity goals without requiring any input"
    
    @Generable
    struct Arguments {
        @Guide(description: "Set to true to show current tasks and productivity goals")
        let showTasks: Bool
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 DirectTaskTool: Showing tasks immediately (no parameters)")
        
        let tasks = await MainActor.run {
            TodoListStore.shared.items
        }
        
        let totalCount = tasks.count
        let completedCount = tasks.filter { $0.isDone }.count
        let pendingCount = totalCount - completedCount
        
        Logging.general.log("DirectTaskTool: Processing \(totalCount) tasks")
        
        let output: String
        if totalCount == 0 {
            output = "Your productivity workspace is completely clear! No tasks are currently in your workspace. This is a perfect time to add new goals or enjoy your free time."
        } else {
            // Show a concise overview with first few tasks
            let taskPreview = tasks.prefix(5).enumerated().map { index, task in
                let status = task.isDone ? "✅ Done" : "📋 Active"
                return "  \(index + 1). \(status): \(task.text)"
            }.joined(separator: "\n")
            
            let moreTasksNote = totalCount > 5 ? "\n  ...and \(totalCount - 5) more" : ""
            
            output = """
            📊 Productivity Overview:
            • Total goals: \(totalCount)
            • Completed: \(completedCount) ✅
            • Active: \(pendingCount) 📋
            • Progress: \(totalCount > 0 ? Int((Double(completedCount) / Double(totalCount)) * 100) : 0)%
            
            Current Goals:
            \(taskPreview)\(moreTasksNote)
            
            You're doing great with your productivity!
            """
        }
        
        Logging.general.log("DirectTaskTool: Returning immediate task overview")
        return ToolOutput(output)
    }
}

// Alternative version that always returns count first
@available(iOS 26.0, *)
struct QuickTaskCountTool: Tool {
    let name = "countTasks"
    let description = "Instantly returns the number of tasks"
    
    @Generable
    struct Arguments {
        @Guide(description: "Set to true to get task count")
        let getCount: Bool
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 QuickTaskCountTool: Getting task count")
        
        let tasks = await MainActor.run {
            TodoListStore.shared.items
        }
        
        let totalCount = tasks.count
        let completedCount = tasks.filter { $0.isDone }.count
        
        let output = "You have \(totalCount) total goals: \(completedCount) completed, \(totalCount - completedCount) active."
        
        Logging.general.log("QuickTaskCountTool: Returning count")
        return ToolOutput(output)
    }
}