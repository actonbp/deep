/*
Bryan's Brain - Task Priorities Update Tool

Abstract:
Tool for updating task priority order using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct UpdateTaskPrioritiesTool: Tool {
    let name = "updateTaskPriorities"
    let description = "Updates the priority order of tasks in the to-do list"
    
    @Generable
    struct Arguments {
        @Guide(description: "An array of task description strings, ordered from highest priority (index 0) to lowest")
        let orderedTaskDescriptions: [String]
    }
    
    func call(arguments: Arguments) async -> String {
        Logging.general.log("🚨 UpdateTaskPrioritiesTool: Updating priorities for \(arguments.orderedTaskDescriptions.count) tasks")
        
        let success = await MainActor.run {
            TodoListStore.shared.updatePriorities(orderedTasks: arguments.orderedTaskDescriptions)
            return true // updatePriorities doesn't return a value, assume success
        }
        
        if success {
            Logging.general.log("UpdateTaskPrioritiesTool: Priorities updated successfully")
            return "Updated task priorities. New order: \(arguments.orderedTaskDescriptions.joined(separator: ", "))"
        } else {
            Logging.general.log("UpdateTaskPrioritiesTool: Failed to update priorities")
            return "Could not update task priorities. Some tasks may not have been found."
        }
    }
}