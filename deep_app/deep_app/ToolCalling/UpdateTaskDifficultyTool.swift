/*
Bryan's Brain - Task Difficulty Update Tool

Abstract:
Tool for updating task difficulty level using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct UpdateTaskDifficultyTool: Tool {
    let name = "updateTaskDifficulty"
    let description = "Updates the estimated difficulty (Low, Medium, High) for a specific task"
    
    @Generable
    struct Arguments {
        @Guide(description: "The description of the task whose difficulty needs to be updated")
        let taskDescription: String
        
        @Guide(description: "The estimated difficulty level: Low, Medium, High")
        let difficulty: String
    }
    
    func call(arguments: Arguments) async -> String {
        Logging.general.log("🚨 UpdateTaskDifficultyTool: Updating difficulty for: \(arguments.taskDescription)")
        
        // Convert string to Difficulty enum
        guard let difficultyEnum = Difficulty(rawValue: arguments.difficulty) else {
            Logging.general.log("UpdateTaskDifficultyTool: Invalid difficulty value: \(arguments.difficulty)")
            return "Invalid difficulty level. Please use: Low, Medium, or High"
        }
        
        let success = await MainActor.run {
            TodoListStore.shared.updateTaskDifficulty(
                description: arguments.taskDescription,
                difficulty: difficultyEnum
            )
            return true // updateTaskDifficulty doesn't return a value, assume success
        }
        
        if success {
            Logging.general.log("UpdateTaskDifficultyTool: Difficulty updated successfully")
            return "Updated difficulty for '\(arguments.taskDescription)' to '\(arguments.difficulty)'"
        } else {
            Logging.general.log("UpdateTaskDifficultyTool: Task not found")
            return "Could not find task with description: '\(arguments.taskDescription)'"
        }
    }
}