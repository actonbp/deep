import Foundation

// Service class to interact with the OpenAI API
class OpenAIService {

    // Get the API key by reading Secrets.plist directly (DEBUG ONLY)
    private func getAPIKey() -> String? {
        #if DEBUG
        // Try finding Secrets.plist within the main app bundle
        guard let secretsPlistPath = Bundle.main.path(forResource: "Secrets", ofType: "plist") else {
            print("Error: Could not find Secrets.plist in the main app bundle.")
            print("       Ensure Secrets.plist is added to the project and has Target Membership for 'deep_app'.")
            assertionFailure("Secrets.plist not found in main bundle during debug build.")
            return nil
        }
        
        guard FileManager.default.fileExists(atPath: secretsPlistPath) else {
            // This check is somewhat redundant if Bundle.main.path found it, but good for sanity
            print("Error: Secrets.plist path found but file doesn't exist at: \(secretsPlistPath). This should not happen.")
            assertionFailure("Secrets.plist path found but file doesn't exist?!?")
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: secretsPlistPath))
            guard let dict = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                  let apiKey = dict["OpenAIAPIKey"] as? String,
                  !apiKey.isEmpty,
                  !apiKey.contains("PASTE_YOUR") else { // Check for placeholder or missing key
                print("Error: Could not find 'OpenAIAPIKey' key in Secrets.plist or it's empty/placeholder.")
                assertionFailure("API Key missing or placeholder in Secrets.plist")
                return nil
            }
            
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [OpenAIService]: Loaded API Key directly from Secrets.plist (DEBUG build)")
            }
            // print("DEBUG: Key starts with \(String(apiKey.prefix(4))), ends with \(String(apiKey.suffix(4)))")
            return apiKey // apiKey is now in scope here
            
        } catch {
            print("Error reading or parsing Secrets.plist from bundle path: \(error)")
            assertionFailure("Failed to read/parse Secrets.plist from bundle path: \(error)")
            return nil
        }
        #else
        // RELEASE BUILDS: This method WILL NOT WORK.
        // You MUST implement a secure way to provide the key in Release builds,
        // e.g., fetching from a secure server or using a properly configured Info.plist via build settings.
        print("FATAL ERROR: Direct Secrets.plist reading is only supported in DEBUG builds.")
        print("           Configure secure key management for RELEASE builds.")
        fatalError("API Key management for Release builds not implemented.")
        #endif
    }
    
    // MARK: - Data Structures for OpenAI API

    // --- Explicit Encodable Structs for Tool Definition ---
    struct Tool: Encodable {
        let type: String = "function"
        let function: FunctionDefinition
    }

    struct FunctionDefinition: Encodable {
        let name: String
        let description: String
        let parameters: ParametersDefinition
    }

    struct ParametersDefinition: Encodable {
        let type: String = "object"
        let properties: [String: PropertyDefinition]
        let required: [String]? // Optional for functions with no required params
    }

    struct PropertyDefinition: Encodable {
        let type: String
        let description: String
        let items: ItemsDefinition? // Optional for non-array types
    }
    
    struct ItemsDefinition: Encodable { // Used for array items
        let type: String
    }
    // ----------------------------------------------------
    
    // Represents a single message in the chat conversation
    struct ChatMessage: Codable {
        let role: String // "user", "assistant", "system", or "tool"
        let content: String?
        let tool_calls: [ToolCall]? // Optional: AI requests tool usage
        let tool_call_id: String? // Optional: ID for tool response message
        let name: String? // Added: Name of the function for tool role messages
        
        // Initializer for simple text messages
        init(role: String, content: String) {
            self.role = role
            self.content = content
            self.tool_calls = nil
            self.tool_call_id = nil
            self.name = nil // Ensure name is nil for non-tool messages
        }
        
        // Initializer for tool response messages (now includes name)
        init(tool_call_id: String, name: String, content: String?) {
            self.role = "tool"
            self.content = content
            self.tool_calls = nil
            self.tool_call_id = tool_call_id
            self.name = name // Set the function name
        }

        // ** NEW ** Initializer for assistant messages requesting tool calls
        init(role: String = "assistant", content: String? = nil, tool_calls: [ToolCall]?) {
            self.role = role
            self.content = content
            self.tool_calls = tool_calls
            self.tool_call_id = nil
            self.name = nil // Ensure name is nil
        }
    }

    // Represents a tool call requested by the AI
    struct ToolCall: Codable {
        let id: String
        let type: String // Should be "function"
        let function: FunctionCall
    }

    // Represents the function details in a tool call
    struct FunctionCall: Codable {
        let name: String
        let arguments: String // Arguments are a JSON string
    }

    // Arguments for the addTaskToList function
    struct AddTaskArguments: Codable {
        let taskDescription: String
    }

    // Arguments for createCalendarEvent function
    struct CreateCalendarEventArguments: Decodable { // Needs to be Decodable only
        let summary: String
        let startTimeToday: String // e.g., "9:00 AM", "14:30"
        let endTimeToday: String   // e.g., "10:30 AM", "15:00"
        let description: String? // Optional
    }

    // --- Tool Definitions using Explicit Structs ---
    
    // addTaskTool remains an array because the API expects an array of tools,
    // even if we often conceptualize it as a single tool definition here.
    // We'll construct the single Tool object within the array.
    private let addTaskToolDefinition = FunctionDefinition(
        name: "addTaskToList",
        description: "Adds a task to the user's to-do list.",
        parameters: .init(
            properties: [
                "taskDescription": .init(type: "string", description: "A description of the task to be added.", items: nil)
            ],
            required: ["taskDescription"]
        )
    )

    private let listTasksToolDefinition = FunctionDefinition(
        name: "listCurrentTasks",
        description: "Gets the current list of tasks from the user's to-do list.",
        parameters: .init(properties: [:], required: nil) // No properties or required fields
    )
    
    private let removeTaskToolDefinition = FunctionDefinition(
        name: "removeTaskFromList",
        description: "Removes a specific task from the user's to-do list based on its description.",
        parameters: .init(
            properties: [
                "taskDescription": .init(type: "string", description: "The exact description of the task to remove.", items: nil)
            ],
            required: ["taskDescription"]
        )
    )
    
    private let updateDurationToolDefinition = FunctionDefinition(
        name: "updateTaskEstimatedDuration",
        description: "Updates the estimated duration for a specific task on the to-do list.",
        parameters: .init(
            properties: [
                "taskDescription": .init(type: "string", description: "The description of the task whose duration needs to be updated.", items: nil),
                "estimatedDuration": .init(type: "string", description: "The estimated duration for the task (e.g., '~15 mins', '1 hour', 'quick').", items: nil)
            ],
            required: ["taskDescription", "estimatedDuration"]
        )
    )
    
    private let updatePrioritiesToolDefinition = FunctionDefinition(
        name: "updateTaskPriorities",
        description: "Updates the priority order of tasks in the to-do list.",
        parameters: .init(
            properties: [
                "orderedTaskDescriptions": .init(
                    type: "array",
                    description: "An array of task description strings, ordered from highest priority (index 0) to lowest.",
                    items: .init(type: "string") // Specify item type for array
                )
            ],
            required: ["orderedTaskDescriptions"]
        )
    )
    
    private let createEventToolDefinition = FunctionDefinition(
        name: "createCalendarEvent",
        description: "Creates a new event on the user's primary Google Calendar for today.",
        parameters: .init(
            properties: [
                "summary": .init(type: "string", description: "The title or summary of the event.", items: nil),
                "startTimeToday": .init(type: "string", description: "The start time for today's event (e.g., '9:00 AM', '14:30').", items: nil),
                "endTimeToday": .init(type: "string", description: "The end time for today's event (e.g., '10:30 AM', '15:00').", items: nil),
                "description": .init(type: "string", description: "An optional longer description for the event.", items: nil)
            ],
            required: ["summary", "startTimeToday", "endTimeToday"]
        )
    )
    
    private let getEventsToolDefinition = FunctionDefinition(
        name: "getTodaysCalendarEvents",
        description: "Gets the list of events scheduled on the user's primary Google Calendar for today.",
        parameters: .init(properties: [:], required: nil) // No properties or required fields
    )
    
    // --- ADDED: getCurrentDateTime Tool Definition ---
    private let getCurrentDateTimeToolDefinition = FunctionDefinition(
        name: "getCurrentDateTime",
        description: "Gets the current date and time.",
        parameters: .init(properties: [:], required: nil) // No parameters needed
    )
    // ---------------------------------------------
    
    // --- ADDED: deleteCalendarEvent Tool Definition ---
    private let deleteCalendarEventToolDefinition = FunctionDefinition(
        name: "deleteCalendarEvent",
        description: "Deletes a specific event from the user's primary Google Calendar for today, identified by its summary and start time.",
        parameters: .init(
            properties: [
                "summary": .init(type: "string", description: "The title or summary of the event to delete.", items: nil),
                "startTimeToday": .init(type: "string", description: "The original start time of the event to delete (e.g., '9:00 AM', '14:30').", items: nil)
            ],
            required: ["summary", "startTimeToday"]
        )
    )
    // -----------------------------------------------

    // --- ADDED: updateCalendarEventTime Tool Definition ---
    private let updateCalendarEventTimeToolDefinition = FunctionDefinition(
        name: "updateCalendarEventTime",
        description: "Updates the start and/or end time of a specific event on the user's primary Google Calendar for today.",
        parameters: .init(
            properties: [
                "summary": .init(type: "string", description: "The title or summary of the event to update.", items: nil),
                "originalStartTimeToday": .init(type: "string", description: "The original start time of the event being updated (e.g., '9:00 AM', '14:30').", items: nil),
                "newStartTimeToday": .init(type: "string", description: "The new start time for the event (e.g., '10:00 AM', '15:30').", items: nil),
                "newEndTimeToday": .init(type: "string", description: "The new end time for the event (e.g., '11:00 AM', '16:00').", items: nil)
            ],
            required: ["summary", "originalStartTimeToday", "newStartTimeToday", "newEndTimeToday"]
        )
    )
    // ----------------------------------------------------
    
    // Combined list of all available tools (now as Tool structs)
    private var allTools: [Tool] { 
        return [
            .init(function: addTaskToolDefinition),
            .init(function: listTasksToolDefinition),
            .init(function: removeTaskToolDefinition),
            .init(function: updatePrioritiesToolDefinition),
            .init(function: updateDurationToolDefinition),
            .init(function: createEventToolDefinition),
            .init(function: getEventsToolDefinition),
            .init(function: getCurrentDateTimeToolDefinition),
            .init(function: deleteCalendarEventToolDefinition), // <-- Added delete tool
            .init(function: updateCalendarEventTimeToolDefinition) // <-- Added update tool
        ]
    }

    // Structure for the request body sent to OpenAI (Only needs to be Encodable)
    private struct ChatRequest: Encodable { // Changed from Codable to Encodable
        let model: String
        let messages: [ChatMessage]
        let tools: [Tool]? // <-- Now uses the explicit Tool struct
        let tool_choice: String? // e.g., "auto"
    }

    // Structure to decode the response from OpenAI
    private struct ChatResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let role: String
                let content: String?
                let tool_calls: [ToolCall]?
            }
            let message: Message
            let finish_reason: String // e.g., "stop", "tool_calls"
        }
        let choices: [Choice]
    }

    // MARK: - API Call Function
    
    // Define possible outcomes of the API call
    enum APIResult {
        case success(text: String)
        case toolCall(toolCalls: [ToolCall])
        case failure(error: Error?)
    }
    
    // Modified function to handle text response or tool calls
    func processConversation(messages: [ChatMessage]) async -> APIResult {
        guard let apiKey = getAPIKey() else {
            print("Error: API Key could not be retrieved.")
            return .failure(error: nil) // Consider a specific error type
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Error: Invalid URL")
            return .failure(error: nil)
        }
        
        let requestBody = ChatRequest(model: "gpt-4o-mini",
                                      messages: messages,
                                      tools: allTools, // <-- Pass the [Tool] array directly
                                      tool_choice: "auto")
        
        // Use default JSONEncoder if no special strategies are needed
        let encoder = JSONEncoder()
        // Optional: Uncomment for pretty printing the request body during debug
        // encoder.outputFormatting = .prettyPrinted 
        
        guard let encodedBody = try? encoder.encode(requestBody) else {
            print("Error: Failed to encode request body")
            // Optionally print the error: print("Encoding error: \\(error)")
            return .failure(error: nil) // Or pass the specific encoding error
        }
        
        // Debug print the request body JSON string
        #if DEBUG
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
            if let jsonString = String(data: encodedBody, encoding: .utf8) {
                print("--- OpenAI Request Body ---")
                print(jsonString)
                print("--------------------------")
            }
        }
        #endif

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = encodedBody
        request.timeoutInterval = 30
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("Error: HTTP Status Code \(httpResponse.statusCode)")
                // TODO: Decode potential error body from OpenAI
                return .failure(error: nil)
            }
            
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            
            guard let choice = chatResponse.choices.first else {
                print("Error: No choice found in OpenAI response")
                return .failure(error: nil)
            }
            
            // Check if the AI requested a tool call
            if let toolCalls = choice.message.tool_calls, !toolCalls.isEmpty {
                if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                    print("DEBUG [OpenAIService]: AI requested tool call(s): \(toolCalls.map { $0.function.name })")
                }
                // Pass the whole toolCalls array back
                return .toolCall(toolCalls: toolCalls)
            }
            // Otherwise, return the regular text response
            else if let content = choice.message.content {
                if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                    print("DEBUG [OpenAIService]: AI returned text response.")
                }
                return .success(text: content)
            } else {
                print("Error: No content or tool call in AI response")
                return .failure(error: nil)
            }
            
        } catch {
            print("Error making or decoding API call: \(error)")
            return .failure(error: error)
        }
    }
} 