/*
Bryan's Brain - Task Project/Path Update Tool

Abstract:
Tool for updating task project or path assignment using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct UpdateTaskProjectOrPathTool: Tool {
    let name = "updateTaskProjectOrPath"
    let description = "Sets or clears the specific project or path (e.g., 'Paper XYZ', 'LEAD 552') for a task within its category"
    
    @Generable
    struct Arguments {
        @Guide(description: "The description of the task to assign to a project/path")
        let taskDescription: String
        
        @Guide(description: "The project/path name to assign. Provide an empty string to clear the project/path")
        let projectOrPath: String
    }
    
    func call(arguments: Arguments) async -> String {
        Logging.general.log("🚨 UpdateTaskProjectOrPathTool: Updating project/path for: \(arguments.taskDescription)")
        
        let projectValue = arguments.projectOrPath.isEmpty ? nil : arguments.projectOrPath
        
        let success = await MainActor.run {
            TodoListStore.shared.updateTaskProjectOrPath(
                description: arguments.taskDescription,
                projectOrPath: projectValue
            )
            return true // updateTaskProjectOrPath doesn't return a value, assume success
        }
        
        if success {
            Logging.general.log("UpdateTaskProjectOrPathTool: Project/path updated successfully")
            let action = projectValue == nil ? "cleared" : "set to '\(arguments.projectOrPath)'"
            return "Project/path \(action) for task: '\(arguments.taskDescription)'"
        } else {
            Logging.general.log("UpdateTaskProjectOrPathTool: Task not found")
            return "Could not find task with description: '\(arguments.taskDescription)'"
        }
    }
}