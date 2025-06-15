/*
Bryan's Brain - Task Duration Update Tool

Abstract:
Tool for updating task estimated duration using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct UpdateTaskEstimatedDurationTool: Tool {
    let name = "updateTaskEstimatedDuration"
    let description = "Updates the estimated duration for a specific task on the to-do list"
    
    @Generable
    struct Arguments {
        @Guide(description: "The description of the task whose duration needs to be updated")
        let taskDescription: String
        
        @Guide(description: "The estimated duration for the task (e.g., '~15 mins', '1 hour', 'quick')")
        let estimatedDuration: String
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 UpdateTaskEstimatedDurationTool: Updating duration for: \(arguments.taskDescription)")
        
        let success = await MainActor.run {
            TodoListStore.shared.updateTaskDuration(
                description: arguments.taskDescription,
                duration: arguments.estimatedDuration
            )
            return true // updateTaskDuration doesn't return a value, assume success
        }
        
        if success {
            Logging.general.log("UpdateTaskEstimatedDurationTool: Duration updated successfully")
            return ToolOutput("Updated duration for '\(arguments.taskDescription)' to '\(arguments.estimatedDuration)'")
        } else {
            Logging.general.log("UpdateTaskEstimatedDurationTool: Task not found")
            return ToolOutput("Could not find task with description: '\(arguments.taskDescription)'")
        }
    }
}