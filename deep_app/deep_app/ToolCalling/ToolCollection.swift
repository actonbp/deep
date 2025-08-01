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
            // ADHD-Focused Tools (prevent overwhelm)
            NextActionTool(),         // NEW: Suggests ONE next action
            MicroStepTool(),         // NEW: Breaks tasks into 5-min steps
            
            // Direct Access Tools (no parameters, immediate response)
            DirectTaskTool(),         // CRITICAL: Shows tasks without asking for input
            QuickTaskCountTool(),     // CRITICAL: Returns count without parameters
            
            // Task Management (LIMITED to prevent loops)
            // CreateTaskTool(),      // REMOVED: Causes task creation loops
            SafeTaskRetrievalTool(),  // Safer alternative to GetTasksTool
            MarkTaskCompleteTool(),
            // RemoveTaskTool(),      // REMOVED: Too destructive
            
            // Calendar Access (Essential for daily productivity)
            GetCurrentDateTimeTool(),
            GetTodaysCalendarEventsTool(),  
            SafeCalendarTool(),             
            // CreateCalendarEventTool(),  // REMOVED: Prevent calendar spam
            
            // Notes & System
            GetScratchpadTool(),
            SafeResponseTool(),       // For handling potentially triggering queries
            SystemVerificationTool()
        ]
    }
    
    /// Ultra-minimal set using successful Foundation Models patterns
    static func minimal() -> [any Tool] {
        [
            // ADHD-focused tools (prevent overwhelm)
            NextActionTool(),         // Suggests ONE next action
            MicroStepTool(),         // Breaks into 5-min steps
            
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
            // ADHD-Focused Tools
            NextActionTool(),
            MicroStepTool(),
            
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
            QuickTaskCountTool(),
            SimplifiedTaskTool(),
            SimpleShowTasksTool()
        ]
    }
}