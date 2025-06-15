# Foundation Models Tool Response Recognition Issue

## Problem Description

In iOS 26 beta, the Apple Foundation Models framework has an issue where the local model doesn't properly recognize tool responses that return data. This manifests as:

- ✅ Tools that CREATE data work (e.g., `addTaskToList`)
- ❌ Tools that RETRIEVE data fail (e.g., `listCurrentTasks`)
- The model says "I can't see your tasks" even after successfully calling the tool

## Root Cause Analysis

The issue appears to be a bug in how the Foundation Models framework passes tool responses back to the model:

1. The tool IS being called (debug logs confirm this)
2. The tool IS returning data correctly
3. The model is NOT interpreting the tool response as usable data
4. Instead, the model acts as if it never received the tool response

## Diagnostic Steps

### 1. Enable Debug Logging
Look for these log messages:
```
DEBUG [GetTasksTool]: Tool called to retrieve tasks
DEBUG [GetTasksTool]: Retrieved tasks: [actual task data]
DEBUG [AppleFoundationService]: Response content: [model's response]
```

### 2. Test Enhanced Diagnostic Tool
The diagnostic tool now supports multiple response formats to test what the model recognizes:

```
"Run diagnostic test hello with format json"
"Run diagnostic test hello with format markdown"
"Run diagnostic test hello with format structured"
"Run diagnostic test hello with format plain"
```

Expected behavior:
- Should call `runDiagnostic` tool
- Should echo back the diagnostic response in the requested format
- Different formats may have different recognition rates

### 3. Test Experimental Retrieval Tool
Try the experimental tool that mimics successful patterns:

```
"Use experimental tool to count tasks"
"Use experimental tool to list tasks"
"Use experimental tool to check tasks"
```

This tool uses simplified responses similar to successful tools like `addTaskToList`.

### 4. Check Tool Execution
Tools are executing if you see:
- Tasks being added successfully
- Debug logs showing tool calls
- Purple bars in Foundation Models Instrument

## Workarounds

### 1. Use OpenAI Instead
In Settings, disable "Use On-Device Model (Free)" for reliable tool responses.

### 2. Fallback to Text-Only Mode
The system automatically falls back after 2 failed attempts:
- Attempt 1: All tools
- Attempt 2: Essential tools only  
- Attempt 3: No tools (text-only)

### 3. Hardcode Responses (Not Recommended)
For demos only - have tools return hardcoded strings that the model recognizes.

### 4. Wait for iOS 26 Stable
This appears to be a beta bug that Apple will likely fix.

## Technical Details

### What Works
```swift
// Creating new data
func call(arguments: Arguments) async throws -> ToolOutput {
    TodoListStore.shared.addItem(text: arguments.taskDescription)
    return ToolOutput("Task added successfully.")
}
```

### What Doesn't Work
```swift
// Retrieving existing data
func call(arguments: Arguments) async throws -> ToolOutput {
    let tasks = TodoListStore.shared.getFormattedTaskList()
    return ToolOutput(tasks) // Model doesn't recognize this as data
}
```

## Attempted Solutions

1. **Explicit Response Format**: Tried prefixing with "TOOL_RESULT:"
2. **Structured Responses**: Used detailed success/status messages
3. **Simplified Output**: Returned just raw data
4. **Enhanced Instructions**: Told model to interpret tool responses
5. **Debug Mode**: Added diagnostic tools

None of these workarounds fix the underlying framework issue.

## New Enhanced Solutions (December 2024)

### Enhanced GetTasksTool
The `listCurrentTasks` tool now supports multiple response formats:
- `format: "json"` - Returns tasks as JSON
- `format: "structured"` - Uses delimited response format
- `format: "simple"` - Returns simplified text
- `format: "plain"` - Returns standard formatted list

### Enhanced DiagnosticTool
Tests different response formats to identify what the model recognizes:
- `responseFormat: "json"` - JSON response
- `responseFormat: "markdown"` - Markdown formatted
- `responseFormat: "structured"` - Delimited format
- `responseFormat: "plain"` - Simple text

### ExperimentalTaskRetrievalTool
New tool that mimics successful tool patterns:
- `action: "count"` - Returns simple count message
- `action: "list"` - Returns conversational list
- `action: "check"` - Returns ultra-simple status

## Recommendations

1. **For Development**: Use OpenAI while building features
2. **For Testing**: Use the diagnostic tool to verify the issue
3. **For Production**: Implement proper fallbacks and error messages
4. **For Users**: Provide clear guidance about switching to OpenAI

## Future Resolution

This issue will likely be resolved when:
- Apple releases iOS 26 stable
- Foundation Models framework exits beta
- Apple provides documentation on proper tool response handling

Until then, the app gracefully degrades to text-only mode when tool responses fail. 