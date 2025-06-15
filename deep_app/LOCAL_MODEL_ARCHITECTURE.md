# Local Model Architecture - Bryan's Brain

## Overview

As of June 11, 2025, Bryan's Brain has integrated support for Apple's on-device Foundation Models framework (iOS 26+). This document describes the architecture, implementation, and current status.

## Architecture Overview

```
┌─────────────────┐
│   ChatViewModel │
├─────────────────┤
│ @AppStorage     │
│ useLocalModel   │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Switch  │
    └────┬────┘
         │
┌────────┴────────┬──────────────────┐
│                 │                  │
▼                 ▼                  │
┌─────────────┐   ┌──────────────┐  │
│OpenAIService│   │AppleFoundation│  │
│             │   │   Service     │  │
├─────────────┤   ├──────────────┤  │
│ GPT-4o-mini │   │ ~3B on-device│  │
│ Cloud API   │   │ iOS 26+ only │  │
│ 22+ tools   │   │ 22 tools     │  │
└─────────────┘   └──────────────┘  │
                           │         │
                  ┌────────▼───────┐ │
                  │FoundationModel│ │
                  │     Tools      │ │
                  ├────────────────┤ │
                  │ @Generable    │ │
                  │ Tool Protocol │ │
                  └────────────────┘ │
```

## Implementation Details

### 1. Service Architecture

**AppleFoundationService** mirrors the OpenAIService API:
```swift
func processConversation(messages: [OpenAIService.ChatMessage]) async -> APIResult
```

This allows seamless switching between services based on user preference.

### 2. Tool System

Tools use Apple's `Tool` protocol with `@Generable` macro:

```swift
@available(iOS 26.0, *)
struct CreateTaskTool: Tool {
    let name = "addTaskToList"
    let description = "Creates a new task"
    
    @Generable
    struct Arguments {
        @Guide(description: "Task text")
        let taskDescription: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Implementation
    }
}
```

### 3. Availability Handling

The app checks model availability at multiple levels:
- Device eligibility (hardware/OS support)
- Apple Intelligence enabled
- Model downloaded and ready

### 4. Progressive Degradation

When failures occur, the system automatically retries with reduced complexity:

**Attempt 1**: All 22 tools
- Full functionality
- May trigger IPC crashes in beta

**Attempt 2**: Essential tools only (6 tools)
- Basic task operations
- Scratchpad access
- Diagnostic tool

**Attempt 3**: No tools (text-only)
- Pure conversational AI
- No task integration

## Current Tool Inventory

### Task Management
1. `addTaskToList` - Create new tasks ✅
2. `listCurrentTasks` - Retrieve task list ❌
3. `markTaskComplete` - Complete tasks ❌
4. `removeTaskFromList` - Delete tasks ❌
5. `updateTaskPriorities` - Reorder tasks ❌
6. `updateTaskEstimatedDuration` - Set time estimates ❌
7. `updateTaskDifficulty` - Set difficulty levels ❌
8. `updateTaskCategory` - Categorize tasks ❌
9. `updateTaskProjectOrPath` - Assign to projects ❌

### Calendar Integration
10. `createCalendarEvent` - Add events ❌
11. `getTodaysCalendarEvents` - View calendar ❌
12. `deleteCalendarEvent` - Remove events ❌
13. `updateCalendarEventTime` - Reschedule ❌

### AI-Enhanced Features
14. `generateTaskSummary` - Create summaries ❌
15. `enrichTaskMetadata` - Auto-fill metadata ❌
16. `generateProjectEmoji` - Smart emojis ❌
17. `organizeAndCleanup` - Bulk organization ❌
18. `breakDownTask` - Task decomposition ❌

### Utility
19. `getCurrentDateTime` - Time awareness ❌
20. `getScratchpad` - View notes ❌
21. `updateScratchpad` - Save notes ❌
22. `runDiagnostic` - Debug tool ❌

✅ = Working | ❌ = Beta bug (tool executes but response not recognized)

## Known Issues (iOS 26 Beta)

### 1. Tool Response Recognition Bug
**Problem**: Model successfully calls tools but doesn't interpret returned data
**Impact**: Can't retrieve tasks, calendar events, or scratchpad content
**Workaround**: None - fundamental framework issue

### 2. IPC Crashes
**Problem**: "Underlying connection interrupted" errors
**Impact**: Session terminates unexpectedly
**Workaround**: Retry with fewer tools

### 3. Content Filter False Positives
**Problem**: ADHD/mental health terminology triggers safety filters
**Impact**: System prompts rejected
**Workaround**: Use neutral language

## Error Handling Strategy

### Timeout Protection
- 30-second timeout per request
- Prevents hanging on crashed sessions

### Retry Logic
- Up to 3 attempts
- 1-second delay between crash retries
- 0.5-second stabilization delay for retries

### User Communication
- Clear error messages
- Guidance to switch to OpenAI
- Explanation of beta limitations

## Performance Optimizations

### Session Prewarming
```swift
try await session.prewarm()
```
Loads model before user request

### Stabilization Delays
```swift
if attempt > 0 {
    try await Task.sleep(nanoseconds: 500_000_000)
}
```
Allows system to recover between attempts

## Testing & Debugging

### Enable Debug Logs
Settings → Debug Log → ON

### Key Log Messages
```
DEBUG [AppleFoundationService]: Attempt 1 with all tools
DEBUG [GetTasksTool]: Tool called to retrieve tasks
DEBUG [GetTasksTool]: Retrieved tasks: [data]
DEBUG [AppleFoundationService]: Response content: [model response]
```

### Diagnostic Tool
Ask: "Run diagnostic test hello"
- Verifies tool calling mechanism
- Tests response handling

### Foundation Models Instrument
- Profile on physical device
- Track asset loading time
- Monitor inference duration
- Identify tool calling overhead

## Migration Path

### Current State (June 2025)
- Basic chat: Production ready
- Task creation: Works reliably
- Data retrieval: Blocked by beta bug

### Expected Timeline
- iOS 26 Beta 2-3: Bug fixes expected
- iOS 26 RC: Full functionality likely
- Fall 2025: Production deployment

### Preparation Steps
1. Infrastructure ready ✅
2. Tools implemented ✅
3. Error handling complete ✅
4. Awaiting framework fixes ⏳

## Best Practices

### For Development
1. Test on physical iOS 26 device
2. Use OpenAI for feature development
3. Monitor console for debug logs
4. Profile with Instruments

### For Users
1. Recommend OpenAI for reliability
2. Offer local model as "preview"
3. Provide clear beta warnings
4. Guide through failures gracefully

## Diagnostic Capabilities (December 2024 Update)

### Enhanced Diagnostic Tools
To help identify workarounds for the tool response bug:

1. **Multi-Format DiagnosticTool**
   - Tests plain, JSON, markdown, and structured formats
   - Usage: `"Run diagnostic test hello with format json"`

2. **Enhanced GetTasksTool**
   - Supports simple, JSON, structured, and plain formats
   - Usage: `"List current tasks with format simple"`

3. **ExperimentalTaskRetrievalTool**
   - Mimics successful tool patterns
   - Actions: count, list, check
   - Usage: `"Use experimental tool to count tasks"`

### Automated Testing
- Type `"Test local model tools"` in chat
- Runs comprehensive diagnostic suite
- Tests all formats and tools systematically
- Provides summary of working/failing patterns

### Debug Monitoring
Watch console for:
```
DEBUG [ToolName]: Tool called...
DEBUG [ToolName]: Returning response...
DEBUG [AppleFoundationService]: Response content...
```

## Conclusion

The local model integration is architecturally complete but limited by iOS 26 beta bugs. Enhanced diagnostics help identify potential workarounds while we await Apple's fix. The implementation is ready for full functionality once Apple resolves the tool response recognition issue. Until then, the app gracefully handles limitations while providing basic conversational AI capabilities on-device. 