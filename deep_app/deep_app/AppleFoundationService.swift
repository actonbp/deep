//
//  AppleFoundationService.swift
//  deep_app
//
//  Bridges the chat loop to Apple's on‑device Foundation Model.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
import os

/// Service for Apple on-device Foundation Model with tool calling support.
/// Provides parity with OpenAIService for task management and calendar operations.
@available(iOS 26, *)
actor AppleFoundationService {

    enum APIResult { case success(String), failure(Error?) }
    
    // MARK: - Utility Functions
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add the timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            // Return the first result and cancel other tasks
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }
    
    private struct TimeoutError: LocalizedError {
        var errorDescription: String? {
            return "Operation timed out"
        }
    }

    // MARK: - Process Conversation
    
    func processConversation(messages: [OpenAIService.ChatMessage]) async -> APIResult {
#if canImport(FoundationModels)
        // Build conversation context from messages
        // let systemPrompt = messages.first { $0.role == "system" }?.content ?? ""
        let recentMessages = messages.filter { $0.role != "system" }.suffix(10)
        
        // Ultra-safe system prompt to avoid content filters
        let safeSystemPrompt = "You are Bryan's Brain, a supportive productivity assistant with direct access to the user's task and calendar systems. Your goal is to help users stay organized and take action on their next steps."
        
        // Build conversation context
        var conversationContext = ""
        for msg in recentMessages {
            if let content = msg.textContent() {
                conversationContext += "\(msg.role.capitalized): \(content)\n"
            }
        }
        
        // Extract the latest user message
        guard let lastUserChatMessage = recentMessages.last(where: { $0.role == "user" }),
              let lastUserMessage = lastUserChatMessage.textContent() else {
            return .failure(nil)
        }

        do {
            // Add retry logic for Foundation Models crashes
            var attempt = 0
            let maxAttempts = 3  // Increased from 2
            
            while attempt < maxAttempts {
                do {
                    // Progressive degradation: full tools -> essential tools -> no tools
                    let toolsToUse: [any Tool]
                    let toolMode: String
                    
                    switch attempt {
                    case 0:
                        toolsToUse = FoundationModelTools.essential()  // Start with reduced set
                        toolMode = "essential tools"
                    case 1:
                        toolsToUse = [SimplifiedTaskTool(), SimpleShowTasksTool(), CreateTaskTool(), SystemVerificationTool()]  // CRITICAL: Must include CreateTaskTool for adding tasks!
                        toolMode = "simplified tools with task creation"
                    default:
                        toolsToUse = []  // No tools - just text generation
                        toolMode = "no tools (text only)"
                    }
                    
                    print("DEBUG [AppleFoundationService]: Attempt \(attempt + 1) with \(toolMode)")
                    
                    // Create a fresh session for each attempt to avoid state corruption
                    print("DEBUG [AppleFoundationService]: Creating new session with \(toolsToUse.count) tools")
                    // Logging.general.log("AppleFoundationService: Starting session with \(toolsToUse.count) tools")
                    let session = LanguageModelSession(
                        tools: toolsToUse,
                        instructions: """
                        \(safeSystemPrompt)
                        
                        \(toolsToUse.isEmpty ? """
                        Note: Task tools are temporarily unavailable. 
                        Please provide helpful responses based on the conversation context.
                        """ : """
                        You have direct access to the user's tasks and calendar through your tools. When users ask about their tasks, schedule, or want to add something new, use your tools naturally to help them.
                        
                        Core behaviors:
                        - When asked "what are my tasks" → use taskManager or showAllTasks to check and share their current list
                        - When they want to add tasks → use addTaskToList to create them immediately  
                        - When they ask about their day → check getTodaysCalendarEvents
                        - Be encouraging and action-oriented, focusing on next steps
                        - Share tool results naturally in your responses
                        
                        Getting Unstuck Guidance:
                        When users say "I don't know where to start" or feel overwhelmed:
                        1. Check their current context (tasks and calendar)
                        2. Suggest the smallest possible next step
                        3. Be supportive and encouraging
                        
                        CRITICAL INSTRUCTION FOR TOOL RESPONSES:
                        When you call a tool, the system will return the results to you.
                        If listCurrentTasks returns "Here are your current tasks:" followed by a list, that IS your task data.
                        Never say you cannot see tasks - the tool response IS the task data.
                        Always share the exact content returned by the tool with the user.
                        
                        VERIFICATION MODE:
                        For system verification requests, use verifySystem with the appropriate message.
                        Available report formats: standard, structured, detailed.
                        Always share the complete verification report.
                        
                        IMPORTANT: You HAVE the capability to directly add and view tasks! Do not tell users to use external apps.
                        
                        AVAILABLE TOOLS (you can use these directly):
                        - taskManager: For viewing and managing tasks with natural language queries
                        - showAllTasks: For immediately displaying all tasks
                        - addTaskToList: For creating new tasks (YOU CAN DO THIS!)
                        - verifySystem: For system verification
                        
                        CRITICAL: When users ask to add tasks, use addTaskToList immediately. You ARE capable of adding tasks!
                        \(toolMode == "all tools" ? """
                        - To remove tasks: use removeTaskFromList
                        - To update priorities: use updateTaskPriorities
                        - To set duration: use updateTaskEstimatedDuration
                        """ : "")
                        
                        \(toolsToUse.isEmpty ? """
                        When tools are not available, focus on helping users organize their thoughts conceptually and suggest they can add tasks manually in the app.
                        """ : "")
                        
                        NOTES:
                        - To view notes: use getScratchpad
                        - To save notes: use updateScratchpad
                        
                        When you call a tool, the system will execute it and return the results.
                        Always use the tool results in your response to the user.
                        Never say you cannot access data - use the tools provided.
                        """)
                        
                        Previous conversation:
                        \(conversationContext)
                        """
                    )
                    
                    // Try to prewarm the session
                    session.prewarm()
                    print("DEBUG [AppleFoundationService]: Session prewarmed successfully")
                    
                    // Add a small delay to let the session stabilize (iOS 26 beta issue)
                    if attempt > 0 {
                        print("DEBUG [AppleFoundationService]: Waiting for session to stabilize...")
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    }
                    
                    // Make the request with adaptive timeout based on question complexity
                    print("DEBUG [AppleFoundationService]: About to call session.respond() - attempt \(attempt + 1)")
                    print("DEBUG [AppleFoundationService]: Message: \(lastUserMessage)")
                    
                    // Detect complex questions that need more thinking time
                    let isComplexQuestion = lastUserMessage.lowercased().contains("tools") || 
                                          lastUserMessage.lowercased().contains("build") ||
                                          lastUserMessage.lowercased().contains("ideas") ||
                                          lastUserMessage.lowercased().contains("how") ||
                                          lastUserMessage.lowercased().contains("create") ||
                                          lastUserMessage.lowercased().contains("develop") ||
                                          lastUserMessage.count > 100 // Long questions need more time
                    
                    let timeoutSeconds: TimeInterval = isComplexQuestion ? 300 : 120 // 5 minutes for complex, 2 minutes for simple
                    print("DEBUG [AppleFoundationService]: Using timeout of \(timeoutSeconds) seconds (complex: \(isComplexQuestion))")
                    
                    let response = try await withTimeout(seconds: timeoutSeconds) {
                        try await session.respond(to: lastUserMessage)
                    }
                    print("DEBUG [AppleFoundationService]: session.respond() completed successfully")
                    
                    print("DEBUG [AppleFoundationService]: Successfully received response from Foundation Models")
                    print("DEBUG [AppleFoundationService]: Response content: \(response.content)")
                    
                    // Check for content filter rejection
                    if response.content.contains("I'm sorry I cannot fulfill") || 
                       response.content.contains("I can't help with that") ||
                       response.content.contains("I cannot assist") {
                        print("DEBUG [AppleFoundationService]: Content filter triggered - attempting workaround")
                        
                        // If it's a simple task request, use the direct workaround
                        let isTaskRequest = lastUserMessage.lowercased().contains("task") || 
                                           lastUserMessage.lowercased().contains("count") ||
                                           lastUserMessage.lowercased().contains("test")
                        
                        if isTaskRequest {
                            let tasks = await MainActor.run { TodoListStore.shared.items }
                            let response = "You have \(tasks.count) items in your list."
                            print("DEBUG [AppleFoundationService]: Using content filter workaround")
                            return .success(response)
                        }
                    }
                    
                    // Check if model is refusing to use tools for task access
                    let refusalPatterns = [
                        "can't see", "unable to access", "don't have access", "not capable",
                        "cannot directly", "I don't have the ability", "I'm not able"
                    ]
                    
                    let isTaskRequest = lastUserMessage.lowercased().contains("task") || 
                                       lastUserMessage.lowercased().contains("todo") ||
                                       lastUserMessage.lowercased().contains("list")
                    
                    let isRefusing = refusalPatterns.contains { pattern in
                        response.content.lowercased().contains(pattern)
                    }
                    
                    if isTaskRequest && isRefusing {
                        print("DEBUG [AppleFoundationService]: Model refusing to use tools for task request. Attempting workaround...")
                        
                        // Try to manually invoke the force tool
                        let tasks = await MainActor.run { TodoListStore.shared.items }
                        let taskCount = tasks.count
                        
                        if taskCount == 0 {
                            let workaroundResponse = "I checked your task list and found it's completely empty. You have 0 tasks right now."
                            print("DEBUG [AppleFoundationService]: Using workaround response for empty list")
                            return .success(workaroundResponse)
                        } else {
                            let taskList = tasks.prefix(10).enumerated().map { index, task in
                                "\(index + 1). \(task.text)\(task.isDone ? " ✓" : "")"
                            }.joined(separator: "\n")
                            
                            let workaroundResponse = "I found \(taskCount) tasks in your list:\n\n\(taskList)\(taskCount > 10 ? "\n\n...and \(taskCount - 10) more tasks." : "")"
                            print("DEBUG [AppleFoundationService]: Using workaround response with task list")
                            return .success(workaroundResponse)
                        }
                    }
                    
                    // Check if response mentions inability to access data (original check)
                    if response.content.contains("can't see") || response.content.contains("unable to access") || response.content.contains("don't have access") {
                        print("DEBUG [AppleFoundationService]: Model appears confused about tool access - may need workaround.")
                    }
                    
                    return .success(response.content)
                    
                } catch {
                    attempt += 1
                    print("DEBUG [AppleFoundationService]: Attempt \(attempt) failed: \(error.localizedDescription)")
                    
                    // Check for specific Foundation Models crashes
                    let errorMessage = error.localizedDescription.lowercased()
                    let isCrash = errorMessage.contains("inference provider crashed") ||
                                  errorMessage.contains("ipc error") ||
                                  errorMessage.contains("underlying connection interrupted") ||
                                  errorMessage.contains("sensitive") ||
                                  errorMessage.contains("canceled session") ||
                                  errorMessage.contains("session generation error") ||
                                  errorMessage.contains("error 2") ||
                                  errorMessage.contains("tool execution") ||
                                  errorMessage.contains("session error") ||
                                  errorMessage.contains("content policy") ||
                                  errorMessage.contains("safety")
                    
                    // Special handling for tool-related crashes
                    let isToolCrash = errorMessage.contains("session generation error") ||
                                     errorMessage.contains("error 2") ||
                                     errorMessage.contains("tool execution")
                    
                    if isToolCrash {
                        print("DEBUG [AppleFoundationService]: Tool execution crash detected: \(error.localizedDescription)")
                        
                        // If this is a task request and we got a tool crash, use the workaround
                        let isTaskRequest = lastUserMessage.lowercased().contains("task") || 
                                           lastUserMessage.lowercased().contains("todo") ||
                                           lastUserMessage.lowercased().contains("list")
                        
                        if isTaskRequest {
                            print("DEBUG [AppleFoundationService]: Tool crash on task request - using direct workaround")
                            
                            let tasks = await MainActor.run { TodoListStore.shared.items }
                            let taskCount = tasks.count
                            
                            if taskCount == 0 {
                                let workaroundResponse = "I checked your task list and found it's completely empty. You have 0 tasks right now.\n\n(Note: On-device AI tools are experiencing issues in iOS 26 beta, so I retrieved this directly.)"
                                return .success(workaroundResponse)
                            } else {
                                let taskList = tasks.prefix(10).enumerated().map { index, task in
                                    "\(index + 1). \(task.text)\(task.isDone ? " ✓" : "")"
                                }.joined(separator: "\n")
                                
                                let workaroundResponse = "I found \(taskCount) tasks in your list:\n\n\(taskList)\(taskCount > 10 ? "\n\n...and \(taskCount - 10) more tasks." : "")\n\n(Note: On-device AI tools are experiencing issues in iOS 26 beta, so I retrieved this directly.)"
                                return .success(workaroundResponse)
                            }
                        }
                    }
                    
                    if isCrash {
                        if attempt < maxAttempts {
                            print("DEBUG [AppleFoundationService]: Foundation Models crashed, retrying after delay...")
                            // Wait a bit before retry to let the system recover
                            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                            continue
                        } else {
                            print("DEBUG [AppleFoundationService]: Foundation Models crashed after \(maxAttempts) attempts, giving up")
                            // Create a descriptive error for the user
                            let userFriendlyError = NSError(
                                domain: "AppleFoundationService",
                                code: 1001,
                                userInfo: [
                                    NSLocalizedDescriptionKey: "Apple's on-device AI is currently experiencing issues. This is a known problem with iOS 26 beta when using tool calling. Please try again, or switch to OpenAI in Settings for more stable performance."
                                ]
                            )
                            return .failure(userFriendlyError)
                        }
                    } else if errorMessage.contains("timeout") {
                        // Handle timeout specifically
                        let timeoutError = NSError(
                            domain: "AppleFoundationService",
                            code: 1003,
                            userInfo: [
                                NSLocalizedDescriptionKey: "The on-device AI took too long to respond. Please try a simpler request or switch to OpenAI in Settings."
                            ]
                        )
                        return .failure(timeoutError)
                    } else {
                        // For other errors, don't retry
                        return .failure(error)
                    }
                }
            }
            
            // This shouldn't be reached, but just in case
            return .failure(NSError(domain: "AppleFoundationService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Unexpected error in retry loop"]))

        } catch {
            print("DEBUG [AppleFoundationService]: Unexpected error: \(error.localizedDescription)")
            return .failure(error)
        }
#else
        return .failure(nil)
#endif
    }
}

// MARK: - Placeholder Types for Compilation

// These types are placeholders since we don't have the exact API yet
// They allow the code to compile and show the intended structure

#if canImport(FoundationModels)

// Remove the placeholder types that were causing conflicts
// The actual FoundationModels framework will provide these

#endif 