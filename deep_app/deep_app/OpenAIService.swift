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
            
            print("DEBUG: Loaded API Key directly from Secrets.plist found in Bundle (DEBUG build)")
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

    // Represents a single message in the chat conversation
    struct ChatMessage: Codable {
        let role: String // "user", "assistant", "system", or "tool"
        let content: String?
        let tool_calls: [ToolCall]? // Optional: AI requests tool usage
        let tool_call_id: String? // Optional: ID for tool response message
        
        // Initializer for simple text messages
        init(role: String, content: String) {
            self.role = role
            self.content = content
            self.tool_calls = nil
            self.tool_call_id = nil
        }
        
        // Initializer for tool response messages
        init(tool_call_id: String, content: String?) {
            self.role = "tool"
            self.content = content
            self.tool_calls = nil
            self.tool_call_id = tool_call_id
        }

        // ** NEW ** Initializer for assistant messages requesting tool calls
        init(role: String = "assistant", content: String? = nil, tool_calls: [ToolCall]?) {
            self.role = role
            self.content = content
            self.tool_calls = tool_calls
            self.tool_call_id = nil
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

    // Tool definition to be sent to OpenAI (Now an array containing one tool dictionary)
    private let addTaskTool: [[String: Any]] = [ // Explicit type [[String: Any]]
        [ // Start of the single tool dictionary in the array
            "type": "function",
            "function": [
                "name": "addTaskToList",
                "description": "Adds a task to the user's to-do list.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "taskDescription": [
                            "type": "string",
                            "description": "A description of the task to be added."
                        ]
                    ],
                    "required": ["taskDescription"]
                ]
            ]
        ] // End of the single tool dictionary in the array
    ]
    
    // Structure for the request body sent to OpenAI (Only needs to be Encodable)
    private struct ChatRequest: Encodable { // Changed from Codable to Encodable
        let model: String
        let messages: [ChatMessage]
        let tools: [[String: AnyEncodable]]? // Correct type for encoded tools
        let tool_choice: String? // e.g., "auto"
        
        // Note: No custom CodingKeys or encode(to:) needed if default implementation works.
        // We might need it if AnyEncodable causes issues, but let's try without first.
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

    // Custom struct to help encode nested dictionaries/arrays with Any
    struct AnyEncodable: Encodable {
        let value: Any

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch value {
            case let value as String: try container.encode(value)
            case let value as Int: try container.encode(value)
            case let value as Double: try container.encode(value)
            case let value as Bool: try container.encode(value)
            // Correctly handle encoding dictionary: recursively wrap values
            case let value as [String: Any]: try container.encode(value.mapValues { AnyEncodable(value: $0) })
            // Correctly handle encoding array: recursively wrap elements
            case let value as [Any]: try container.encode(value.map { AnyEncodable(value: $0) })
            // Handle case where value might already be AnyEncodable (though less likely with [[String: Any]])
            case let value as AnyEncodable: try container.encode(value)
            default:
                // Simpler debug description string interpolation
                let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyEncodable value '\(value)' is not encodable.")
                throw EncodingError.invalidValue(value, context)
            }
        }
    }

    // MARK: - API Call Function
    
    // Define possible outcomes of the API call
    enum APIResult {
        case success(text: String)
        case toolCall(id: String, functionName: String, arguments: String)
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
        
        // Prepare tools for encoding by recursively wrapping values
        func encodeTools(_ tools: [[String: Any]]) -> [[String: AnyEncodable]] {
            return tools.map { toolDict in
                toolDict.mapValues { AnyEncodable(value: $0) }
            }
        }

        let encodableTools = encodeTools(addTaskTool) // Use helper func
        
        let requestBody = ChatRequest(model: "gpt-4o-mini",
                                      messages: messages,
                                      tools: encodableTools, // Send tool definition
                                      tool_choice: "auto") // Let AI decide when to use tool
        
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
        if let jsonString = String(data: encodedBody, encoding: .utf8) {
            print("--- OpenAI Request Body ---")
            print(jsonString)
            print("--------------------------")
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
            if let toolCalls = choice.message.tool_calls, let firstToolCall = toolCalls.first {
                print("DEBUG: AI requested tool call: \(firstToolCall.function.name)")
                return .toolCall(id: firstToolCall.id,
                                 functionName: firstToolCall.function.name,
                                 arguments: firstToolCall.function.arguments)
            }
            // Otherwise, return the regular text response
            else if let content = choice.message.content {
                print("DEBUG: AI returned text response.")
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