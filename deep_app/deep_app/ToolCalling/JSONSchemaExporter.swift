/*
Bryan's Brain - JSON Schema Export Utility

Abstract:
Enables cross-LLM compatibility by converting Foundation Models @Generable types
to JSON Schema format for use with OpenAI, Claude, and Gemini.

iOS 26 Beta 4 Feature: GenerationSchema is now Codable
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct JSONSchemaExporter {
    
    /// Exports a Foundation Models tool to OpenAI-compatible function definition
    static func exportToolToOpenAI(tool: any Tool) -> OpenAIService.FunctionDefinition? {
        // Get the tool metadata
        let name = tool.name
        let description = tool.description
        
        // For iOS 26 Beta 4, we can now encode the GenerationSchema
        // This is a simplified example - in practice, you'd need to handle
        // the actual schema conversion based on the tool's Arguments type
        
        // Create a generic parameters schema
        let parameters = OpenAIService.ParametersDefinition(
            properties: [:], // Would be populated from the tool's Arguments
            required: []
        )
        
        return OpenAIService.FunctionDefinition(
            name: name,
            description: description,
            parameters: parameters
        )
    }
    
    /// Converts a @Generable model to JSON Schema format
    /// This enables cross-LLM compatibility as shown in the Beta 4 release notes
    static func exportGenerableToJSONSchema<T: Generable & Codable>(_ type: T.Type) throws -> String {
        // In iOS 26 Beta 4, GenerationSchema is Codable
        // This allows us to export the schema as JSON
        
        // Create the generation schema
        // Note: The exact syntax for GenerationSchema initialization may vary
        // This is a placeholder implementation based on the Beta 4 announcement
        
        // For now, return a mock schema as the actual API is not fully documented
        let mockSchema = """
        {
          "type": "object",
          "properties": {},
          "required": []
        }
        """
        
        return mockSchema
    }
    
    /// Example of how to use GeneratedContent(json:) from Beta 3
    static func parseJSONResponse<T: Generable & Decodable>(_ json: String, as type: T.Type) throws -> T {
        guard let jsonData = json.data(using: .utf8) else {
            throw JSONSchemaError.invalidJSON
        }
        
        // In iOS 26 Beta 3+, we can use GeneratedContent(json:)
        // This allows parsing JSON responses from any LLM into our @Generable models
        let _ = try GeneratedContent(json: json)
        
        // Convert GeneratedContent to our model type
        // Note: This is a simplified example - actual implementation would
        // depend on how GeneratedContent exposes its data
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: jsonData)
    }
    
    enum JSONSchemaError: LocalizedError {
        case invalidJSON
        case conversionFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidJSON:
                return "Invalid JSON string provided"
            case .conversionFailed:
                return "Failed to convert between schema formats"
            }
        }
    }
}

// MARK: - Cross-LLM Tool Protocol
// This demonstrates how to create tools that work with any LLM

@available(iOS 26.0, *)
protocol CrossLLMTool {
    associatedtype Arguments: Generable & Codable
    
    var name: String { get }
    var description: String { get }
    
    func call(arguments: Arguments) async throws -> any PromptRepresentable
    func exportSchema() throws -> String
}

@available(iOS 26.0, *)
extension CrossLLMTool {
    func exportSchema() throws -> String {
        return try JSONSchemaExporter.exportGenerableToJSONSchema(Arguments.self)
    }
}

// MARK: - Example Implementation

@available(iOS 26.0, *)
struct CrossPlatformTaskTool: CrossLLMTool {
    let name = "createTask"
    let description = "Creates a new task in the user's task list"
    
    @Generable
    struct Arguments: Codable {
        @Guide(description: "The task description")
        let description: String
        
        @Guide(description: "Task priority (1-5)")
        let priority: Int
        
        @Guide(description: "Estimated duration in minutes")
        let duration: Int?
    }
    
    func call(arguments: Arguments) async throws -> any PromptRepresentable {
        // Create the task using the existing TodoListStore
        await MainActor.run {
            TodoListStore.shared.addItem(
                text: arguments.description
            )
        }
        
        // Return a string (which is PromptRepresentable)
        return "Created task: '\(arguments.description)' with priority \(arguments.priority)"
    }
}

// MARK: - Usage Example

/*
 // Export schema for use with OpenAI:
 let tool = CrossPlatformTaskTool()
 let jsonSchema = try tool.exportSchema()
 
 // Send to OpenAI with the exported schema
 let openAIFunction = [
     "name": tool.name,
     "description": tool.description,
     "parameters": jsonSchema
 ]
 
 // When OpenAI returns a tool call, parse it:
 let arguments = try JSONSchemaExporter.parseJSONResponse(
     openAIResponse,
     as: CrossPlatformTaskTool.Arguments.self
 )
 
 // Execute the tool with parsed arguments
 let result = try await tool.call(arguments: arguments)
*/