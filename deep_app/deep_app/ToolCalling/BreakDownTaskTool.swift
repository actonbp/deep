/*
Bryan's Brain - Task Breakdown Tool

Abstract:
Tool for breaking down large tasks into smaller subtasks using Foundation Models framework
Essential for ADHD users who struggle with overwhelming tasks
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct BreakDownTaskTool: Tool {
    let name = "breakDownTask"
    let description = "Breaks down a large, complex task into smaller, more manageable subtasks. Essential for ADHD users who struggle with overwhelming tasks. Each subtask should be actionable and completable in 15-30 minutes."
    
    @Generable
    struct Arguments {
        @Guide(description: "The description of the large task to break down")
        let originalTaskDescription: String
        
        @Guide(description: "Array of smaller, actionable subtasks. Each subtask should be specific, measurable, and completable in 15-30 minutes")
        let subtasks: [String]
        
        @Guide(description: "Whether to replace the original task with the subtasks (true) or keep both (false). Default is true")
        let replaceOriginal: Bool?
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 BreakDownTaskTool: Breaking down task: \(arguments.originalTaskDescription)")
        
        let shouldReplace = arguments.replaceOriginal ?? true
        
        let result = await MainActor.run {
            // Simple implementation: remove original if requested, then add subtasks
            var success = true
            
            if shouldReplace {
                success = TodoListStore.shared.removeTask(description: arguments.originalTaskDescription)
            }
            
            // Add all subtasks
            for subtask in arguments.subtasks {
                TodoListStore.shared.addItem(text: subtask)
            }
            
            return success
        }
        
        if result {
            let action = shouldReplace ? "replaced with" : "broken down into"
            Logging.general.log("BreakDownTaskTool: Task broken down successfully")
            return ToolOutput("Task '\(arguments.originalTaskDescription)' \(action) \(arguments.subtasks.count) subtasks:\n\n" + 
                            arguments.subtasks.enumerated().map { "• \($0.element)" }.joined(separator: "\n"))
        } else {
            Logging.general.log("BreakDownTaskTool: Original task not found")
            return ToolOutput("Could not find the original task: '\(arguments.originalTaskDescription)'")
        }
    }
}