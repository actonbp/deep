/*
Bryan's Brain - Task Creation Tool

Abstract:
Tool for creating new tasks using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct CreateTaskTool: Tool {
    let name = "addTaskToList"
    let description = "Creates a new task in the user's task list"
    
    @Generable
    struct Arguments {
        @Guide(description: "The task description to add")
        let taskDescription: String
        
        @Guide(description: "Optional category for the task")
        let category: String?
        
        @Guide(description: "Optional project or path for the task")
        let projectOrPath: String?
    }
    
    func call(arguments: Arguments) async -> String {
        Logging.general.log("🚨 CreateTaskTool: Creating task: \(arguments.taskDescription)")
        
        await MainActor.run {
            TodoListStore.shared.addItem(
                text: arguments.taskDescription,
                category: arguments.category,
                projectOrPath: arguments.projectOrPath
            )
        }
        
        Logging.general.log("CreateTaskTool: Task created successfully")
        return "Created task: '\(arguments.taskDescription)'"
    }
}