/*
Bryan's Brain - Task Completion Tool

Abstract:
Tool for marking tasks as complete using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct MarkTaskCompleteTool: Tool {
    let name = "markTaskComplete"
    let description = "Marks a specific task as complete on the user's to-do list based on its description. Does NOT remove the task."
    
    @Generable
    struct Arguments {
        @Guide(description: "The exact description of the task to mark as complete")
        let taskDescription: String
    }
    
    func call(arguments: Arguments) async -> String {
        Logging.general.log("🚨 MarkTaskCompleteTool: Marking task complete: \(arguments.taskDescription)")
        
        let success = await MainActor.run {
            // Find the item and toggle it to done
            if let item = TodoListStore.shared.items.first(where: { 
                $0.text.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(arguments.taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame 
            }) {
                TodoListStore.shared.toggleDone(item: item)
                return true
            }
            return false
        }
        
        if success {
            Logging.general.log("MarkTaskCompleteTool: Task marked complete successfully")
            return "Marked task as complete: '\(arguments.taskDescription)'"
        } else {
            Logging.general.log("MarkTaskCompleteTool: Task not found")
            return "Could not find task with description: '\(arguments.taskDescription)'"
        }
    }
}