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
    
    /// Essential tools for basic functionality (with safety-optimized alternatives)
    static func essential() -> [any Tool] {
        [
            // Direct Access Tools (no parameters, immediate response)
            DirectTaskTool(),         // CRITICAL: Shows tasks without asking for input
            QuickTaskCountTool(),     // CRITICAL: Returns count without parameters
            
            // Task Management
            CreateTaskTool(),
            SafeTaskRetrievalTool(),  // Safer alternative to GetTasksTool
            GetTasksTool(),           // Keep original as backup
            MarkTaskCompleteTool(),
            RemoveTaskTool(),
            
            // Calendar Access (Essential for daily productivity)
            GetCurrentDateTimeTool(),
            GetTodaysCalendarEventsTool(),  // MISSING: This is why calendar doesn't work!
            SafeCalendarTool(),             // Safety-optimized calendar alternative
            CreateCalendarEventTool(),
            
            // Notes & System
            GetScratchpadTool(),
            SafeResponseTool(),       // For handling potentially triggering queries
            SystemVerificationTool()
        ]
    }
    
    /// Ultra-minimal set using successful Foundation Models patterns
    static func minimal() -> [any Tool] {
        [
            // Simple tools following proven patterns (like dad jokes example)
            SimplifiedTaskTool(),     // NEW: Single natural language parameter
            SimpleShowTasksTool(),    // NEW: No parameters, immediate response
            CreateTaskTool(),         // Keep creation functionality
            
            // Essential system
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
            
            // System & Safety
            SystemVerificationTool(),
            SafeTaskRetrievalTool(),
            SafeCalendarTool(),
            SafeResponseTool(),
            
            // Direct Tools (prevent infinite loops)
            DirectTaskTool(),
            QuickTaskCountTool()
        ]
    }
}