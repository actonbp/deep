# Foundation Models Comprehensive Implementation Guide

This comprehensive guide consolidates all the lessons learned, workarounds, and best practices for implementing Apple's Foundation Models framework in Bryan's Brain.

## Table of Contents

1. [Framework Overview](#framework-overview)
2. [Major Implementation Challenges](#major-implementation-challenges)
3. [Safety System Understanding](#safety-system-understanding)
4. [Tool Design Best Practices](#tool-design-best-practices)
5. [Problem Solutions & Workarounds](#problem-solutions--workarounds)
6. [Error Handling Strategies](#error-handling-strategies)
7. [Production Recommendations](#production-recommendations)
8. [Lessons Learned Archive](#lessons-learned-archive)

## Framework Overview

### Apple's 6-Phase Tool Execution Process

Understanding this process is crucial for designing effective tools:

1. **Present Tools**: Model receives list of available tools and their descriptions
2. **Submit Prompt**: User's request sent to the model
3. **Generate Arguments**: Model decides which tool(s) to call and generates arguments
4. **Execute Tool**: Your tool's `call(arguments:)` method runs with generated arguments
5. **Return Output**: Tool returns `ToolOutput` to the model
6. **Final Response**: Model incorporates tool output into its response to user

### iOS 26 Beta Status

- **Framework State**: Beta with known bugs
- **Release Timeline**: General availability expected Fall 2025
- **Stability**: Improving with each beta release

### 🎉 iOS 26 Beta 4 Update (July 22, 2025)

**Major JSON Schema Support Added!**

- **`GenerationSchema` is now Codable**: Can serialize/deserialize tool schemas
- **JSON Schema Export**: Convert `@Generable` models to industry-standard JSON Schema
- **Cross-LLM Compatibility**: Use `@Generable` models with OpenAI, Claude, and other LLMs
- **Bi-directional Integration**: Initialize `@Generable` models from external LLM responses

**Implementation Example:**
```swift
// Define model once
@Generable
struct TaskModel {
    @Guide(description: "Task description")
    let title: String
}

// Export for OpenAI/Claude
let schema = GenerationSchema(TaskModel.self)
let jsonData = try JSONEncoder().encode(schema)

// Now any LLM can use this schema!
```

This update fundamentally changes the integration story - Foundation Models tools are no longer isolated to Apple's ecosystem!

## Major Implementation Challenges

### 1. Tool Response Recognition Bug

**Problem**: Foundation Models can call tools successfully but don't properly recognize when tools return data.

**Symptoms**:
- Tool logs show successful execution
- Model acts as if it never received the response
- Creates/modifies data works ✅
- Retrieves/displays data fails ❌

**Examples**:
- ✅ "Add task: Buy groceries" - Works perfectly
- ❌ "Show my tasks" - Model says "I can't see your tasks"

**Current Status**: iOS 26 beta framework bug, not our implementation

### 2. Infinite Loop Issue

**Problem**: AI asks users for tool parameters instead of using tools directly.

**Example Flow**:
1. User: "Show my tasks"
2. AI: "What would you like me to show?"
3. User: "My tasks"
4. AI: [Safety rejection due to repetitive pattern]

**Root Cause**: Model treating tools as conversation topics rather than executable functions

### 3. Safety System Over-Sensitivity

**Problem**: Extremely conservative content filters causing false positive rejections.

**Trigger Patterns**:
- Common words: "list", "get", "retrieve", "fetch"
- Task-related terminology
- Mental health/ADHD language
- Repetitive clarification requests

## Safety System Understanding

### Multi-Layer Protection System

1. **Content Analysis**: Scans prompts for potentially harmful content
2. **Pattern Detection**: Identifies repetitive or suspicious interaction patterns
3. **Context Evaluation**: Considers conversation history for safety assessment
4. **Response Filtering**: Blocks AI responses that might contain harmful content

### Error Classification

**Safety Rejections** (15+ detected patterns):
- "I can't help with that"
- "Content policy violation"
- "Unable to process request"
- "Let's focus on something else"

**Technical Errors**:
- Session cancellation
- IPC crashes
- Network timeouts
- Framework errors

## Tool Design Best Practices

### Apple's Patterns vs Current Implementation

| Aspect | Current Implementation | Apple's Pattern |
|--------|----------------------|-----------------|
| Tool Names | `listCurrentTasks` | `getTasks` |
| Arguments | `retrieve: Bool` | Specific parameters only |
| Responses | Plain strings | Mixed: strings or GeneratedContent |
| Error Handling | Basic logging | Try/catch with fallbacks |

### Recommended Tool Naming

**Use clear verb-first naming:**
- `listCurrentTasks` → `getTasks` or `getTaskList`
- `addTaskToList` → `createTask` or `addTask`
- `markTaskComplete` → `completeTask`

### Tool Arguments Best Practices

**Avoid Boolean Flags**:
```swift
// Bad
@Generable
struct Arguments {
    let retrieve: Bool  // Don't use flags to trigger actions
}

// Good
@Generable
struct Arguments {
    @Guide(description: "Filter by status: all, completed, pending")
    let filter: String?
}
```

### Response Patterns

**Use GeneratedContent for structured data:**
```swift
// Simple responses
return ToolOutput("You have \(tasks.count) tasks.")

// Structured data
let content = GeneratedContent(properties: [
    "taskCount": tasks.count,
    "tasks": tasks.map { $0.text }
])
return ToolOutput(content)
```

## Problem Solutions & Workarounds

### 1. Safety-Optimized Tools

**Strategy**: Use positive, encouraging language instead of trigger words.

**SafeTaskRetrievalTool Example**:
```swift
struct SafeTaskRetrievalTool: Tool {
    let name = "getProductivityStatus"
    let description = "Get an overview of your current productivity goals and achievements"
    
    @Generable
    struct Arguments {
        @Guide(description: "Natural language query about productivity goals")
        let query: String = "show my goals"
    }
}
```

**Language Substitutions**:
- "tasks" → "productivity goals"
- "list" → "overview"
- "retrieve" → "check"
- "fetch" → "review"

### 2. Direct-Call Tools (No Parameters)

**Strategy**: Eliminate infinite loops by removing all parameters.

```swift
struct DirectTaskTool: Tool {
    let name = "checkGoals"
    let description = "Check your current productivity goals"
    
    @Generable
    struct Arguments {
        // No parameters - immediate execution
    }
}
```

### 3. Enhanced System Prompts

**Key Instructions**:
- "NEVER ask users for clarification"
- "Use tools immediately when requested"
- "If a tool fails, try a different approach"

### 4. Progressive Tool Degradation

**3-Stage Fallback System**:

1. **Stage 1**: Full tool set with safety-optimized versions
2. **Stage 2**: Essential tools only (create, basic read)
3. **Stage 3**: Text-only mode with hardcoded responses

```swift
func selectToolSet(attempt: Int) -> [Tool] {
    switch attempt {
    case 1: return FoundationModelTools.all()
    case 2: return FoundationModelTools.essential()
    default: return [] // Text-only mode
    }
}
```

## Error Handling Strategies

### Session Management

**Best Practices**:
- Prewarm sessions on app launch
- Handle cancellation errors gracefully
- Implement retry logic with exponential backoff
- Timeout after 30 seconds for simple queries, 5 minutes for complex

### Retry Logic

```swift
func processWithRetry(message: String, maxAttempts: Int = 3) async -> Result {
    for attempt in 1...maxAttempts {
        do {
            let toolSet = selectToolSet(attempt: attempt)
            return try await processConversation(message, tools: toolSet)
        } catch {
            if attempt == maxAttempts {
                return .failure(error)
            }
            // Exponential backoff
            try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
        }
    }
}
```

### Error Message Mapping

**Technical errors → User-friendly messages:**
- "Session canceled" → "Let me restart and try again"
- "IPC error" → "Having trouble with the on-device model, switching to backup"
- "Safety rejection" → "Let me rephrase that differently"

## Production Recommendations

### Development Strategy

1. **Monitor iOS releases**: Test each beta for framework improvements
2. **Maintain dual support**: Keep OpenAI as reliable fallback
3. **User choice**: Let users choose between models based on needs
4. **Gradual rollout**: Enable local model for power users first

### User Experience Guidelines

1. **Clear expectations**: Explain beta limitations upfront
2. **Seamless fallback**: Switch to OpenAI when local model fails
3. **Progress indicators**: Show when using different models
4. **Feedback loop**: Collect user reports on local model performance

### Implementation Priorities

1. **High Priority**: Fix infinite loop prevention
2. **Medium Priority**: Improve safety workarounds
3. **Low Priority**: Optimize performance and response quality

## Lessons Learned Archive

### Dad Jokes Success Pattern

**What Worked**:
- Simple natural language arguments (`naturalLanguageQuery: String`)
- Direct implementation without complex branching
- Closure-based session configuration
- Immediate tool execution without asking for clarification

**Applied to Tasks**:
```swift
@Generable
struct Arguments {
    @Guide(description: "Natural language description of the task")
    let taskDescription: String
}
```

### Infinite Loop Resolution

**Original Problem**:
1. User: "Show my tasks"
2. AI: "What tasks would you like me to show?"
3. User: "All my tasks"
4. AI: [Safety rejection due to repetitive pattern]

**Solution Applied**:
- System prompt: "NEVER ask for clarification, use tools immediately"
- Direct-call tools with no parameters
- Hardcoded fallback responses when tools fail

### Safety Filter Navigation

**Trigger Words Identified**:
- "list", "get", "retrieve", "fetch"
- "show", "display", "view"
- "ADHD", "mental health"
- Any combination suggesting data retrieval

**Successful Workarounds**:
- "productivity goals" instead of "tasks"
- "overview" instead of "list"
- "check" instead of "retrieve"
- Positive, encouraging language throughout

### Tool Awareness Fix

**Problem**: CreateTaskTool was missing from tool sets, causing confusion.

**Solution**:
- Ensure CreateTaskTool is included in all tool collections
- Remove contradictory system prompt instructions
- Add explicit capability affirmations in prompts

### Performance Optimizations

**Session Management**:
- Prewarm sessions to reduce first-call latency
- Handle "underlying connection interrupted" errors
- Implement proper session lifecycle management

**Memory Management**:
- Clear old sessions when creating new ones
- Monitor memory usage with large tool sets
- Use @MainActor properly for UI updates

---

## Summary

This comprehensive guide represents months of trial-and-error implementation with Apple's Foundation Models beta. While the framework shows tremendous promise for on-device AI, the current beta state requires careful workarounds for production use.

**Key Takeaways**:
1. Foundation Models will revolutionize on-device AI when stable
2. Current beta has specific bugs that require creative solutions
3. Safety systems are overly conservative but can be navigated
4. Apple's patterns work best when followed precisely
5. Progressive degradation ensures users always get responses

**Next Steps**:
- Continue monitoring iOS 26 beta releases
- Maintain comprehensive fallback systems
- Prepare for rapid adoption when framework stabilizes
- Document new patterns as they emerge

For the latest updates and discussions, see the individual markdown files in the project history.