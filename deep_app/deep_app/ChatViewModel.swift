import Foundation
import SwiftUI

// ChatViewModel to manage the state of the chat interface
@available(iOS 16.0, *)
class ChatViewModel: ObservableObject, @unchecked Sendable {
    // The OpenAI service for API calls
    private let openAIService = OpenAIService()
    // Use the shared singleton TodoListStore instance
    private var todoListStore = TodoListStore.shared
    
    // Published properties that SwiftUI views can observe
    @Published var messages: [ChatMessageItem] = []
    @Published var newMessageText: String = ""
    @Published var isLoading: Bool = false
    
    // Add suggested prompts
    let suggestedPrompts: [String] = [
        "Remind me to call Mom this week",
        "I need to buy groceries",
        "What are my top priorities?", // Placeholder for future feature
        "Help me brainstorm ideas for project X", // Placeholder
        "Schedule workout for tomorrow morning"
    ]
    
    // A representation of a chat message in the UI
    struct ChatMessageItem: Identifiable, Equatable {
        let id = UUID()
        let content: String?
        let role: MessageRole
        let timestamp: Date
        let toolCallId: String? // Added for tool responses
        let toolCalls: [OpenAIService.ToolCall]? // Added for assistant requests

        // Initializer for user/system/simple assistant messages
        init(content: String, role: MessageRole, timestamp: Date = Date()) {
            self.content = content
            self.role = role
            self.timestamp = timestamp
            self.toolCallId = nil // Default nil
            self.toolCalls = nil  // Default nil
        }

        // Initializer for assistant messages requesting tool calls
        init(content: String? = nil, role: MessageRole = .assistant, toolCalls: [OpenAIService.ToolCall], timestamp: Date = Date()) {
            self.content = content // OpenAI allows null content with tool calls
            self.role = role
            self.timestamp = timestamp
            self.toolCallId = nil
            self.toolCalls = toolCalls // Store tool calls
        }

        // Initializer for tool response messages
        init(content: String, role: MessageRole = .tool, toolCallId: String, timestamp: Date = Date()) {
            self.content = content
            self.role = role
            self.timestamp = timestamp
            self.toolCallId = toolCallId // Store tool call ID
            self.toolCalls = nil
        }
        
        // Implement Equatable (simple ID check is likely sufficient for UI updates)
        static func == (lhs: ChatMessageItem, rhs: ChatMessageItem) -> Bool {
            lhs.id == rhs.id
        }

        // Helper to convert to OpenAIService ChatMessage (Handles all cases)
        var toOpenAIMessage: OpenAIService.ChatMessage {
            switch role {
            case .tool:
                // Requires toolCallId to be non-nil, enforced by initializer
                guard let toolCallId = toolCallId else {
                    fatalError("Tool message item created without toolCallId") 
                }
                // Use the correct init, which accepts optional content
                return OpenAIService.ChatMessage(tool_call_id: toolCallId, content: content) 
            case .assistant:
                // Use the new init for assistant messages with tool calls
                // It handles optional content correctly.
                return OpenAIService.ChatMessage(role: role.rawValue, content: content, tool_calls: toolCalls)
            default: // .user, .system
                // Use the simple init, ensuring non-optional content is passed.
                // Provide an empty string if content is nil (API requires content for user/system).
                return OpenAIService.ChatMessage(role: role.rawValue, content: content ?? "")
            }
        }
    }
    
    // Roles for messages
    enum MessageRole: String {
        case user
        case assistant
        case system
        case tool // Added for tool results
    }
    
    // Initialize with a system message
    init() {
        messages = [
            ChatMessageItem(
                content: "You are Bryan's Brain, a helpful assistant. Analyze the user's messages. If you detect a potential task the user needs to do, use the provided 'addTaskToList' tool **immediately** to add it to their to-do list. Prioritize adding the task quickly based on the user's intent, even if details like specific times are missing. Add the core task; details can be clarified later if needed.", 
                role: .system
            )
        ]
    }
    
    // Function to send a message and process response
    func processUserInput() async {
        guard !newMessageText.isEmpty, !isLoading else { return }
        
        let textToSend = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSend.isEmpty else { return }
        
        // Add user message immediately
        let userMessage = ChatMessageItem(content: textToSend, role: .user)
        await MainActor.run { [weak self] in
            self?.messages.append(userMessage)
            self?.newMessageText = ""
            self?.isLoading = true
        }
        
        // Start the conversation processing loop
        await continueConversation() 
    }
    
    // Handles calling the API and processing results, including tool calls
    private func continueConversation() async {
        // Prepare messages for API using the updated toOpenAIMessage
        let apiMessages = await MainActor.run { [weak self] in 
            self?.messages.map { $0.toOpenAIMessage } ?? [] 
        }
        
        // Ensure loading indicator is shown before API call
        await MainActor.run { [weak self] in 
            if self?.isLoading == false {
                 self?.isLoading = true
            }    
        }

        let result = await openAIService.processConversation(messages: apiMessages)
        
        // Stop loading indicator *before* processing result / potential next step
        await MainActor.run { [weak self] in
            self?.isLoading = false
        }

        switch result {
        case .success(let text):
            // Add standard assistant text response
            let assistantMessage = ChatMessageItem(content: text, role: .assistant)
            await MainActor.run { [weak self] in
                self?.messages.append(assistantMessage)
            }

        case .toolCall(let id, let functionName, let arguments):
            print("DEBUG: Handling tool call: \(functionName)")
            
            // --- Crucial Change --- 
            // Get the *last* message (which should be the assistant's request)
            // We need its tool_calls array to store it correctly.
            // NOTE: This assumes the API *always* returns tool_calls in the *last* message choice.
            guard let lastApiMessageChoice = apiMessages.last, 
                  let assistantToolCalls = lastApiMessageChoice.tool_calls else {
                print("Error: Could not find tool_calls in the last API message for tool call handling.")
                // Handle error appropriately - maybe add an error message to UI
                return 
            }
            
            // Create and store the Assistant message that *requested* the tool call
            let assistantRequestMessage = ChatMessageItem(role: .assistant, toolCalls: assistantToolCalls)
            await MainActor.run { [weak self] in
                // Optional: Decide if you want to display anything for this message item
                // E.g., self?.messages.append(ChatMessageItem(content: "(Using tool: \(functionName)...)", role: .assistant))
                // For now, let's just store it internally without UI representation if content is nil/empty
                // Or maybe add it to the list so the history is complete for the *next* call
                 self?.messages.append(assistantRequestMessage) 
            }
            // ----------------------

            // Handle the specific tool call
            if functionName == "addTaskToList" {
                await handleAddTaskToolCall(id: id, arguments: arguments)
            } else {
                // Handle unknown tool call
                print("Warning: Received unknown tool call: \(functionName)")
                // Create the tool response *item*
                let toolResponseItem = ChatMessageItem(content: "{\"error\": \"Unknown function\"}", role: .tool, toolCallId: id)
                await MainActor.run { [weak self] in 
                    self?.messages.append(toolResponseItem) 
                }
                await continueConversation() // Trigger next step with updated history
            }

        case .failure(let error):
            // Handle API error
            let errorMessage = ChatMessageItem(content: "Sorry, an error occurred: \(error?.localizedDescription ?? "Unknown error")", role: .assistant)
            await MainActor.run { [weak self] in
                self?.messages.append(errorMessage)
            }
        }
    }

    // Specific handler for the addTaskToList tool
    private func handleAddTaskToolCall(id: String, arguments: String) async {
        // Decode the arguments JSON string
        guard let argsData = arguments.data(using: .utf8), 
              let decodedArgs = try? JSONDecoder().decode(OpenAIService.AddTaskArguments.self, from: argsData) else {
            print("Error: Failed to decode arguments for addTaskToList: \(arguments)")
            // Create the tool response *item* for the error
            let toolResponseItem = ChatMessageItem(content: "{\"error\": \"Invalid arguments\"}", role: .tool, toolCallId: id)
            await MainActor.run { [weak self] in 
                self?.messages.append(toolResponseItem) 
            }
            await continueConversation() // Trigger next step
            return
        }
        
        let taskDescription = decodedArgs.taskDescription
        print("DEBUG [ViewModel]: Adding task via function call: \(taskDescription)")
        
        // Add the item using the store
        await MainActor.run { // Ensure store modification happens on main thread if needed
            todoListStore.addItem(text: taskDescription)
        }
        
        // Create the tool response *item* for success
        let toolResponseItem = ChatMessageItem(content: "Task added successfully.", role: .tool, toolCallId: id)
        await MainActor.run { [weak self] in 
            self?.messages.append(toolResponseItem) 
        }
        // Trigger the next step in the conversation, sending the tool result back to the AI
        await continueConversation()
    }
} 