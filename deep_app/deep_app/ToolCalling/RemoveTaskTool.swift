/*
Bryan's Brain - Task Removal Tool

Abstract:
Tool for removing tasks from the user's task list using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct RemoveTaskTool: Tool {
    let name = "removeTaskFromList"
    let description = "Removes a specific task from the user's to-do list based on its description"
    
    @Generable
    struct Arguments {
        @Guide(description: "The exact description of the task to remove")
        let taskDescription: String
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 RemoveTaskTool: Removing task: \(arguments.taskDescription)")
        
        let success = await MainActor.run {
            TodoListStore.shared.removeTask(description: arguments.taskDescription)
        }
        
        if success {
            Logging.general.log("RemoveTaskTool: Task removed successfully")
            return ToolOutput("Removed task: '\(arguments.taskDescription)'")
        } else {
            Logging.general.log("RemoveTaskTool: Task not found")
            return ToolOutput("Could not find task with description: '\(arguments.taskDescription)'")
        }
    }
}