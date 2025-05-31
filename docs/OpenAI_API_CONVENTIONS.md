# OpenAI API Conventions

This document summarizes how the project interacts with the OpenAI Chat Completions API and establishes conventions for future work.

## Model Selection
* **Default model:** `gpt-4o-mini` (as configured in `OpenAIService`).  
* When OpenAI deprecates or supersedes a model, update **both** the constant in code and this document.

## Function-Calling / Tools
We use the function-calling interface to let the assistant invoke app features.

| Swift Struct | `function.name` | Purpose |
|--------------|-----------------|---------|
| `AddTaskArguments` | `addTaskToList` | Append a new task to the to-do list |
| — | `listCurrentTasks` | Return formatted list of tasks |
| — | `removeTaskFromList` | Remove task by description |
| — | `updateTaskEstimatedDuration` | Store estimated effort |
| — | `updateTaskPriorities` | Re-order tasks |
| `CreateCalendarEventArguments` | `createCalendarEvent` | Add event for **today** on Google Calendar |
| — | `getTodaysCalendarEvents` | Read today's events |
| — | `deleteCalendarEvent` | Remove event identified by summary + start time |
| — | `updateCalendarEventTime` | Change start/end time for existing event |
| — | `getCurrentDateTime` | Return local date/time string |
| — | `markTaskComplete` | Mark task complete without deleting |

**Conventions:**
1. Keep **all** tool definitions centralised in `OpenAIService`.
2. Every new tool **must** have:
   * A corresponding Swift `FunctionDefinition` entry.
   * A Codable Swift struct for its arguments (even `struct Empty {}` if none).
   * A handler inside `ChatViewModel` that returns a `ChatMessageItem`.
3. Optional parameters are allowed but should be documented and default to `nil` on the Swift side.

## Request Construction
```swift
let requestBody = ChatRequest(
    model: "gpt-4o-mini",
    messages: messages,  // Already in OpenAI format
    tools: allTools,     // Defined above
    tool_choice: "auto" // Let the model decide
)
```
* We intentionally delegate tool-selection to the model via `tool_choice = "auto"` to balance autonomy with simplicity.
* JSON bodies are encoded with `JSONEncoder()`; pretty-printed output is enabled under the **DEBUG** flag when `debugLogEnabledKey` is set in `UserDefaults`.

## Error Handling
* Non-2xx responses are surfaced as `.failure` in `OpenAIService.APIResult`.
* We log **but do not crash** on JSON encoding/decoding failures— these are treated as recoverable errors.

## Security
* The API key is only loaded from `Secrets.plist` in **DEBUG** builds.  
* **Release builds must implement a secure key retrieval strategy** (see TODO list).

## Logging
* Controlled by `AppSettings.debugLogEnabledKey` in `UserDefaults`.  
* When enabled, both request JSON and tool-call decisions are printed to Xcode's console.

_Last updated: 2025-05-31_