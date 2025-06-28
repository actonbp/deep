/*
Bryan's Brain - Task Retrieval Tool

Abstract:
Tool for retrieving the user's current task list using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct GetTasksTool: Tool {
    let name = "listCurrentTasks"
    let description = "Gets the current task list for the user"
    
    @Generable
    struct Arguments {
        @Guide(description: "Set to true to retrieve tasks")
        let retrieve: Bool
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 GetTasksTool: Tool called with retrieve: \(arguments.retrieve)")
        
        let tasks = await MainActor.run {
            TodoListStore.shared.items
        }
        
        Logging.general.log("GetTasksTool: Retrieved \(tasks.count) tasks")
        
        let output: String
        if tasks.isEmpty {
            output = "You have no tasks in your list."
        } else {
            // Limit to first 10 tasks to avoid token limit issues
            let maxTasksToShow = 10
            let tasksToShow = Array(tasks.prefix(maxTasksToShow))
            let taskList = tasksToShow.enumerated().map { index, task in
                let status = task.isDone ? "[COMPLETED]" : "[TODO]"
                return "\(index + 1). \(status) \(task.text)"
            }.joined(separator: "\n")
            
            if tasks.count > maxTasksToShow {
                output = "You have \(tasks.count) tasks (showing first \(maxTasksToShow)):\n\(taskList)\n\n...and \(tasks.count - maxTasksToShow) more tasks."
            } else {
                output = "You have \(tasks.count) tasks:\n\(taskList)"
            }
        }
        
        Logging.general.log("GetTasksTool: Returning successful response")
        return ToolOutput(output)
    }
}