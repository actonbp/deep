//
//  AIAgentManager.swift
//  deep_app
//
//  Manages background AI processing for task refinement and optimization
//

import Foundation
import BackgroundTasks
import SwiftUI

/// Manages AI Agent Mode - background processing for intelligent task management
class AIAgentManager: ObservableObject {
    static let shared = AIAgentManager()
    
    // Background task identifiers
    static let refineTasksIdentifier = "com.bryanbrain.ai.agent.refine"
    static let dailyAnalysisIdentifier = "com.bryanbrain.ai.agent.daily"
    
    // Settings keys
    static let aiAgentModeEnabledKey = "aiAgentModeEnabled"
    static let lastProcessingDateKey = "lastAIProcessingDate"
    static let processingInsightsKey = "aiProcessingInsights"
    
    @AppStorage(aiAgentModeEnabledKey) var isEnabled: Bool = false
    @Published var lastProcessingDate: Date?
    @Published var latestInsights: String = ""
    
    private let openAIService = OpenAIService()
    private let todoStore = TodoListStore.shared
    
    // Static flag to ensure we never register twice in the entire app lifecycle
    private static var hasRegisteredTasks = false
    
    init() {
        loadLastProcessingInfo()
    }
    
    // MARK: - Public Methods
    
    /// Initialize AI Agent Manager and register background tasks if needed
    func initializeIfNeeded() {
        // Ensure background tasks are registered (safe to call multiple times)
        registerBackgroundTasks()
        
        // If already enabled, schedule tasks
        if isEnabled {
            scheduleBackgroundTasks()
            print("🤖 AI Agent Mode: Re-scheduling tasks on app launch")
        }
    }
    
    /// Enable AI Agent Mode and schedule background tasks
    func enableAIAgentMode() {
        // Ensure background tasks are registered (safe to call multiple times)
        registerBackgroundTasks()
        
        // Enable and schedule
        isEnabled = true
        scheduleBackgroundTasks()
        
        print("🤖 AI Agent Mode: ENABLED")
    }
    
    /// Disable AI Agent Mode and cancel scheduled tasks
    func disableAIAgentMode() {
        isEnabled = false
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refineTasksIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.dailyAnalysisIdentifier)
        
        print("🤖 AI Agent Mode: DISABLED")
    }
    
    /// Manually trigger AI processing (for testing or immediate refinement)
    func processNow() async {
        await performTaskRefinement()
    }
    
    // MARK: - Background Task Registration
    
    private func registerBackgroundTasks() {
        // Only register if not already registered (prevents crash)
        guard !Self.hasRegisteredTasks else {
            print("🤖 Background tasks already registered, skipping")
            return
        }
        
        // Register task refinement (runs every few hours)
        let refineRegistered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refineTasksIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundTaskRefinement(task: task as! BGProcessingTask)
        }
        
        // Register daily analysis (runs once per day)
        let dailyRegistered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.dailyAnalysisIdentifier,
            using: nil
        ) { task in
            self.handleDailyAnalysis(task: task as! BGProcessingTask)
        }
        
        if refineRegistered && dailyRegistered {
            Self.hasRegisteredTasks = true
            print("🤖 Background tasks registered successfully")
        } else {
            print("🤖 Warning: Failed to register some background tasks")
            print("🤖 Refine task registered: \(refineRegistered)")
            print("🤖 Daily task registered: \(dailyRegistered)")
        }
    }
    
    // MARK: - Task Scheduling
    
    private func scheduleBackgroundTasks() {
        scheduleTaskRefinement()
        scheduleDailyAnalysis()
    }
    
    private func scheduleTaskRefinement() {
        let request = BGProcessingTaskRequest(identifier: Self.refineTasksIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        // Run every 4 hours
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("🤖 Scheduled task refinement for ~4 hours from now")
        } catch {
            print("🤖 Failed to schedule task refinement: \(error)")
        }
    }
    
    private func scheduleDailyAnalysis() {
        let request = BGProcessingTaskRequest(identifier: Self.dailyAnalysisIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        // Schedule for 6 AM tomorrow
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 0
        
        if let scheduledDate = calendar.date(from: components),
           scheduledDate <= Date() {
            // If 6 AM already passed today, schedule for tomorrow
            request.earliestBeginDate = calendar.date(byAdding: .day, value: 1, to: scheduledDate)
        } else {
            request.earliestBeginDate = calendar.date(from: components)
        }
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("🤖 Scheduled daily analysis for 6 AM")
        } catch {
            print("🤖 Failed to schedule daily analysis: \(error)")
        }
    }
    
    // MARK: - Background Task Handlers
    
    func handleBackgroundTaskRefinement(task: BGProcessingTask) {
        // Schedule the next occurrence
        scheduleTaskRefinement()
        
        // Create a task to monitor for expiration
        let processingTask = Task {
            await performTaskRefinement()
            task.setTaskCompleted(success: true)
        }
        
        // Handle task expiration
        task.expirationHandler = {
            processingTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    func handleDailyAnalysis(task: BGProcessingTask) {
        // Schedule the next occurrence
        scheduleDailyAnalysis()
        
        // Create a task to monitor for expiration
        let processingTask = Task {
            await performDailyAnalysis()
            task.setTaskCompleted(success: true)
        }
        
        // Handle task expiration
        task.expirationHandler = {
            processingTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    // MARK: - AI Processing Logic
    
    private func performTaskRefinement() async {
        print("🤖 Starting AI task refinement...")
        
        let tasks = todoStore.items
        guard !tasks.isEmpty else { return }
        
        // Build a comprehensive task summary for AI analysis
        let taskSummary = tasks.map { task in
            """
            Task: \(task.text)
            Priority: \(task.priority?.description ?? "Not set")
            Estimated Duration: \(task.estimatedDuration ?? "Not set")
            Difficulty: \(task.difficulty?.rawValue ?? "Not set")
            Category: \(task.category ?? "None")
            Project: \(task.projectOrPath ?? "None")
            Completed: \(task.isDone)
            Created: \(task.dateCreated.formatted())
            """
        }.joined(separator: "\n\n")
        
        // Create AI prompt for task refinement
        let systemPrompt = """
        You are Bryan's Brain - an AI productivity coach specializing in ADHD time-blocking and executive function support. Your goal is to transform a chaotic task list into a structured, time-blocked productivity system.

        ## ADHD Time-Blocking Philosophy:
        - **Time Blindness Compensation**: Always overestimate by 25-50% for ADHD brains
        - **Context Switching Cost**: Add 5-15 min buffers between different types of tasks
        - **Energy Management**: Consider cognitive load and when tasks should be scheduled
        - **Dopamine Optimization**: Break overwhelming tasks into quick wins + longer focus blocks
        - **Executive Function Load**: Assess decision-making complexity vs routine execution

        ## Your Analysis Framework:

        ### 1. TIME ESTIMATION (Critical for ADHD)
        - **Quick tasks (5-15 min)**: Email, calls, simple decisions
        - **Focus blocks (25-45 min)**: Deep work, writing, coding  
        - **Power sessions (60-90 min)**: Complex projects, creative work
        - **Buffer time**: Always add 25% for ADHD time blindness
        - **Transition time**: 5-15 min between different task types

        ### 2. TASK BREAKDOWN STRATEGY
        Identify tasks that need decomposition:
        - Anything over 90 minutes → break into smaller chunks
        - Vague tasks → create specific, actionable steps
        - Multi-step processes → separate planning from execution
        - Each subtask should have clear success criteria

        ### 3. DIFFICULTY ASSESSMENT
        - **Low**: Routine, clear steps, minimal decisions
        - **Medium**: Some complexity, moderate focus required
        - **High**: Complex thinking, many decisions, deep focus

        ### 4. CATEGORIZATION FOR TIME BLOCKING
        - **Deep Work**: Requires sustained focus, minimal interruptions
        - **Admin**: Quick tasks, can be batched together
        - **Creative**: Best when energy is high, needs inspiration
        - **Social**: Calls, meetings, interactions
        - **Physical**: Movement-based, can boost energy

        ### 5. ENERGY OPTIMIZATION
        Consider when tasks should be scheduled:
        - **Morning**: High-focus work, important decisions
        - **Afternoon**: Admin, routine tasks, meetings
        - **Evening**: Planning, reflection, low-cognitive load

        Return detailed analysis as JSON:
        {
            "refinements": [
                {
                    "taskText": "exact task text",
                    "suggestions": {
                        "estimatedDuration": "realistic time with ADHD buffer (e.g., '45 min + 10 min buffer')",
                        "difficulty": "Low/Medium/High with explanation",
                        "category": "suggested category for time blocking",
                        "breakDown": ["specific actionable subtasks"] (if task > 90 min or vague),
                        "timeBlockingNote": "when this should be scheduled and why",
                        "energyRequirement": "High/Medium/Low cognitive load",
                        "batchingOpportunity": "tasks that could be grouped together",
                        "contextSwitchingCost": "Low/Medium/High - how much mental effort to start"
                    }
                }
            ],
            "timeBlockingInsights": {
                "overallAssessment": "analysis of the entire task list structure",
                "timeBlockingSuggestions": "specific recommendations for organizing the day",
                "adhd_optimizations": "specific tips for executive function challenges",
                "energyManagement": "recommendations for scheduling based on cognitive load",
                "quickWins": "tasks that could provide dopamine boost",
                "focusBlocks": "suggestions for deep work sessions"
            }
        }
        """
        
        let messages: [OpenAIService.ChatMessage] = [
            .init(role: "system", content: systemPrompt),
            .init(role: "user", content: "Here are my current tasks:\n\n\(taskSummary)")
        ]
        
        // Call OpenAI for analysis
        let result = await openAIService.processConversation(messages: messages)
        
        switch result {
        case .success(let responseText):
            await processAIRefinements(responseText)
        case .toolCall(_):
            print("🤖 Unexpected tool call in refinement")
        case .failure(let error):
            print("🤖 AI refinement failed: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    private func performDailyAnalysis() async {
        print("🤖 Starting daily AI analysis...")
        
        let tasks = todoStore.items
        let incompleteTasks = tasks.filter { !$0.isDone }
        let completedToday = tasks.filter { task in
            task.isDone && Calendar.current.isDateInToday(task.dateCreated)
        }
        
        let analysisPrompt = """
        Analyze this ADHD user's task list and provide a personalized daily plan:
        
        Incomplete tasks: \(incompleteTasks.count)
        Completed today: \(completedToday.count)
        
        Focus on:
        1. What are the 3 most important tasks for today?
        2. Suggested order based on cognitive load and energy patterns
        3. Which tasks could be "quick wins" to build momentum?
        4. Any tasks that have been lingering too long?
        5. Encouraging message tailored to ADHD challenges
        
        Keep the response concise and actionable.
        """
        
        let messages: [OpenAIService.ChatMessage] = [
            .init(role: "system", content: "You are Bryan's Brain, an ADHD-specialized productivity coach. Provide warm, encouraging, and practical daily guidance."),
            .init(role: "user", content: analysisPrompt)
        ]
        
        let result = await openAIService.processConversation(messages: messages)
        
        switch result {
        case .success(let insights):
            await MainActor.run {
                self.latestInsights = insights
                self.lastProcessingDate = Date()
                self.saveProcessingInfo()
            }
            
            // TODO: Could send a notification with key insights
            print("🤖 Daily analysis complete!")
            
        case .toolCall(_), .failure(_):
            print("🤖 Daily analysis failed")
        }
    }
    
    private func processAIRefinements(_ jsonResponse: String) async {
        // Parse JSON response and apply refinements
        guard let data = jsonResponse.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let refinements = json["refinements"] as? [[String: Any]] else {
            print("🤖 Failed to parse AI refinements: \(jsonResponse.prefix(200))")
            return
        }
        
        var updateCount = 0
        var analysisResults: [String] = []
        
        for refinement in refinements {
            guard let taskText = refinement["taskText"] as? String,
                  let suggestions = refinement["suggestions"] as? [String: Any],
                  let task = todoStore.items.first(where: { $0.text == taskText }) else {
                continue
            }
            
            var taskUpdates: [String] = []
            
            // Apply duration estimate (with ADHD buffer time)
            if let duration = suggestions["estimatedDuration"] as? String,
               task.estimatedDuration == nil || task.estimatedDuration?.isEmpty == true {
                todoStore.updateTaskDuration(description: task.text, duration: duration)
                taskUpdates.append("Duration: \(duration)")
                updateCount += 1
            }
            
            // Apply difficulty with context
            if let difficultyStr = suggestions["difficulty"] as? String {
                // Extract just the difficulty level (Low/Medium/High) if it includes explanation
                let difficultyLevel = difficultyStr.components(separatedBy: " ").first ?? difficultyStr
                if let difficulty = Difficulty(rawValue: difficultyLevel),
                   task.difficulty == nil {
                    todoStore.updateTaskDifficulty(description: task.text, difficulty: difficulty)
                    taskUpdates.append("Difficulty: \(difficulty.rawValue)")
                    updateCount += 1
                }
            }
            
            // Apply category for time blocking
            if let category = suggestions["category"] as? String,
               task.category == nil || task.category?.isEmpty == true {
                todoStore.updateTaskCategory(description: task.text, category: category)
                taskUpdates.append("Category: \(category)")
                updateCount += 1
            }
            
            // Log comprehensive analysis for this task
            var taskAnalysis = "📋 \(taskText):"
            if !taskUpdates.isEmpty {
                taskAnalysis += " \(taskUpdates.joined(separator: ", "))"
            }
            
            // Add time blocking insights
            if let timeBlockingNote = suggestions["timeBlockingNote"] as? String {
                taskAnalysis += "\n   ⏰ Timing: \(timeBlockingNote)"
            }
            
            if let energyReq = suggestions["energyRequirement"] as? String {
                taskAnalysis += "\n   🔋 Energy: \(energyReq)"
            }
            
            if let contextCost = suggestions["contextSwitchingCost"] as? String {
                taskAnalysis += "\n   🔄 Context Switch: \(contextCost)"
            }
            
            if let breakDown = suggestions["breakDown"] as? [String], !breakDown.isEmpty {
                taskAnalysis += "\n   🔨 Breakdown needed: \(breakDown.count) subtasks"
                // TODO: Could actually create subtasks here in the future
            }
            
            analysisResults.append(taskAnalysis)
        }
        
        // Process comprehensive time-blocking insights
        var comprehensiveInsights = "🤖 AI Agent Analysis Complete!\n\n"
        comprehensiveInsights += "📊 Updates Applied: \(updateCount) task improvements\n\n"
        
        if let timeBlockingInsights = json["timeBlockingInsights"] as? [String: Any] {
            if let overallAssessment = timeBlockingInsights["overallAssessment"] as? String {
                comprehensiveInsights += "📈 Overall Assessment:\n\(overallAssessment)\n\n"
            }
            
            if let timeBlockingSuggestions = timeBlockingInsights["timeBlockingSuggestions"] as? String {
                comprehensiveInsights += "🕐 Time Blocking Strategy:\n\(timeBlockingSuggestions)\n\n"
            }
            
            if let adhdOptimizations = timeBlockingInsights["adhd_optimizations"] as? String {
                comprehensiveInsights += "🧠 ADHD Optimizations:\n\(adhdOptimizations)\n\n"
            }
            
            if let energyManagement = timeBlockingInsights["energyManagement"] as? String {
                comprehensiveInsights += "⚡ Energy Management:\n\(energyManagement)\n\n"
            }
            
            if let quickWins = timeBlockingInsights["quickWins"] as? String {
                comprehensiveInsights += "🎯 Quick Wins:\n\(quickWins)\n\n"
            }
            
            if let focusBlocks = timeBlockingInsights["focusBlocks"] as? String {
                comprehensiveInsights += "🎯 Focus Blocks:\n\(focusBlocks)\n\n"
            }
        }
        
        // Add individual task analysis
        if !analysisResults.isEmpty {
            comprehensiveInsights += "📋 Individual Task Analysis:\n"
            comprehensiveInsights += analysisResults.joined(separator: "\n\n")
        }
        
        // Save comprehensive insights
        let finalInsights = comprehensiveInsights
        await MainActor.run {
            self.latestInsights = finalInsights
            self.lastProcessingDate = Date()
            self.saveProcessingInfo()
        }
        
        print("🤖 ADHD Time-Blocking Analysis Complete!")
        print("📊 Applied \(updateCount) metadata updates")
        print("📝 Generated comprehensive time-blocking insights")
        
        // Log detailed analysis to console for debugging
        print("\n" + comprehensiveInsights)
    }
    
    // MARK: - Persistence
    
    private func saveProcessingInfo() {
        UserDefaults.standard.set(lastProcessingDate, forKey: Self.lastProcessingDateKey)
        UserDefaults.standard.set(latestInsights, forKey: Self.processingInsightsKey)
    }
    
    private func loadLastProcessingInfo() {
        lastProcessingDate = UserDefaults.standard.object(forKey: Self.lastProcessingDateKey) as? Date
        latestInsights = UserDefaults.standard.string(forKey: Self.processingInsightsKey) ?? ""
    }
}

// MARK: - Debug Commands for Testing

#if DEBUG
extension AIAgentManager {
    /// Simulate background task execution for testing
    func simulateBackgroundTask() {
        print("🤖 DEBUG: Simulating background task...")
        Task {
            await performTaskRefinement()
        }
    }
    
    /// Force schedule tasks immediately for testing
    func forceScheduleNow() {
        let request = BGProcessingTaskRequest(identifier: Self.refineTasksIdentifier)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10) // 10 seconds
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("🤖 DEBUG: Scheduled task for 10 seconds from now")
        } catch {
            print("🤖 DEBUG: Failed to schedule: \(error)")
        }
    }
}
#endif