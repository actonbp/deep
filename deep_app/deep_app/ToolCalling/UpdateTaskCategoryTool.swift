/*
Bryan's Brain - Task Category Update Tool

Abstract:
Tool for updating task category using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct UpdateTaskCategoryTool: Tool {
    let name = "updateTaskCategory"
    let description = "Sets or clears the category (e.g., Research, Teaching, Life) for a specific task"
    
    @Generable
    struct Arguments {
        @Guide(description: "The description of the task to categorize")
        let taskDescription: String
        
        @Guide(description: "The category name to assign. Provide an empty string to clear the category")
        let category: String
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 UpdateTaskCategoryTool: Updating category for: \(arguments.taskDescription)")
        
        let categoryValue = arguments.category.isEmpty ? nil : arguments.category
        
        let success = await MainActor.run {
            TodoListStore.shared.updateTaskCategory(
                description: arguments.taskDescription,
                category: categoryValue
            )
            return true // updateTaskCategory doesn't return a value, assume success
        }
        
        if success {
            Logging.general.log("UpdateTaskCategoryTool: Category updated successfully")
            let action = categoryValue == nil ? "cleared" : "set to '\(arguments.category)'"
            return ToolOutput("Category \(action) for task: '\(arguments.taskDescription)'")
        } else {
            Logging.general.log("UpdateTaskCategoryTool: Task not found")
            return ToolOutput("Could not find task with description: '\(arguments.taskDescription)'")
        }
    }
}