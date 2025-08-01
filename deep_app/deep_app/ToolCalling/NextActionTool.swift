/*
Bryan's Brain - Next Action Tool

Abstract:
ADHD-focused tool that suggests ONE specific next action when users are overwhelmed.
Prevents task creation loops and focuses on existing tasks.
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct NextActionTool: Tool {
    let name = "suggestNextAction"
    let description = "Suggests ONE specific next action when feeling overwhelmed or stuck"
    
    @Generable
    struct Arguments {
        @Guide(description: "User's current energy level: low, medium, or high")
        let energyLevel: String?
        
        @Guide(description: "Available time in minutes (optional)")
        let availableMinutes: Int?
    }
    
    func call(arguments: Arguments) async -> String {
        print("🎯 NextActionTool: Finding next action for overwhelmed user")
        
        // Get existing tasks
        let tasks = await MainActor.run {
            TodoListStore.shared.items.filter { !$0.isDone }
        }
        
        guard !tasks.isEmpty else {
            return """
            Great news! You have no pending tasks. This is a perfect time to:
            • Take a well-deserved break
            • Plan something fun
            • Or add a new goal if you're feeling motivated
            
            What would feel good right now?
            """
        }
        
        // Filter by energy level if provided
        let energyLevel = arguments.energyLevel?.lowercased() ?? "medium"
        let availableTime = arguments.availableMinutes ?? 30
        
        // Find best task based on energy and time
        let suitableTasks = tasks.filter { task in
            // Check difficulty matches energy
            let difficultyMatch: Bool
            switch (task.difficulty?.rawValue.lowercased(), energyLevel) {
            case ("low", _), (nil, _):
                difficultyMatch = true // Low difficulty works for any energy
            case ("medium", "medium"), ("medium", "high"):
                difficultyMatch = true
            case ("high", "high"):
                difficultyMatch = true
            default:
                difficultyMatch = false
            }
            
            // Check time estimate if available
            let timeMatch: Bool
            if let duration = task.estimatedDuration,
               let minutes = parseDuration(duration) {
                timeMatch = minutes <= availableTime
            } else {
                timeMatch = true // No estimate means we assume it fits
            }
            
            return difficultyMatch && timeMatch
        }
        
        // Pick the best task
        let selectedTask = suitableTasks.first ?? tasks.first!
        
        // Create motivating response
        let energyNote: String
        switch energyLevel {
        case "low":
            energyNote = "Since your energy is low, I picked something manageable."
        case "high":
            energyNote = "You've got good energy - let's tackle something meaningful!"
        default:
            energyNote = "This task is a good fit for your current state."
        }
        
        let timeNote = selectedTask.estimatedDuration != nil 
            ? "Estimated time: \(selectedTask.estimatedDuration!)"
            : "No time estimate yet - start with just 10 minutes"
        
        return """
        🎯 Your Next Action:
        
        **\(selectedTask.text)**
        
        \(energyNote)
        \(timeNote)
        
        Remember: Starting is the hardest part. Even 5 minutes of progress counts!
        
        Ready to begin? I'm here if you need me to break this down further.
        """
    }
    
    private func parseDuration(_ duration: String) -> Int? {
        // Simple parsing for common formats
        if duration.contains("min") {
            return Int(duration.replacingOccurrences(of: "min", with: "").trimmingCharacters(in: .whitespaces))
        } else if duration.contains("hour") {
            if let hours = Int(duration.replacingOccurrences(of: "hour", with: "").replacingOccurrences(of: "s", with: "").trimmingCharacters(in: .whitespaces)) {
                return hours * 60
            }
        }
        return nil
    }
}

// Companion tool for when users need smaller steps
@available(iOS 26.0, *)
struct MicroStepTool: Tool {
    let name = "createMicroStep"
    let description = "Breaks current task into one tiny 5-minute action"
    
    @Generable
    struct Arguments {
        @Guide(description: "The task that feels too big")
        let taskText: String
    }
    
    func call(arguments: Arguments) async -> String {
        print("🔍 MicroStepTool: Breaking down overwhelming task")
        
        // Generate a micro-step based on task type
        let task = arguments.taskText.lowercased()
        
        let microStep: String
        if task.contains("write") || task.contains("draft") {
            microStep = "Open the document and write just the first sentence"
        } else if task.contains("email") || task.contains("message") {
            microStep = "Open your email and type just the subject line"
        } else if task.contains("call") || task.contains("phone") {
            microStep = "Find the phone number and add it to your contacts"
        } else if task.contains("research") || task.contains("read") {
            microStep = "Open one browser tab and bookmark the first relevant article"
        } else if task.contains("organize") || task.contains("clean") {
            microStep = "Set a 5-minute timer and organize just what's in arm's reach"
        } else if task.contains("plan") || task.contains("schedule") {
            microStep = "Open your calendar and pick just one time slot"
        } else {
            microStep = "Spend 5 minutes gathering what you need to start"
        }
        
        return """
        🐣 Micro-Step for "\(arguments.taskText)":
        
        **\(microStep)**
        
        That's it! Just this one tiny thing. Once you do this micro-step:
        • You've broken the inertia
        • Your brain will often want to continue
        • But if not, that's okay too - you still made progress!
        
        Ready? Set a 5-minute timer and go! 🚀
        """
    }
}