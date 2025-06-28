/*
Bryan's Brain - Simplified Task Tool

Abstract:
Implementing the patterns from successful Foundation Models examples
Uses simple natural language parameter like the dad jokes example
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct SimplifiedTaskTool: Tool {
    let name = "taskManager"
    let description = "Manages and displays user tasks and productivity information"
    
    @Generable
    struct Arguments {
        @Guide(description: "A natural language request about tasks, such as 'show all tasks', 'count tasks', or 'what are my tasks'")
        let naturalLanguageQuery: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        Logging.general.log("🚨 SimplifiedTaskTool: Query: \(arguments.naturalLanguageQuery)")
        
        let tasks = await MainActor.run {
            TodoListStore.shared.items
        }
        
        let query = arguments.naturalLanguageQuery.lowercased()
        
        // Simple pattern matching
        if query.contains("count") || query.contains("how many") {
            return ToolOutput(generateCountResponse(tasks: tasks))
        } else {
            return ToolOutput(generateTaskOverview(tasks: tasks))
        }
    }
    
    private func generateCountResponse(tasks: [TodoItem]) -> String {
        let total = tasks.count
        let completed = tasks.filter { $0.isDone }.count
        let active = total - completed
        
        if total == 0 {
            return "You have no tasks at the moment. Your workspace is completely clear!"
        } else {
            return "You have \(total) tasks total: \(completed) completed and \(active) active."
        }
    }
    
    private func generateTaskOverview(tasks: [TodoItem]) -> String {
        if tasks.isEmpty {
            return "Your task list is empty. Ready to add some new goals!"
        }
        
        let taskList = tasks.prefix(5).enumerated().map { index, task in
            let status = task.isDone ? "✅" : "📋"
            return "\(index + 1). \(status) \(task.text)"
        }.joined(separator: "\n")
        
        let more = tasks.count > 5 ? "\n...and \(tasks.count - 5) more tasks" : ""
        
        return "Here are your tasks:\n\n\(taskList)\(more)"
    }
}

// Structured output for task responses (following the pattern)
@available(iOS 26.0, *)
@Generable
struct TaskResponse {
    let summary: String
    let taskCount: Int
    let completedCount: Int
}

// Ultra-simple version with no parameters at all
@available(iOS 26.0, *)
struct SimpleShowTasksTool: Tool {
    let name = "showAllTasks"
    let description = "Shows all tasks immediately without any parameters"
    
    @Generable
    struct Arguments {
        // No arguments - always shows all tasks
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        Logging.general.log("🚨 SimpleShowTasksTool: Showing all tasks (no params)")
        
        let tasks = await MainActor.run {
            TodoListStore.shared.items
        }
        
        if tasks.isEmpty {
            return ToolOutput("Your task list is empty!")
        }
        
        // Limit to 10 tasks to avoid token limit issues
        let maxTasksToShow = 10
        let tasksToShow = Array(tasks.prefix(maxTasksToShow))
        let taskList = tasksToShow.enumerated().map { index, task in
            let status = task.isDone ? "✅" : "📋"
            return "\(index + 1). \(status) \(task.text)"
        }.joined(separator: "\n")
        
        if tasks.count > maxTasksToShow {
            return ToolOutput("Your tasks (showing \(maxTasksToShow) of \(tasks.count)):\n\n\(taskList)\n\n...and \(tasks.count - maxTasksToShow) more tasks.")
        } else {
            return ToolOutput("Your tasks:\n\n\(taskList)")
        }
    }
}