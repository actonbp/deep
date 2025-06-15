# Foundation Models Tool Calling Implementation

## Overview

This document explains how tool calling is implemented in Bryan's Brain using Apple's Foundation Models framework (iOS 26+).

## How Tool Calling Works

Based on Apple's WWDC25 documentation, the Foundation Models framework supports tool calling through:

1. **Tool Protocol**: Each tool conforms to the `Tool` protocol with:
   - `name`: A unique identifier for the tool
   - `description`: Natural language description of when to use the tool
   - `Arguments`: A `@Generable` struct defining the tool's parameters
   - `call()`: The function that executes when the model invokes the tool

2. **Generable Arguments**: Tool arguments must be marked with `@Generable` to ensure type safety
   - Use `@Guide` to provide descriptions or constraints for parameters
   - Supports enums, optionals, and common Swift types

3. **Autonomous Execution**: The model decides when and how to call tools based on:
   - The tool's description
   - The current conversation context
   - The user's request

## Implemented Tools

### Task Management Tools

1. **CreateTaskTool**
   - Creates a new task with title and optional description
   - Example: "Create a task to buy groceries"

2. **GetTasksTool**
   - Retrieves tasks filtered by status (all/completed/pending)
   - Example: "Show me my pending tasks"

3. **CompleteTaskTool**
   - Marks a task as completed by title match
   - Example: "Mark buy groceries as done"

4. **UpdateTaskTool**
   - Updates task title or description
   - Example: "Change buy groceries to buy organic groceries"

5. **DeleteTaskTool**
   - Deletes a task by title match
   - Example: "Delete the groceries task"

### Scratchpad Tools

6. **GetScratchpadTool**
   - Retrieves current scratchpad content
   - Example: "What's in my scratchpad?"

7. **UpdateScratchpadTool**
   - Updates scratchpad with new content (append or replace)
   - Example: "Add these meeting notes to my scratchpad"

## Integration Flow

1. User sends a message in chat
2. ChatViewModel determines whether to use OpenAI or local model
3. If using local model, AppleFoundationService:
   - Creates a LanguageModelSession with all tools
   - Provides instructions about available tools
   - Sends the user's message
4. The model autonomously:
   - Analyzes the request
   - Calls appropriate tools if needed
   - Incorporates tool results into response
5. Response is displayed in chat

## Key Implementation Details

### Type Safety with @Generable

```swift
@Generable
struct Arguments {
    @Guide(description: "Title of the task to create")
    let title: String
    
    @Guide(description: "Optional description for the task")
    let description: String?
}
```

### Tool Output

Tools return `ToolOutput` which can be created from:
- Strings for natural language responses
- `GeneratedContent` for structured data

### Error Handling

Each tool handles errors gracefully:
- TodoListStore operations use the shared singleton instance
- Tools return descriptive messages on failure
- MainActor is used for UI-related operations

### Data Storage

The app uses `TodoListStore.shared` which:
- Stores tasks as JSON in UserDefaults via @AppStorage
- Syncs with CloudKit when available
- Does NOT use Core Data

## Testing Tool Calling

To test the implementation:

1. Enable "Use On-Device Model" in Settings
2. Try these example prompts:
   - "Create a task to review quarterly reports"
   - "Show me all my tasks"
   - "Complete the quarterly reports task"
   - "What's in my scratchpad?"
   - "Save this idea to my scratchpad: new app feature - voice notes"

## Future Enhancements

When Apple releases more documentation, consider adding:
- Calendar integration tools
- Weather and location tools
- Dynamic tool creation
- Tool result streaming
- More complex tool chaining

## References

- WWDC25: Meet the Foundation Models framework
- WWDC25: Deep dive into the Foundation Models framework
- Apple's Human Interface Guidelines: Generative AI 