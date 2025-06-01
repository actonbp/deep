import Foundation
import SwiftUI

// ChatViewModel to manage the state of the chat interface
@available(iOS 16.0, *)
class ChatViewModel: ObservableObject, @unchecked Sendable {
    // The OpenAI service for API calls
    private let openAIService = OpenAIService()
    // Use the shared singleton TodoListStore instance
    private var todoListStore = TodoListStore.shared
    
    // --- ADDED: UserDefaults key for saving messages ---
    private let messagesSaveKey = "chatMessagesHistory"
    // ---------------------------------------------------
    
    // Published properties that SwiftUI views can observe
    @Published var messages: [ChatMessageItem] = [] {
        didSet {
            saveMessages()
        }
    }
    @Published var newMessageText: String = ""
    @Published var isLoading: Bool = false
    
    // Add suggested prompts - prioritizing "getting started" guidance
    let suggestedPrompts: [String] = [
        "I don't know where to start",
        "Help me get unstuck",
        "What should I do next?",
        "Plan my day",
        "What's on my calendar today?",
        "Estimate task times"
    ]
    
    // A representation of a chat message in the UI
    struct ChatMessageItem: Identifiable, Equatable, Codable {
        let id: UUID
        let content: String?
        let role: MessageRole
        let timestamp: Date
        let toolCallId: String?
        let functionName: String?
        let toolCalls: [OpenAIService.ToolCall]?

        enum CodingKeys: String, CodingKey {
            case id, content, role, timestamp, toolCallId, functionName, toolCalls
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            content = try container.decodeIfPresent(String.self, forKey: .content)
            role = try container.decode(MessageRole.self, forKey: .role)
            timestamp = try container.decode(Date.self, forKey: .timestamp)
            toolCallId = try container.decodeIfPresent(String.self, forKey: .toolCallId)
            functionName = try container.decodeIfPresent(String.self, forKey: .functionName)
            toolCalls = try container.decodeIfPresent([OpenAIService.ToolCall].self, forKey: .toolCalls)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(content, forKey: .content)
            try container.encode(role, forKey: .role)
            try container.encode(timestamp, forKey: .timestamp)
            try container.encodeIfPresent(toolCallId, forKey: .toolCallId)
            try container.encodeIfPresent(functionName, forKey: .functionName)
            try container.encodeIfPresent(toolCalls, forKey: .toolCalls)
        }

        init(id: UUID = UUID(), content: String, role: MessageRole, timestamp: Date = Date()) {
            self.id = id
            self.content = content
            self.role = role
            self.timestamp = timestamp
            self.toolCallId = nil
            self.toolCalls = nil
            self.functionName = nil
        }

        init(id: UUID = UUID(), content: String? = nil, role: MessageRole = .assistant, toolCalls: [OpenAIService.ToolCall], timestamp: Date = Date()) {
            self.id = id
            self.content = content
            self.role = role
            self.timestamp = timestamp
            self.toolCallId = nil
            self.toolCalls = toolCalls
            self.functionName = nil
        }

        init(id: UUID = UUID(), content: String, role: MessageRole = .tool, toolCallId: String, functionName: String, timestamp: Date = Date()) {
            self.id = id
            self.content = content
            self.role = role
            self.timestamp = timestamp
            self.toolCallId = toolCallId
            self.functionName = functionName
            self.toolCalls = nil
        }
        
        static func == (lhs: ChatMessageItem, rhs: ChatMessageItem) -> Bool {
            lhs.id == rhs.id
        }

        var toOpenAIMessage: OpenAIService.ChatMessage {
            switch role {
            case .tool:
                guard let toolCallId = toolCallId else { fatalError("Tool message item missing toolCallId") }
                guard let functionName = functionName else { fatalError("Tool message item missing functionName") }
                return OpenAIService.ChatMessage(tool_call_id: toolCallId, name: functionName, content: content) 
            case .assistant:
                return OpenAIService.ChatMessage(role: role.rawValue, content: content, tool_calls: toolCalls)
            default: // .user, .system
                return OpenAIService.ChatMessage(role: role.rawValue, content: content ?? "")
            }
        }
    }
    
    // Roles for messages
    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
        case tool
    }
    
    // Initialize with a system message AND load previous messages
    init() {
        loadMessages()
        updateSystemMessage()
        
        if messages.count == 1 && messages.first?.role == .system {
             addWelcomeMessage()
        }
    }
    
    // --- ADDED: Function to dynamically set system prompt ---
    func updateSystemMessage() {
        let areCategoriesEnabled = UserDefaults.standard.bool(forKey: AppSettings.enableCategoriesKey)
        var systemPromptContent = """
            You are Bryan's Brain, a supportive, optimistic, and action-oriented ADHD productivity coach. Your primary goal is to help the user capture thoughts, structure their day, prioritize tasks, and maintain momentum by focusing on the **next small step**.
            
            **SPECIAL GUIDANCE: "Getting Unstuck" Responses**
            When users say things like "I don't know where to start", "help me get unstuck", "what should I do next?", or express feeling overwhelmed:
            1. **First, check their context**: Use 'getTodaysCalendarEvents' and 'listCurrentTasks' to understand their current situation
            2. **Identify the smallest possible next step**: Break down overwhelming tasks into 5-minute actions
            3. **Offer specific, immediate actions**: Instead of general advice, suggest one concrete thing they can do right now
            4. **Acknowledge the feeling**: Validate that starting is hard, especially with ADHD
            5. **Use time-boxing**: Suggest "Just 15 minutes on..." to reduce pressure
            6. **Be encouraging**: Remind them that any progress counts
            """
            
        if areCategoriesEnabled {
            systemPromptContent += "\nTasks have metadata: `priority`, `estimatedDuration`, `difficulty` (Low, Medium, High), `dateCreated`, `category` (string), and `projectOrPath` (string)."
            systemPromptContent += "\nTools: 'addTaskToList' (takes optional projectOrPath, category), 'listCurrentTasks', 'removeTaskFromList', 'updateTaskPriorities', 'updateTaskEstimatedDuration', 'updateTaskDifficulty', 'updateTaskCategory', 'updateTaskProjectOrPath', 'markTaskComplete', 'createCalendarEvent', 'getTodaysCalendarEvents', 'deleteCalendarEvent', 'updateCalendarEventTime', 'getCurrentDateTime', 'generateTaskSummary'."
            systemPromptContent += "\nInstructions: \n1. **Capture & Structure:** When user mentions a task, check if similar exists (use `listCurrentTasks` if unsure). Ask user to clarify before adding. Use 'addTaskToList' (with optional project/category if mentioned) if confirmed new. \n2. **Metadata Handling:** After adding a task, OR **when user asks to 'guess' or 'set' metadata**, make reasonable guesses for any missing fields (`category`, `projectOrPath`, `difficulty`, `estimatedDuration`) based on context. Use the specific update tools (`updateTaskCategory`, `updateTaskProjectOrPath`, etc.) to apply these guesses/assignments. \n3. **Confirm Actions:** Always confirm task adds, removals, completions, and ANY metadata updates (including guesses you applied).\n4. **Prioritize:** Handle prioritization requests.\n5. **Action Focus:** Guide to next small action.\n6. **Check Calendar:** Use 'getTodaysCalendarEvents'.\n7. **Time Blocking:** Suggest schedule based on tasks & calendar. Ask to create events.\n8. **Tone:** Encouraging, optimistic, patient.\n9. **Current Time/Date:** Use 'getCurrentDateTime'.\n10. **Delete Event:** Use 'deleteCalendarEvent'.\n11. **Update Event Time:** Use 'updateCalendarEventTime'.\n12. **Mark Task Done:** Use 'markTaskComplete'.\n13. **Remove Task:** Use 'removeTaskFromList' only if explicitly asked.\n14. **Task Summaries:** For tasks with descriptions longer than 40 characters, proactively generate a 3-5 word summary using 'generateTaskSummary'. This helps the roadmap view stay readable. Only generate summaries for tasks that don't already have one."
        } else {
            systemPromptContent += "\nTasks have metadata: `priority`, `estimatedDuration`, `difficulty` (Low, Medium, High), `dateCreated`, and `projectOrPath` (string, e.g., Paper XYZ, LEAD 552)."
            systemPromptContent += "\nTools: 'addTaskToList' (takes optional projectOrPath), 'listCurrentTasks', 'removeTaskFromList', 'updateTaskPriorities', 'updateTaskEstimatedDuration', 'updateTaskDifficulty', 'updateTaskProjectOrPath', 'markTaskComplete', 'createCalendarEvent', 'getTodaysCalendarEvents', 'deleteCalendarEvent', 'updateCalendarEventTime', 'getCurrentDateTime', 'generateTaskSummary'."
            systemPromptContent += "\nInstructions: \n1. **Capture & Structure:** When user mentions a task, check if similar exists (use `listCurrentTasks` if unsure). Ask user to clarify before adding. Use 'addTaskToList' (with optional project if mentioned) if confirmed new. \n2. **Metadata Handling:** After adding a task, OR **when user asks to 'guess' or 'set' metadata**, make reasonable guesses for any missing fields (`projectOrPath`, `difficulty`, `estimatedDuration`) based on context. Use the specific update tools (`updateTaskProjectOrPath`, `updateTaskDifficulty`, etc.) to apply these guesses/assignments. \n3. **Confirm Actions:** Always confirm task adds, removals, completions, and ANY metadata updates (including guesses you applied).\n4. **Prioritize:** Handle prioritization requests.\n5. **Action Focus:** Guide to next small action.\n6. **Check Calendar:** Use 'getTodaysCalendarEvents'.\n7. **Time Blocking:** Suggest schedule based on tasks & calendar. Ask to create events.\n8. **Tone:** Encouraging, optimistic, patient.\n9. **Current Time/Date:** Use 'getCurrentDateTime'.\n10. **Delete Event:** Use 'deleteCalendarEvent'.\n11. **Update Event Time:** Use 'updateCalendarEventTime'.\n12. **Mark Task Done:** Use 'markTaskComplete'.\n13. **Remove Task:** Use 'removeTaskFromList' only if explicitly asked.\n14. **Task Summaries:** For tasks with descriptions longer than 40 characters, proactively generate a 3-5 word summary using 'generateTaskSummary'. This helps the roadmap view stay readable. Only generate summaries for tasks that don't already have one."
        }
        
        // Remove existing system message if it exists
        messages.removeAll { $0.role == .system }
        
        // Create and insert the new system message
        let systemMessage = ChatMessageItem(content: systemPromptContent, role: .system)
        messages.insert(systemMessage, at: 0)
        print("DEBUG [ViewModel]: System prompt updated. Categories Enabled: \(areCategoriesEnabled)")
    }
    // -----------------------------------------------------

    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessageItem(
            content: "Hey! I'm here to help you capture thoughts, manage tasks, and plan your day.\n\nFeeling stuck or don't know where to start? Just ask - I'm great at helping you find that first small step! What's on your mind?", 
            role: .assistant, 
            timestamp: Date()
        )
        DispatchQueue.main.async { [weak self] in
            self?.messages.append(welcomeMessage)
        }
    }
    
    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: messagesSaveKey)
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                 print("DEBUG [ViewModel]: Saved \(messages.count) messages.")
            }
        } else {
             print("ERROR [ViewModel]: Failed to encode messages for saving.")
        }
    }

    private func loadMessages() {
        guard let savedData = UserDefaults.standard.data(forKey: messagesSaveKey) else {
            print("DEBUG [ViewModel]: No saved messages found.")
            self.messages = [] 
            return
        }
        
        if let decodedMessages = try? JSONDecoder().decode([ChatMessageItem].self, from: savedData) {
            self.messages = decodedMessages
             print("DEBUG [ViewModel]: Loaded \(decodedMessages.count) messages.")
        } else {
            print("ERROR [ViewModel]: Failed to decode saved messages. Starting fresh.")
            self.messages = []
            UserDefaults.standard.removeObject(forKey: messagesSaveKey)
        }
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
        // --- Smarter History Truncation ---
        let maxRecentMessages = 20 // Target number of recent messages (flexible)
        let allMessages = await MainActor.run { messages } // Get current messages safely
        
        var messagesToSend: [OpenAIService.ChatMessage] = []
        var includedCount = 0
        var mandatoryInclusionNext = false // Flag to ensure assistant tool_call request is included

        // Iterate backwards through non-system messages
        for messageItem in allMessages.filter({ $0.role != .system }).reversed() {
            let apiMessage = messageItem.toOpenAIMessage
            
            // Ensure we don't exceed the limit unless mandatory inclusion is needed
            if includedCount >= maxRecentMessages && !mandatoryInclusionNext {
                break // Stop adding messages once limit is reached (unless required)
            }
            
            messagesToSend.append(apiMessage)
            includedCount += 1
            
            // If this is a tool response, mark that the previous message (assistant request) MUST be included
            if apiMessage.role == "tool" {
                mandatoryInclusionNext = true
            } 
            // If this is an assistant message with tool_calls, the mandate is fulfilled
            else if apiMessage.role == "assistant" && apiMessage.tool_calls != nil {
                mandatoryInclusionNext = false // Reset flag after including the required assistant message
            } 
            // For user messages or assistant messages without tool_calls, reset the flag
            else {
                 mandatoryInclusionNext = false
            }
        }
        
        // Reverse the selected messages to restore original order
        messagesToSend.reverse()
        
        // Prepend the system message if it exists
        if let systemMessageItem = allMessages.first(where: { $0.role == .system }) {
            messagesToSend.insert(systemMessageItem.toOpenAIMessage, at: 0)
        }
        
        let apiMessages = messagesToSend // Use the truncated list
        // ----------------------------------
        
        // Ensure loading indicator is shown before API call
        await MainActor.run { [weak self] in 
            if self?.isLoading == false {
                 self?.isLoading = true
            }    
        }

        // --- Logging before API Call ---
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
            print("DEBUG [ViewModel]: Sending \(apiMessages.count) messages to API...")
            // Optionally print the messages themselves if needed for deeper debugging
            // print(apiMessages)
        }
        // ------------------------------

        let result = await openAIService.processConversation(messages: apiMessages)
        
        // --- Logging after API Call ---
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
            print("DEBUG [ViewModel]: Received result from API: \(result)")
        }
        // -----------------------------

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

        case .toolCall(let toolCalls):
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [ViewModel]: Handling tool call(s) received from API: \(toolCalls.map { $0.function.name })")
            }
            
            // Create and store the Assistant message that *requested* the tool call(s)
            let assistantRequestMessage = ChatMessageItem(role: .assistant, toolCalls: toolCalls)
            await MainActor.run { [weak self] in
                 self?.messages.append(assistantRequestMessage) 
            }
            
            // --- Execute ALL requested tool calls using TaskGroup --- 
            var toolResponseItems: [ChatMessageItem] = [] // Array to hold results
            
            // Use TaskGroup to handle potential concurrency and collect results safely
            await withTaskGroup(of: ChatMessageItem.self) { group in
                for toolCall in toolCalls {
                    group.addTask { // Add each tool call handler as a task
                        let id = toolCall.id
                        let functionName = toolCall.function.name
                        let arguments = toolCall.function.arguments
                        
                        // Handle the specific tool call function and return the result message
                        // NOTE: The handler functions already RETURN the ChatMessageItem
                        let responseItem: ChatMessageItem
                        switch functionName {
                        case "addTaskToList":
                            responseItem = await self.handleAddTaskToolCall(id: id, functionName: functionName, arguments: arguments)
                        case "listCurrentTasks":
                            responseItem = await self.handleListTasksToolCall(id: id, functionName: functionName)
                        case "removeTaskFromList":
                            responseItem = await self.handleRemoveTaskToolCall(id: id, functionName: functionName, arguments: arguments)
                        case "updateTaskPriorities":
                            responseItem = await self.handleUpdatePrioritiesToolCall(id: id, functionName: functionName, arguments: arguments)
                        case "updateTaskEstimatedDuration":
                            responseItem = await self.handleUpdateDurationToolCall(id: id, functionName: functionName, arguments: arguments)
                        case "createCalendarEvent":
                            responseItem = await self.handleCreateCalendarEventToolCall(id: id, functionName: functionName, arguments: arguments)
                        case "getTodaysCalendarEvents":
                            responseItem = await self.handleGetTodaysCalendarEventsToolCall(id: id, functionName: functionName)
                        case "getCurrentDateTime":
                            responseItem = await self.handleGetCurrentDateTimeToolCall(id: id, functionName: functionName)
                        case "deleteCalendarEvent":
                            responseItem = await self.handleDeleteCalendarEventToolCall(id: id, functionName: functionName, arguments: arguments)
                        case "updateCalendarEventTime":
                            responseItem = await self.handleUpdateCalendarEventTimeToolCall(id: id, functionName: functionName, arguments: arguments)
                        case "markTaskComplete":
                            responseItem = await self.handleMarkTaskCompleteToolCall(id: id, functionName: functionName, arguments: arguments)
                        case "updateTaskDifficulty":
                            responseItem = await self.handleUpdateTaskDifficultyToolCall(id: id, functionName: functionName, arguments: arguments)
                        case "updateTaskCategory":
                            responseItem = await self.handleUpdateTaskCategoryToolCall(id: id, functionName: functionName, arguments: arguments)
                        case "updateTaskProjectOrPath":
                            responseItem = await self.handleUpdateTaskProjectOrPathToolCall(id: id, functionName: functionName, arguments: arguments)
                        case "generateTaskSummary":
                            responseItem = await self.handleGenerateTaskSummaryToolCall(id: id, functionName: functionName, arguments: arguments)
                        default:
                            // Handle unknown tool call
                            print("Warning: Received unknown tool call: \(functionName)")
                            responseItem = ChatMessageItem(content: "{\"error\": \"Unknown function '\(functionName)'\"}", role: .tool, toolCallId: id, functionName: functionName)
                        }
                        return responseItem // Return the result from the task
                    }
                }
                
                // Collect results from all tasks in the group
                for await result in group {
                    // No MainActor needed here as we collect results *after* tasks complete
                    toolResponseItems.append(result)
                }
            }
            // --------------------------------------------------------
            
            // --- Append ALL collected tool results AFTER the group finishes --- 
            await MainActor.run { [weak self] in
                self?.messages.append(contentsOf: toolResponseItems)
            }
            // -----------------------------------------
            
            // --- Continue conversation ONCE after ALL tool results are added --- 
            await continueConversation()
            // -----------------------------------------------------------------

        case .failure(let error):
            // Handle API error - IMPORTANT: DO NOT add this error message to the history sent back to OpenAI
            let errorMessageContent = "Sorry, an error occurred communicating with the AI: \(error?.localizedDescription ?? "Unknown error")"
            print("ERROR [ViewModel]: API call failed: \(errorMessageContent)")
            // Display the error to the user locally, but don't append it to the main message list
            // that gets sent back in subsequent API calls.
            // Maybe add a temporary error state property?
            // For now, just print it and stop the flow.
            // let localErrorMessage = ChatMessageItem(content: errorMessageContent, role: .assistant) // LOCAL DISPLAY ONLY
            // await MainActor.run { [weak self] in
            //    // self?.messages.append(localErrorMessage) // Don't add to history for OpenAI
            // }
            // Stop the conversation flow on API failure
            break 
        }
    }

    // --- MODIFY Tool Handlers to RETURN ChatMessageItem --- 
    
    // Specific handler for the addTaskToList tool
    private func handleAddTaskToolCall(id: String, functionName: String = "addTaskToList", arguments: String) async -> ChatMessageItem { // <-- Return Item
        // Decode the arguments JSON string
        guard let argsData = arguments.data(using: .utf8),
              let decodedArgs = try? JSONDecoder().decode(OpenAIService.AddTaskArguments.self, from: argsData) else {
            print("Error: Failed to decode arguments for addTaskToList: \(arguments)")
            let errorContent = "{\"error\": \"Invalid arguments for addTaskToList\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName) // <-- Return Error Item
        }
        
        let taskDescription = decodedArgs.taskDescription
        // --- Get optional metadata --- 
        let category = decodedArgs.category
        let project = decodedArgs.projectOrPath
        // ---------------------------
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
            // --- Update Debug Log --- 
            print("DEBUG [ViewModel]: Adding task via function call: \(taskDescription) [Category: \(category ?? "nil")] [Project: \(project ?? "nil")]")
            // ----------------------
        }
        
        // Add the item using the store, passing metadata
        await MainActor.run { 
            todoListStore.addItem(text: taskDescription, category: category, projectOrPath: project)
        }
        
        // Create and RETURN the tool response item
        return ChatMessageItem(content: "Task added successfully.", role: .tool, toolCallId: id, functionName: functionName) // <-- Return Success Item
    }

    // Modify listCurrentTasks handler
    private func handleListTasksToolCall(id: String, functionName: String = "listCurrentTasks") async -> ChatMessageItem { // <-- Return Item
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { print("DEBUG [ViewModel]: Getting task list via function call") }
        let taskListString = await MainActor.run { todoListStore.getFormattedTaskList() }
        return ChatMessageItem(content: taskListString, role: .tool, toolCallId: id, functionName: functionName) // <-- Return Item
    }

    // Modify removeTaskFromList handler
    private func handleRemoveTaskToolCall(id: String, functionName: String = "removeTaskFromList", arguments: String) async -> ChatMessageItem { // <-- Return Item
        struct RemoveTaskArgs: Codable { let taskDescription: String }
        guard let argsData = arguments.data(using: .utf8), let decodedArgs = try? JSONDecoder().decode(RemoveTaskArgs.self, from: argsData) else {
            print("Error: Failed to decode arguments for removeTaskFromList: \(arguments)")
            let errorContent = "{\"error\": \"Invalid arguments for removeTaskFromList\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        let taskDescription = decodedArgs.taskDescription
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { print("DEBUG [ViewModel]: Removing task via function call: \(taskDescription)") }
        let removed = await MainActor.run { todoListStore.removeTask(description: taskDescription) }
        let responseContent = removed ? "Task '\(taskDescription)' removed successfully." : "Task '\(taskDescription)' not found."
        return ChatMessageItem(content: responseContent, role: .tool, toolCallId: id, functionName: functionName) // <-- Return Item
    }

    // Modify updateTaskPriorities handler
    private func handleUpdatePrioritiesToolCall(id: String, functionName: String = "updateTaskPriorities", arguments: String) async -> ChatMessageItem { // <-- Return Item
        struct UpdatePrioritiesArgs: Codable { let orderedTaskDescriptions: [String] }
        guard let argsData = arguments.data(using: .utf8), let decodedArgs = try? JSONDecoder().decode(UpdatePrioritiesArgs.self, from: argsData) else {
            print("Error: Failed to decode arguments for updateTaskPriorities: \(arguments)")
            let errorContent = "{\"error\": \"Invalid arguments for updateTaskPriorities\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { print("DEBUG [ViewModel]: Updating priorities via function call: \(decodedArgs.orderedTaskDescriptions)") }
        await MainActor.run { todoListStore.updatePriorities(orderedTasks: decodedArgs.orderedTaskDescriptions) }
        return ChatMessageItem(content: "Task priorities updated successfully.", role: .tool, toolCallId: id, functionName: functionName) // <-- Return Item
    }
    
    // Modify updateTaskEstimatedDuration handler
    private func handleUpdateDurationToolCall(id: String, functionName: String = "updateTaskEstimatedDuration", arguments: String) async -> ChatMessageItem { // <-- Return Item
        struct UpdateDurationArgs: Codable { let taskDescription: String; let estimatedDuration: String }
        guard let argsData = arguments.data(using: .utf8), let decodedArgs = try? JSONDecoder().decode(UpdateDurationArgs.self, from: argsData) else {
            print("Error: Failed to decode arguments for updateTaskEstimatedDuration: \(arguments)")
            let errorContent = "{\"error\": \"Invalid arguments for updateTaskEstimatedDuration\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { print("DEBUG [ViewModel]: Updating duration for task '\(decodedArgs.taskDescription)' to '\(decodedArgs.estimatedDuration)' via function call.") }
        await MainActor.run { todoListStore.updateTaskDuration(description: decodedArgs.taskDescription, duration: decodedArgs.estimatedDuration) }
        return ChatMessageItem(content: "Task duration updated successfully.", role: .tool, toolCallId: id, functionName: functionName) // <-- Return Item
    }
    
    // Modify createCalendarEvent handler
    private func handleCreateCalendarEventToolCall(id: String, functionName: String = "createCalendarEvent", arguments: String) async -> ChatMessageItem { // <-- Return Item
        guard let argsData = arguments.data(using: .utf8), let decodedArgs = try? JSONDecoder().decode(OpenAIService.CreateCalendarEventArguments.self, from: argsData) else {
            print("Error: Failed to decode arguments for createCalendarEvent: \(arguments)")
            return ChatMessageItem(content: "{\"error\": \"Invalid arguments format for createCalendarEvent\"}", role: .tool, toolCallId: id, functionName: functionName)
        }
        
        // 2. Parse Time Strings and Combine with Today's Date
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX") // Use fixed locale for parsing
        // Allow parsing both "h:mm a" (9:00 AM) and "HH:mm" (14:30)
        timeFormatter.dateFormat = "h:mm a"
        let timeFormatter24 = DateFormatter()
        timeFormatter24.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter24.dateFormat = "HH:mm"
        
        guard let startTimeParsed = timeFormatter.date(from: decodedArgs.startTimeToday) ?? timeFormatter24.date(from: decodedArgs.startTimeToday),
              let endTimeParsed = timeFormatter.date(from: decodedArgs.endTimeToday) ?? timeFormatter24.date(from: decodedArgs.endTimeToday) else {
            print("Error: Failed to parse time strings: '\(decodedArgs.startTimeToday)' or '\(decodedArgs.endTimeToday)'")
            let errorContent = "{\"error\": \"Invalid time format. Expected formats like '9:00 AM' or '14:30'. Provided start: '\(decodedArgs.startTimeToday)', end: '\(decodedArgs.endTimeToday)'.\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        
        // Get components (hour, minute) from parsed times
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTimeParsed)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTimeParsed)
        
        // Get today's date components (year, month, day)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        
        // Combine today's date with parsed times
        var combinedStartComponents = todayComponents
        combinedStartComponents.hour = startComponents.hour
        combinedStartComponents.minute = startComponents.minute
        
        var combinedEndComponents = todayComponents
        combinedEndComponents.hour = endComponents.hour
        combinedEndComponents.minute = endComponents.minute
        
        guard let startTime = calendar.date(from: combinedStartComponents),
              let endTime = calendar.date(from: combinedEndComponents) else {
            print("Error: Failed to combine date and time components.")
             return ChatMessageItem(content: "{\"error\": \"Internal error combining date and time.\"}", role: .tool, toolCallId: id, functionName: functionName)
        }
        
        // Ensure end time is after start time (using combined dates)
        guard endTime > startTime else {
            print("Error: End time ('\(decodedArgs.endTimeToday)') must be after start time ('\(decodedArgs.startTimeToday)') on the same day.")
            let errorContent = "{\"error\": \"End time ('\(decodedArgs.endTimeToday)') must be after start time ('\(decodedArgs.startTimeToday)') on the same day.\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }

        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { print("DEBUG [ViewModel]: Calling CalendarService to create event: '\(decodedArgs.summary)' from \(startTime) to \(endTime)") }
        
        // Use a Task to bridge the callback to async/await style for returning the result
        return await Task<ChatMessageItem, Never> {            
            let calendarService = CalendarService()
            let (eventId, error) = await withCheckedContinuation { (continuation: CheckedContinuation<(String?, Error?), Never>) -> Void in
                calendarService.createCalendarEvent(summary: decodedArgs.summary, description: decodedArgs.description, startTime: startTime, endTime: endTime) { eventId, error in
                    continuation.resume(returning: (eventId, error))
                }
            }
            
            var responseContent: String
            if let error = error {
                print("Error creating calendar event: \(error.localizedDescription)")
                responseContent = "Failed to create calendar event: \(error.localizedDescription)"
            } else if let eventId = eventId {
                responseContent = "Calendar event '\(decodedArgs.summary)' created successfully (ID: \(eventId))."
            } else {
                responseContent = "Calendar event '\(decodedArgs.summary)' created successfully (ID not returned)."
            }
            return ChatMessageItem(content: responseContent, role: .tool, toolCallId: id, functionName: functionName)
        }.value
    }
    
    // Modify getTodaysCalendarEvents handler
    private func handleGetTodaysCalendarEventsToolCall(id: String, functionName: String = "getTodaysCalendarEvents") async -> ChatMessageItem { // <-- Return Item
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { print("DEBUG [ViewModel]: Getting today's calendar events via function call") }
        
        // Use a Task to bridge the callback
        return await Task<ChatMessageItem, Never> {            
            let calendarService = CalendarService()
            let (fetchedEvents, error) = await withCheckedContinuation { (continuation: CheckedContinuation<([CalendarEvent]?, Error?), Never>) -> Void in
                calendarService.fetchTodaysEvents { fetchedEvents, error in
                    continuation.resume(returning: (fetchedEvents, error))
                }
            }
            
            var responseContent: String
            if let error = error {
                print("Error fetching calendar events for AI: \(error.localizedDescription)")
                responseContent = "{\"error\": \"Could not fetch calendar events: \(error.localizedDescription)\"}"
            } else if let events = fetchedEvents, !events.isEmpty {
                responseContent = "Today\'s scheduled events:\n"
                for event in events {
                    responseContent += "- \(event.summary ?? "(No Title)"): \(event.startTimeString) - \(event.endTimeString)\n"
                }
            } else {
                responseContent = "No events found on the calendar for today."
            }
            return ChatMessageItem(content: responseContent, role: .tool, toolCallId: id, functionName: functionName)
        }.value
    }
    
    // --- Handler for getCurrentDateTime ---
    private func handleGetCurrentDateTimeToolCall(id: String, functionName: String = "getCurrentDateTime") async -> ChatMessageItem {
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { print("DEBUG [ViewModel]: Getting current date/time via function call") }
        
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d, yyyy h:mm a") 
        let now = Date()
        let dateTimeString = dateFormatter.string(from: now)
        let responseContent = "It is currently \(dateTimeString)."
        return ChatMessageItem(content: responseContent, role: .tool, toolCallId: id, functionName: functionName)
    }
    // -------------------------------------------
    
    // --- CORRECTED: Full Handler for deleteCalendarEvent ---
    private func handleDeleteCalendarEventToolCall(id: String, functionName: String = "deleteCalendarEvent", arguments: String) async -> ChatMessageItem {
        // 1. Decode Arguments
        struct DeleteEventArgs: Decodable {
            let summary: String
            let startTimeToday: String // e.g., "9:00 AM", "14:30"
        }
        
        guard let argsData = arguments.data(using: .utf8), 
              let decodedArgs = try? JSONDecoder().decode(DeleteEventArgs.self, from: argsData) else {
            print("Error: Failed to decode arguments for deleteCalendarEvent: \(arguments)")
            let errorContent = "{\"error\": \"Invalid arguments format for deleteCalendarEvent\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        
        // 2. Parse Time String
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX") // Fixed locale
        timeFormatter.dateFormat = "h:mm a" // AM/PM
        let timeFormatter24 = DateFormatter()
        timeFormatter24.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter24.dateFormat = "HH:mm" // 24-hour
        
        guard let startTimeParsed = timeFormatter.date(from: decodedArgs.startTimeToday) ?? timeFormatter24.date(from: decodedArgs.startTimeToday) else {
            print("Error: Failed to parse start time string for deletion: '\(decodedArgs.startTimeToday)'")
            let errorContent = "{\"error\": \"Invalid start time format for deletion. Expected formats like '9:00 AM' or '14:30'. Provided: '\(decodedArgs.startTimeToday)'.\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        
        // 3. Combine with Today's Date
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTimeParsed)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        var combinedStartComponents = todayComponents
        combinedStartComponents.hour = startComponents.hour
        combinedStartComponents.minute = startComponents.minute
        
        guard let startTime = calendar.date(from: combinedStartComponents) else {
            print("Error: Failed to combine date and time components for deletion.")
             return ChatMessageItem(content: "{\"error\": \"Internal error combining date and time for deletion.\"}", role: .tool, toolCallId: id, functionName: functionName)
        }

        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { 
            print("DEBUG [ViewModel]: Calling CalendarService to delete event: '\(decodedArgs.summary)' starting at \(startTime)") 
        }

        // 4. Call CalendarService and Handle Result
        return await Task<ChatMessageItem, Never> {            
            let calendarService = CalendarService()
            let (success, error) = await withCheckedContinuation { (continuation: CheckedContinuation<(Bool, Error?), Never>) -> Void in
                calendarService.deleteCalendarEvent(summary: decodedArgs.summary, startTime: startTime) { success, error in
                    continuation.resume(returning: (success, error))
                }
            }
            
            var responseContent: String
            if success {
                responseContent = "Event '\(decodedArgs.summary)' starting at \(decodedArgs.startTimeToday) deleted successfully."
            } else {
                let errorDescription = error?.localizedDescription ?? "Unknown error deleting event."
                print("Error deleting calendar event: \(errorDescription)")
                // Escape quotes within the error description for valid JSON in the response
                let escapedErrorDesc = errorDescription.replacingOccurrences(of: "\"", with: "\\\"")
                responseContent = "{\"error\": \"Failed to delete event '\(decodedArgs.summary)' starting at \(decodedArgs.startTimeToday). Reason: \(escapedErrorDesc)\"}" 
            }
            return ChatMessageItem(content: responseContent, role: .tool, toolCallId: id, functionName: functionName)
        }.value
    }
    // --------------------------------------------------------

    // --- CORRECTED: Full Handler for updateCalendarEventTime ---
    private func handleUpdateCalendarEventTimeToolCall(id: String, functionName: String = "updateCalendarEventTime", arguments: String) async -> ChatMessageItem {
        // 1. Decode Arguments
        struct UpdateTimeArgs: Decodable {
            let summary: String
            let originalStartTimeToday: String
            let newStartTimeToday: String
            let newEndTimeToday: String
        }
        
        guard let argsData = arguments.data(using: .utf8), 
              let decodedArgs = try? JSONDecoder().decode(UpdateTimeArgs.self, from: argsData) else {
            print("Error: Failed to decode arguments for updateCalendarEventTime: \(arguments)")
            let errorContent = "{\"error\": \"Invalid arguments format for updateCalendarEventTime\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        
        // 2. Parse Time Strings (Original Start, New Start, New End)
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "h:mm a"
        let timeFormatter24 = DateFormatter()
        timeFormatter24.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter24.dateFormat = "HH:mm"
        
        guard let originalStartTimeParsed = timeFormatter.date(from: decodedArgs.originalStartTimeToday) ?? timeFormatter24.date(from: decodedArgs.originalStartTimeToday), 
              let newStartTimeParsed = timeFormatter.date(from: decodedArgs.newStartTimeToday) ?? timeFormatter24.date(from: decodedArgs.newStartTimeToday), 
              let newEndTimeParsed = timeFormatter.date(from: decodedArgs.newEndTimeToday) ?? timeFormatter24.date(from: decodedArgs.newEndTimeToday) else {
            print("Error: Failed to parse one or more time strings for update: Original='\(decodedArgs.originalStartTimeToday)', NewStart='\(decodedArgs.newStartTimeToday)', NewEnd='\(decodedArgs.newEndTimeToday)'")
            let errorContent = "{\"error\": \"Invalid time format for update. Expected formats like '9:00 AM' or '14:30'. Check original: '\(decodedArgs.originalStartTimeToday)', new start: '\(decodedArgs.newStartTimeToday)', new end: '\(decodedArgs.newEndTimeToday)'.\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        
        // 3. Combine with Today's Date
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        
        let originalStartComponents = calendar.dateComponents([.hour, .minute], from: originalStartTimeParsed)
        var combinedOriginalStart = todayComponents
        combinedOriginalStart.hour = originalStartComponents.hour
        combinedOriginalStart.minute = originalStartComponents.minute
        
        let newStartComponents = calendar.dateComponents([.hour, .minute], from: newStartTimeParsed)
        var combinedNewStart = todayComponents
        combinedNewStart.hour = newStartComponents.hour
        combinedNewStart.minute = newStartComponents.minute
        
        let newEndComponents = calendar.dateComponents([.hour, .minute], from: newEndTimeParsed)
        var combinedNewEnd = todayComponents
        combinedNewEnd.hour = newEndComponents.hour
        combinedNewEnd.minute = newEndComponents.minute
        
        guard let originalStartTime = calendar.date(from: combinedOriginalStart), 
              let newStartTime = calendar.date(from: combinedNewStart), 
              let newEndTime = calendar.date(from: combinedNewEnd) else {
            print("Error: Failed to combine date and time components for update.")
            return ChatMessageItem(content: "{\"error\": \"Internal error combining date and time for update.\"}", role: .tool, toolCallId: id, functionName: functionName)
        }
        
        // Ensure new end time is after new start time
        guard newEndTime > newStartTime else {
            print("Error: New end time ('\(decodedArgs.newEndTimeToday)') must be after new start time ('\(decodedArgs.newStartTimeToday)') on the same day.")
            let errorContent = "{\"error\": \"New end time ('\(decodedArgs.newEndTimeToday)') must be after new start time ('\(decodedArgs.newStartTimeToday)') on the same day.\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }

        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { 
            print("DEBUG [ViewModel]: Calling CalendarService to update event: '\(decodedArgs.summary)' from \(originalStartTime) to \(newStartTime)-\(newEndTime)") 
        }

        // 4. Call CalendarService and Handle Result
        return await Task<ChatMessageItem, Never> {            
            let calendarService = CalendarService()
            let (success, error) = await withCheckedContinuation { (continuation: CheckedContinuation<(Bool, Error?), Never>) -> Void in
                // Ensure CalendarService method signature matches
                calendarService.updateCalendarEventTime(summary: decodedArgs.summary, originalStartTime: originalStartTime, newStartTime: newStartTime, newEndTime: newEndTime) { success, error in
                    continuation.resume(returning: (success, error))
                }
            }
            
            var responseContent: String
            if success {
                responseContent = "Event '\(decodedArgs.summary)' updated successfully to \(decodedArgs.newStartTimeToday) - \(decodedArgs.newEndTimeToday)."
            } else {
                let errorDescription = error?.localizedDescription ?? "Unknown error updating event time."
                print("Error updating calendar event time: \(errorDescription)")
                // Escape quotes within the error description for valid JSON in the response
                let escapedErrorDesc = errorDescription.replacingOccurrences(of: "\"", with: "\\\"")
                responseContent = "{\"error\": \"Failed to update time for event '\(decodedArgs.summary)'. Reason: \(escapedErrorDesc)\"}" 
            }
            return ChatMessageItem(content: responseContent, role: .tool, toolCallId: id, functionName: functionName)
        }.value
    }
    // -----------------------------------------------------------
    
    // --- ADDED: Handler for markTaskComplete ---
    private func handleMarkTaskCompleteToolCall(id: String, functionName: String = "markTaskComplete", arguments: String) async -> ChatMessageItem {
        struct MarkCompleteArgs: Decodable { let taskDescription: String }
        
        guard let argsData = arguments.data(using: .utf8), 
              let decodedArgs = try? JSONDecoder().decode(MarkCompleteArgs.self, from: argsData) else {
            print("Error: Failed to decode arguments for markTaskComplete: \(arguments)")
            let errorContent = "{\"error\": \"Invalid arguments for markTaskComplete\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        
        let taskDescription = decodedArgs.taskDescription
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { 
            print("DEBUG [ViewModel]: Marking task '\(taskDescription)' as complete via function call.") 
        }

        // Call the store function (to be implemented)
        let success = await todoListStore.markTaskComplete(description: taskDescription)
        
        let responseContent = success ? "Task '\(taskDescription)' marked as complete." : "Task '\(taskDescription)' not found."
        return ChatMessageItem(content: responseContent, role: .tool, toolCallId: id, functionName: functionName)
    }
    // -------------------------------------------
    
    // --- ADDED: Handler for updateTaskDifficulty ---
    private func handleUpdateTaskDifficultyToolCall(id: String, functionName: String = "updateTaskDifficulty", arguments: String) async -> ChatMessageItem {
        struct UpdateDifficultyArgs: Decodable {
            let taskDescription: String
            let difficulty: String // Expect "Low", "Medium", or "High"
        }
        
        guard let argsData = arguments.data(using: .utf8), 
              let decodedArgs = try? JSONDecoder().decode(UpdateDifficultyArgs.self, from: argsData) else {
            print("Error: Failed to decode arguments for updateTaskDifficulty: \(arguments)")
            let errorContent = "{\"error\": \"Invalid arguments for updateTaskDifficulty. Expected taskDescription and difficulty (Low, Medium, or High).\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        
        // Convert the string difficulty back to the enum
        guard let difficultyEnum = Difficulty(rawValue: decodedArgs.difficulty) else {
            print("Error: Invalid difficulty value provided: \(decodedArgs.difficulty). Must be one of: \(Difficulty.allCases.map { $0.rawValue }.joined(separator: ", "))")
            let errorContent = "{\"error\": \"Invalid difficulty value '\(decodedArgs.difficulty)'. Must be Low, Medium, or High.\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        
        let taskDescription = decodedArgs.taskDescription
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { 
            print("DEBUG [ViewModel]: Updating difficulty for task '\(taskDescription)' to '\(difficultyEnum.rawValue)' via function call.") 
        }

        // Call the store function
        todoListStore.updateTaskDifficulty(description: taskDescription, difficulty: difficultyEnum)
        
        let responseContent = "Difficulty for task '\(taskDescription)' updated to \(difficultyEnum.rawValue)."
        return ChatMessageItem(content: responseContent, role: .tool, toolCallId: id, functionName: functionName)
    }
    // -----------------------------------------------
    
    // --- ADDED: Handlers for Roadmap Metadata ---
    private func handleUpdateTaskCategoryToolCall(id: String, functionName: String = "updateTaskCategory", arguments: String) async -> ChatMessageItem {
        struct UpdateCategoryArgs: Decodable {
            let taskDescription: String
            let category: String? // Can be null/empty to clear
        }
        
        guard let argsData = arguments.data(using: .utf8), 
              let decodedArgs = try? JSONDecoder().decode(UpdateCategoryArgs.self, from: argsData) else {
            print("Error: Failed to decode arguments for updateTaskCategory: \(arguments)")
            let errorContent = "{\"error\": \"Invalid arguments for updateTaskCategory. Expected taskDescription and optional category.\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        
        let taskDescription = decodedArgs.taskDescription
        let category = decodedArgs.category // Keep optional
        
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { 
            print("DEBUG [ViewModel]: Updating category for task '\(taskDescription)' to '\(category ?? "nil")' via function call.") 
        }

        // Call the store function
        todoListStore.updateTaskCategory(description: taskDescription, category: category)
        
        let responseContent = "Category for task '\(taskDescription)' updated to \(category ?? "none")."
        return ChatMessageItem(content: responseContent, role: .tool, toolCallId: id, functionName: functionName)
    }

    private func handleUpdateTaskProjectOrPathToolCall(id: String, functionName: String = "updateTaskProjectOrPath", arguments: String) async -> ChatMessageItem {
        struct UpdateProjectPathArgs: Decodable {
            let taskDescription: String
            let projectOrPath: String? // Can be null/empty to clear
        }
        
        guard let argsData = arguments.data(using: .utf8), 
              let decodedArgs = try? JSONDecoder().decode(UpdateProjectPathArgs.self, from: argsData) else {
            print("Error: Failed to decode arguments for updateTaskProjectOrPath: \(arguments)")
            let errorContent = "{\"error\": \"Invalid arguments for updateTaskProjectOrPath. Expected taskDescription and optional projectOrPath.\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        
        let taskDescription = decodedArgs.taskDescription
        let projectOrPath = decodedArgs.projectOrPath // Keep optional
        
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { 
            print("DEBUG [ViewModel]: Updating project/path for task '\(taskDescription)' to '\(projectOrPath ?? "nil")' via function call.") 
        }

        // Call the store function
        todoListStore.updateTaskProjectOrPath(description: taskDescription, projectOrPath: projectOrPath)
        
        let responseContent = "Project/path for task '\(taskDescription)' updated to \(projectOrPath ?? "none")."
        return ChatMessageItem(content: responseContent, role: .tool, toolCallId: id, functionName: functionName)
    }
    // -------------------------------------------
    
    // --- Handler for generateTaskSummary function call ---
    private func handleGenerateTaskSummaryToolCall(id: String, functionName: String = "generateTaskSummary", arguments: String) async -> ChatMessageItem {
        struct GenerateTaskSummaryArgs: Decodable {
            let taskDescription: String
            let summary: String
        }
        
        guard let decodedArgs = try? JSONDecoder().decode(GenerateTaskSummaryArgs.self, from: arguments.data(using: .utf8)!) else {
            print("Error: Failed to decode arguments for generateTaskSummary: \(arguments)")
            let errorContent = "{\"error\": \"Invalid arguments for generateTaskSummary. Expected taskDescription and summary.\"}"
            return ChatMessageItem(content: errorContent, role: .tool, toolCallId: id, functionName: functionName)
        }
        
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) { 
            print("DEBUG [ViewModel]: Generating summary for task '\(decodedArgs.taskDescription)': '\(decodedArgs.summary)'") 
        }
        
        // Update the task summary in the store
        todoListStore.updateTaskSummaryByDescription(description: decodedArgs.taskDescription, summary: decodedArgs.summary)
        
        let responseContent = "Summary for task '\(decodedArgs.taskDescription)' set to: '\(decodedArgs.summary)'"
        return ChatMessageItem(content: responseContent, role: .tool, toolCallId: id, functionName: functionName)
    }
    // -------------------------------------------

    // --- ADDED: Function to start a new chat ---
    func startNewChat() {
        messages.removeAll()
        updateSystemMessage()
        addWelcomeMessage()
        isLoading = false // Ensure loading state is reset
        newMessageText = "" // Clear any pending input text
        print("DEBUG [ViewModel]: Starting new chat.")
        // Note: saveMessages() will be called automatically due to messages didSet
    }
    // -----------------------------------------
} 