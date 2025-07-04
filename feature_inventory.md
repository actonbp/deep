
# Bryan's Brain Feature Inventory

This document provides a definitive list of features that MUST exist in each file. Use this to verify completeness after any recovery operation.

## ContentView.swift (~500+ lines)

### State Variables Required
- `@StateObject private var store = TodoListStore()`
- `@State private var draggedItem: TodoItem?`
- `@State private var expandedItemId: UUID? = nil` ⚠️ **CRITICAL**
- `@State private var editingCategory: String = ""`
- `@State private var editingProject: String? = nil`

### Key Features
1. **5-Tab TabView Structure**
   - ChatView (message.fill)
   - TodoListView (list.bullet.clipboard.fill)
   - TodayCalendarView (calendar)
   - NotesView (note.text)
   - RoadmapView (map.fill)

2. **Expandable Task Metadata** ⚠️ **MOST COMMONLY LOST**
   ```swift
   if expandedItemId == item.id {
       // Category field (if enabled)
       // Project/Path picker
       // Difficulty display
       // Creation date
   }
   ```

3. **Swipe Actions**
   - Mark done with haptic feedback
   - Delete with confirmation

4. **Sound Effects**
   - `playSound()` function
   - Task completion sound

5. **Drag & Drop Reordering**
   - `.onMove` handler
   - Priority updates

## TodoListStore.swift (~400+ lines)

### Required Properties
- `@AppStorage("demonstrationModeEnabled")` for demo mode
- `@AppStorage("debugLogEnabled")` for logging
- `userDefaults` for persistence

### Required Methods
- `populateWithSampleData()` - Demo mode data
- `updateTaskCategory(taskId:category:)`
- `updateTaskProjectOrPath(taskId:projectOrPath:)`
- `updateTaskDifficulty(taskId:difficulty:)`
- `updateTaskDuration(taskId:duration:)`
- `markTaskComplete(taskId:)`
- `updateOrder(fromOffsets:toOffset:)`
- `createTaskFromText(_:)`

### Demo Mode Guards
Every mutating method MUST check:
```swift
guard !demonstrationModeEnabled else {
    debugLog("Demo mode: [operation] blocked")
    return
}
```

## ChatViewModel.swift

### Required Suggested Prompts
```swift
let suggestedPrompts: [String] = [
    "I don't know where to start",  // ⚠️ CRITICAL
    "Help me get unstuck",          // ⚠️ CRITICAL
    "What should I do next?",       // ⚠️ CRITICAL
    "Plan my day",
    "What's on my calendar today?",
    "Estimate task times"
]
```

### System Prompt Must Include
- Base ADHD coach guidance
- **Special "Getting Unstuck" section**
- Tool usage instructions
- Current date/time context

### Welcome Message
Must mention: "Feeling stuck or don't know where to start? Just ask"

## OpenAIService.swift

### Required Tool Handlers
- `addTaskToList`
- `listCurrentTasks`
- `removeTaskFromList`
- `updateTaskPriorities`
- `updateTaskEstimatedDuration`
- `createCalendarEvent`
- `updateTaskCategory`
- `updateTaskProjectOrPath`
- `updateTaskDifficulty`
- `markTaskComplete`

## CalendarService.swift

### Critical Implementation Details
- ⚠️ **MUST use ISO date comparison**, not tolerance-based
- Token refresh mechanism
- Primary calendar detection

## SettingsView.swift

### Required Settings
- OpenAI API Key management
- Model selection (GPT-4o-mini/GPT-4o)
- Google Sign-In
- Categories toggle (`enableCategoriesKey`)
- Demo mode toggle (`demonstrationModeEnabledKey`)
- Debug logging toggle

## RoadmapView.swift

### Required Features
- Zoom/Pan gestures
- Project grouping visualization
- Task positioning by priority
- Difficulty-based sizing

## Theme.swift

### Required Colors
- Background colors for light/dark
- Text colors for primary/secondary
- Accent colors
- Delete/Done action colors

## Missing Any of These = Incomplete Recovery!

If ANY of the above features are missing after a recovery operation, the recovery is incomplete and the app will not function as designed.

## 📅 June 11, 2025 Update: Local Model Integration Features

### SettingsView.swift (Updated)
- **New Toggle**: "Use On-Device Model (Free)" with descriptive text
- `@AppStorage("useLocalModel")` binding

### ChatViewModel.swift (Updated)
- `@AppStorage("useLocalModel")` property at line ~12
- Service switching logic in `continueConversation()`
- `_localService: Any?` stored property for iOS 26+ compatibility

### New Files Required

#### AppleFoundationService.swift (~200 lines)
```swift
@available(iOS 26.0, *)
final class AppleFoundationService {
    func processConversation(messages:) async -> APIResult
    // Progressive degradation (3 attempts)
    // Timeout protection
    // Retry logic
}
```

#### FoundationModelTools.swift (~1000 lines)
- 22 tool implementations using `Tool` protocol
- `@Generable` structs for arguments
- `FoundationModelTools.all()` and `.essential()`
- `DiagnosticTool` for testing

#### Documentation Files
- `FoundationModelsCrashWorkaround.md`
- `FoundationModelsToolResponseIssue.md`
- `LOCAL_MODEL_ARCHITECTURE.md`

### Critical Availability Checks
```swift
// In views using local model
#if canImport(FoundationModels)
if #available(iOS 26.0, *) {
    // Local model code
}
#endif
```

### Required Imports
```swift
#if canImport(FoundationModels)
import FoundationModels
#endif
```

### Tool Names Must Match
OpenAI tools → Foundation Model tools mapping:
- `addTaskToList` → `addTaskToList` ✅
- `listCurrentTasks` → `listCurrentTasks` ✅
- `markTaskComplete` → `markTaskComplete` ✅
- etc.

### Debug Logging
All tools must include:
```swift
print("DEBUG [ToolName]: Message")
```

⚠️ **CRITICAL**: If local model toggle exists but these files/features are missing, the app will crash on iOS 26 devices! 