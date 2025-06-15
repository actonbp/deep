/*
Bryan's Brain - Tool Collection

Abstract:
Collection of available Foundation Models tools, organized like Apple's examples
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
enum FoundationModelTools {
    
    /// Essential tools for basic functionality
    static func essential() -> [any Tool] {
        [
            CreateTaskTool(),
            GetTasksTool(),
            MarkTaskCompleteTool(),
            RemoveTaskTool(),
            GetCurrentDateTimeTool(),
            GetScratchpadTool(),
            SystemVerificationTool()
        ]
    }
    
    /// Minimal set for testing and fallback
    static func minimal() -> [any Tool] {
        [
            GetTasksTool(),
            CreateTaskTool(),
            SystemVerificationTool()
        ]
    }
    
    /// All available tools (for full functionality)
    static func all() -> [any Tool] {
        [
            // Task Management
            CreateTaskTool(),
            GetTasksTool(),
            RemoveTaskTool(),
            MarkTaskCompleteTool(),
            UpdateTaskPrioritiesTool(),
            UpdateTaskEstimatedDurationTool(),
            UpdateTaskDifficultyTool(),
            UpdateTaskCategoryTool(),
            UpdateTaskProjectOrPathTool(),
            BreakDownTaskTool(),
            
            // Calendar
            GetCurrentDateTimeTool(),
            CreateCalendarEventTool(),
            GetTodaysCalendarEventsTool(),
            DeleteCalendarEventTool(),
            UpdateCalendarEventTimeTool(),
            
            // Scratchpad
            GetScratchpadTool(),
            UpdateScratchpadTool(),
            
            // System
            SystemVerificationTool()
        ]
    }
}