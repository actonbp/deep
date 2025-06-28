/*
Bryan's Brain - Safe Response Tool

Abstract:
Tool designed to provide safe, positive responses to queries that might trigger Apple's safety guardrails.
Uses supportive, productivity-focused language to minimize rejection risk.
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct SafeResponseTool: Tool {
    let name = "provideHelpfulGuidance"
    let description = "Provides positive, supportive guidance for productivity and organization"
    
    @Generable
    struct Arguments {
        @Guide(description: "The type of guidance needed: motivation, planning, organization, or general")
        let guidanceType: String
        
        @Guide(description: "Optional context about what the user is working on")
        let context: String?
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 SafeResponseTool: Providing guidance: \(arguments.guidanceType)")
        
        let output: String
        switch arguments.guidanceType.lowercased() {
        case "motivation":
            output = "You're doing great by taking steps to stay organized! Every small action toward your goals is progress worth celebrating. What would you like to focus on next?"
            
        case "planning":
            output = "Great question about planning! Breaking things down into small, manageable steps is key to success. Would you like help organizing your thoughts or priorities?"
            
        case "organization":
            output = "Organization is such a valuable skill! The fact that you're thinking about staying organized shows you're on the right track. What aspect of organization would be most helpful right now?"
            
        case "general":
            let contextNote = arguments.context ?? "your productivity goals"
            output = "I'm here to help you succeed with \(contextNote)! Staying focused and organized is a wonderful approach. What specific area would you like to work on together?"
            
        default:
            output = "I'm here to support your productivity and organization goals in a positive way! What would be most helpful for you right now - planning, organizing, or getting motivated?"
        }
        
        Logging.general.log("SafeResponseTool: Returning supportive guidance")
        return ToolOutput(output)
    }
}