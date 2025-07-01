
# Bryan's Brain Feature Inventory

This document provides a definitive list of features that MUST exist in each file. Use this to verify completeness after any recovery operation.

## ContentView.swift (~1400+ lines) ✅ **UPDATED JUNE 30, 2025 - iOS 26 GLASS**

### State Variables Required
- `@StateObject private var store = TodoListStore()`
- `@State private var draggedItem: TodoItem?`
- `@State private var expandedItemId: UUID? = nil` ⚠️ **CRITICAL**
- `@State private var editingCategory: String = ""`
- `@State private var editingProject: String = ""`
- `@State private var showCompletedTasks = true` ⚠️ **NEW**

### Key Features
1. **5-Tab TabView Structure**
   - ChatView (message.fill)
   - TodoListView (list.bullet.clipboard.fill)
   - TodayCalendarView (calendar)
   - NotesView (note.text)
   - RoadmapView (map.fill)

2. **Enhanced To-Do List UI** ⚠️ **MAJOR UPDATE**
   - **Separate Sections**: `incompleteTasks` and `completedTasks` views
   - **CompactTaskRowView**: Minimal display for completed items
   - **Time Estimates**: `calculateTotalTime()` function for incomplete tasks
   - **Collapsible Completed**: Toggle button with animation

3. **Expandable Task Metadata with MetadataCardView** ⚠️ **COMPLETELY REDESIGNED**

4. **iOS 26 Liquid Glass Extensions** ✨ **NEW JUNE 30, 2025**
   - `glassInputStyle()` - Glass input field styling
   - `glassButtonStyle(prominent: Bool)` - Glass button effects
   - `conditionalGlassEffect<S: Shape>(in shape: S)` - Safe glass application
   - `conditionalGlassBackground<S: Shape>()` - Transparent backgrounds
   - `SafeGlassEffectModifier` - Console warning prevention
   ```swift
   if expandedItemId == item.id {
       LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
           // Category Card (if categories enabled)
           // Project Card with clean picker
           // Difficulty Card (if available)
           // Created Date Card
       }
       // Summary section (if needed)
   }
   ```

4. **MetadataCardView Component** ⚠️ **NEW CRITICAL COMPONENT**
   - Generic card component with icon, title, value
   - Support for both read-only and interactive content
   - Color-coded with opacity backgrounds and borders

3. **Swipe Actions**
   - Mark done with haptic feedback
   - Delete with confirmation

4. **Sound Effects**
   - `playSound()` function
   - Task completion sound

5. **Drag & Drop Reordering**
   - `.onMove` handler
   - Priority updates

## ChatView.swift ⚠️ **MAJOR UPDATE - IMAGE UPLOAD**

### New Required Features ✅ **JUNE 2025**
1. **Image Upload Support**
   - `@State private var selectedImages: [UIImage] = []`
   - `@State private var showingImagePicker = false`
   - Camera button with SF Symbol `camera.fill`
   - Image preview area with grid layout
   - Integration with `ImagePicker` component

2. **Enhanced Message Display**
   - Support for `MessageContent` enum (text/image arrays)
   - Grid layout for displaying multiple images
   - Image resizing and aspect ratio handling

## ImagePicker.swift ⚠️ **NEW FILE**

### Required Components
- `PHPickerViewController` wrapper for SwiftUI
- `@Binding var selectedImages: [UIImage]`
- Image compression and base64 conversion utilities
- Multi-image selection with configurable limits

## AIAgentManager.swift ⚠️ **NEW FILE**

### Required Features
1. **Background Task Registration**
   - Static registration tracking to prevent duplicates
   - `BGTaskScheduler` integration
   - Task identifiers: `com.bryanbrain.ai.agent.refine`, `com.bryanbrain.ai.agent.daily`

2. **ADHD Time-Blocking Analysis**
   - Comprehensive system prompts for cognitive load assessment
   - JSON response parsing for task refinements
   - Metadata enrichment (duration, difficulty, category)
   - Energy management recommendations

3. **Settings Integration**
   - `@AppStorage` for enable/disable toggle
   - Last processing date tracking
   - Insights persistence and display

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