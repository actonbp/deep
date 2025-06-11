import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Foundation Model Tools for Bryan's Brain

/// This file contains all tool definitions for the Apple Foundation Models integration.
/// Each tool corresponds to an agent function from the OpenAI implementation.
@available(iOS 26.0, *)
enum FoundationModelTools {
    
    // MARK: - Task Management Tools
    
    struct AddTaskTool: Tool {
        let name = "addTaskToList"
        let description = "Add a new task to the to-do list. Arguments: taskDescription (required), projectOrPath (optional), category (optional)."
        
        struct Arguments: Codable {
            let taskDescription: String
            let projectOrPath: String?
            let category: String?
        }
        
        func call(_ args: Arguments) async throws -> String {
            await MainActor.run {
                let store = TodoListStore.shared
                store.addItem(
                    text: args.taskDescription,
                    category: args.category,
                    projectOrPath: args.projectOrPath
                )
            }
            return "Task '\(args.taskDescription)' added successfully."
        }
    }
    
    struct ListTasksTool: Tool {
        let name = "listCurrentTasks"
        let description = "List all current to-do tasks with their details including completion status, priority, and metadata."
        
        struct Arguments: Codable {} // No arguments needed
        
        func call(_ args: Arguments) async throws -> String {
            let items = await MainActor.run { TodoListStore.shared.items }
            
            if items.isEmpty {
                return "You have no tasks in your to-do list."
            }
            
            var result = "Here are your current tasks:\n\n"
            for (index, item) in items.enumerated() {
                let status = item.isComplete ? "✓" : "○"
                let priority = index + 1
                var taskLine = "\(priority). \(status) \(item.title)"
                
                // Add metadata if present
                var metadata: [String] = []
                if let duration = item.estimatedDuration {
                    metadata.append("Duration: \(duration)")
                }
                if let project = item.projectOrPath {
                    metadata.append("Project: \(project)")
                }
                if let category = item.category {
                    metadata.append("Category: \(category)")
                }
                if let difficulty = item.difficulty {
                    metadata.append("Difficulty: \(difficulty.rawValue)")
                }
                if !metadata.isEmpty {
                    taskLine += " [\(metadata.joined(separator: ", "))]"
                }
                
                result += taskLine + "\n"
            }
            
            return result
        }
    }
    
    struct RemoveTaskTool: Tool {
        let name = "removeTaskFromList"
        let description = "Remove a specific task from the to-do list based on its description."
        
        struct Arguments: Codable {
            let taskDescription: String
        }
        
        func call(_ args: Arguments) async throws -> String {
            let result = await MainActor.run { () -> String in
                let store = TodoListStore.shared
                if let item = store.items.first(where: { $0.title == args.taskDescription }) {
                    store.removeItem(item)
                    return "Task '\(args.taskDescription)' removed successfully."
                } else {
                    return "Could not find task: '\(args.taskDescription)'"
                }
            }
            return result
        }
    }
    
    struct UpdateTaskPrioritiesTool: Tool {
        let name = "updateTaskPriorities"
        let description = "Update the priority order of tasks. Provide an array of task descriptions ordered from highest to lowest priority."
        
        struct Arguments: Codable {
            let orderedTaskDescriptions: [String]
        }
        
        func call(_ args: Arguments) async throws -> String {
            let result = await MainActor.run { () -> String in
                let store = TodoListStore.shared
                
                // Verify all tasks exist
                for taskDesc in args.orderedTaskDescriptions {
                    if !store.items.contains(where: { $0.title == taskDesc }) {
                        return "Error: Task '\(taskDesc)' not found in the list."
                    }
                }
                
                // Reorder based on provided order
                var reorderedItems: [TodoItem] = []
                
                // First, add items in the specified order
                for taskDesc in args.orderedTaskDescriptions {
                    if let item = store.items.first(where: { $0.title == taskDesc }) {
                        reorderedItems.append(item)
                    }
                }
                
                // Then add any remaining items not in the list
                for item in store.items {
                    if !reorderedItems.contains(where: { $0.id == item.id }) {
                        reorderedItems.append(item)
                    }
                }
                
                // Update the store
                store.items = reorderedItems
                store.saveItems()
                
                return "Task priorities updated successfully."
            }
            return result
        }
    }
    
    struct MarkTaskCompleteTool: Tool {
        let name = "markTaskComplete"
        let description = "Mark a specific task as complete based on its description. The task remains in the list but is marked as done."
        
        struct Arguments: Codable {
            let taskDescription: String
        }
        
        func call(_ args: Arguments) async throws -> String {
            let result = await MainActor.run { () -> String in
                let store = TodoListStore.shared
                if let item = store.items.first(where: { $0.title == args.taskDescription }) {
                    store.markTaskComplete(taskId: item.id)
                    return "Task '\(args.taskDescription)' marked as complete."
                } else {
                    return "Could not find task: '\(args.taskDescription)'"
                }
            }
            return result
        }
    }
    
    // MARK: - Task Metadata Tools
    
    struct UpdateTaskDurationTool: Tool {
        let name = "updateTaskEstimatedDuration"
        let description = "Update the estimated duration for a specific task. Duration should be a string like '~15 mins', '1 hour', 'quick'."
        
        struct Arguments: Codable {
            let taskDescription: String
            let estimatedDuration: String
        }
        
        func call(_ args: Arguments) async throws -> String {
            let result = await MainActor.run { () -> String in
                let store = TodoListStore.shared
                if let item = store.items.first(where: { $0.title == args.taskDescription }) {
                    store.updateTaskDuration(taskId: item.id, duration: args.estimatedDuration)
                    return "Updated duration for '\(args.taskDescription)' to \(args.estimatedDuration)."
                } else {
                    return "Could not find task: '\(args.taskDescription)'"
                }
            }
            return result
        }
    }
    
    struct UpdateTaskDifficultyTool: Tool {
        let name = "updateTaskDifficulty"
        let description = "Update the difficulty level for a task. Valid values: Low, Medium, High."
        
        struct Arguments: Codable {
            let taskDescription: String
            let difficulty: String
        }
        
        func call(_ args: Arguments) async throws -> String {
            let result = await MainActor.run { () -> String in
                let store = TodoListStore.shared
                
                // Parse difficulty
                guard let difficultyLevel = Difficulty(rawValue: args.difficulty) else {
                    return "Invalid difficulty level. Use: Low, Medium, or High."
                }
                
                if let item = store.items.first(where: { $0.title == args.taskDescription }) {
                    store.updateTaskDifficulty(taskId: item.id, difficulty: difficultyLevel)
                    return "Updated difficulty for '\(args.taskDescription)' to \(args.difficulty)."
                } else {
                    return "Could not find task: '\(args.taskDescription)'"
                }
            }
            return result
        }
    }
    
    struct UpdateTaskCategoryTool: Tool {
        let name = "updateTaskCategory"
        let description = "Set or clear the category for a task (e.g., Research, Teaching, Life)."
        
        struct Arguments: Codable {
            let taskDescription: String
            let category: String?
        }
        
        func call(_ args: Arguments) async throws -> String {
            let result = await MainActor.run { () -> String in
                let store = TodoListStore.shared
                if let item = store.items.first(where: { $0.title == args.taskDescription }) {
                    let categoryValue = args.category?.isEmpty == true ? nil : args.category
                    store.updateTaskCategory(taskId: item.id, category: categoryValue)
                    if let cat = categoryValue {
                        return "Updated category for '\(args.taskDescription)' to '\(cat)'."
                    } else {
                        return "Cleared category for '\(args.taskDescription)'."
                    }
                } else {
                    return "Could not find task: '\(args.taskDescription)'"
                }
            }
            return result
        }
    }
    
    struct UpdateTaskProjectTool: Tool {
        let name = "updateTaskProjectOrPath"
        let description = "Set or clear the project/path for a task (e.g., 'Paper XYZ', 'LEAD 552')."
        
        struct Arguments: Codable {
            let taskDescription: String
            let projectOrPath: String?
        }
        
        func call(_ args: Arguments) async throws -> String {
            let result = await MainActor.run { () -> String in
                let store = TodoListStore.shared
                if let item = store.items.first(where: { $0.title == args.taskDescription }) {
                    let projectValue = args.projectOrPath?.isEmpty == true ? nil : args.projectOrPath
                    store.updateTaskProjectOrPath(taskId: item.id, projectOrPath: projectValue)
                    if let proj = projectValue {
                        return "Updated project for '\(args.taskDescription)' to '\(proj)'."
                    } else {
                        return "Cleared project for '\(args.taskDescription)'."
                    }
                } else {
                    return "Could not find task: '\(args.taskDescription)'"
                }
            }
            return result
        }
    }
    
    // MARK: - Calendar Tools
    
    struct GetCurrentDateTimeTool: Tool {
        let name = "getCurrentDateTime"
        let description = "Get the current date and time."
        
        struct Arguments: Codable {} // No arguments needed
        
        func call(_ args: Arguments) async throws -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .short
            formatter.timeZone = TimeZone.current
            
            let now = Date()
            let dateString = formatter.string(from: now)
            
            // Also provide day of week
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let dayOfWeek = dayFormatter.string(from: now)
            
            return "Current date and time: \(dateString) (\(dayOfWeek))"
        }
    }
    
    struct GetTodaysEventsTool: Tool {
        let name = "getTodaysCalendarEvents"
        let description = "Get the list of events scheduled on the user's primary Google Calendar for today."
        
        struct Arguments: Codable {} // No arguments needed
        
        func call(_ args: Arguments) async throws -> String {
            let service = CalendarService.shared
            
            do {
                let events = try await service.fetchEventsForToday()
                
                if events.isEmpty {
                    return "No events scheduled for today."
                }
                
                var result = "Today's calendar events:\n\n"
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formatter.dateStyle = .none
                
                for event in events.sorted(by: { $0.startDate < $1.startDate }) {
                    let startTime = formatter.string(from: event.startDate)
                    let endTime = formatter.string(from: event.endDate)
                    result += "• \(event.summary) (\(startTime) - \(endTime))\n"
                    if let description = event.eventDescription, !description.isEmpty {
                        result += "  Description: \(description)\n"
                    }
                }
                
                return result
            } catch {
                return "Unable to fetch calendar events. Please ensure you're signed in to Google Calendar."
            }
        }
    }
    
    struct CreateCalendarEventTool: Tool {
        let name = "createCalendarEvent"
        let description = "Create a new event on the user's primary Google Calendar for today. Times should be like '9:00 AM' or '14:30'."
        
        struct Arguments: Codable {
            let summary: String
            let startTimeToday: String
            let endTimeToday: String
            let description: String?
        }
        
        func call(_ args: Arguments) async throws -> String {
            let service = CalendarService.shared
            
            // Parse times
            guard let startDate = parseTimeToday(args.startTimeToday),
                  let endDate = parseTimeToday(args.endTimeToday) else {
                return "Error: Could not parse time. Use format like '9:00 AM' or '14:30'."
            }
            
            guard startDate < endDate else {
                return "Error: Start time must be before end time."
            }
            
            do {
                let eventId = try await service.createEvent(
                    summary: args.summary,
                    startDate: startDate,
                    endDate: endDate,
                    description: args.description
                )
                
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Created event '\(args.summary)' from \(formatter.string(from: startDate)) to \(formatter.string(from: endDate))."
            } catch {
                return "Failed to create calendar event: \(error.localizedDescription)"
            }
        }
        
        private func parseTimeToday(_ timeString: String) -> Date? {
            // Implementation would parse time strings like "9:00 AM" or "14:30"
            // and return a Date object for today at that time
            // This is a simplified placeholder
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            formatter.defaultDate = Date()
            if let time = formatter.date(from: timeString) {
                return time
            }
            
            formatter.dateFormat = "HH:mm"
            return formatter.date(from: timeString)
        }
    }
    
    // MARK: - All Available Tools
    
    /// Returns all available tools for the Foundation Model
    static func allTools() -> [any Tool] {
        return [
            // Task Management
            AddTaskTool(),
            ListTasksTool(),
            RemoveTaskTool(),
            UpdateTaskPrioritiesTool(),
            MarkTaskCompleteTool(),
            
            // Task Metadata
            UpdateTaskDurationTool(),
            UpdateTaskDifficultyTool(),
            UpdateTaskCategoryTool(),
            UpdateTaskProjectTool(),
            
            // Calendar
            GetCurrentDateTimeTool(),
            GetTodaysEventsTool(),
            CreateCalendarEventTool()
            
            // TODO: Add remaining tools:
            // - DeleteCalendarEventTool
            // - UpdateCalendarEventTimeTool
            // - GenerateTaskSummaryTool
            // - EnrichTaskMetadataTool
            // - GenerateProjectEmojiTool
            // - OrganizeAndCleanupTool
            // - BreakDownTaskTool
        ]
    }
}

// MARK: - Tool Protocol (Placeholder)

#if canImport(FoundationModels)
// This will be replaced by the actual Tool protocol from FoundationModels
protocol Tool {
    associatedtype Arguments: Codable
    var name: String { get }
    var description: String { get }
    func call(_ arguments: Arguments) async throws -> String
}
#endif 