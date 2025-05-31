# Bryan's Brain - AI Development Guide

## Project Overview

**Bryan's Brain** is an iOS productivity app specifically designed for ADHD users. The app focuses on reducing cognitive friction, providing action-oriented guidance, and helping users maintain momentum through "next small step" philosophy.

### Core Philosophy
- **Reduce Friction**: Minimize decision fatigue and cognitive load
- **Action-Oriented**: Focus on what to do next, not overwhelming lists
- **ADHD-Specific**: Address executive function challenges through design
- **Incremental Progress**: Break down large tasks into manageable steps

## App Architecture

### 5-Tab Structure
1. **Chat Tab** (`ChatView.swift`) - AI assistant powered by OpenAI
2. **To-Do List Tab** (`ContentView.swift` - TodoListView) - Rich task management
3. **Calendar Tab** (`TodayCalendarView.swift`) - Google Calendar integration
4. **Scratchpad Tab** (`NotesView.swift`) - Quick notes capture
5. **Roadmap Tab** (`RoadmapView.swift`) - Visual project canvas

### Key Files & Responsibilities

#### Core Data Models
- **`TodoItem`** (`ContentView.swift:22-91`) - Rich task model with ADHD-focused metadata
  - Priority, estimated duration, difficulty, category, project/path, creation date
  - Custom Codable implementation for backward compatibility
- **`CalendarEvent`** (`CalendarEvent.swift`) - Calendar event model with parsed dates
- **`Difficulty`** enum (`ContentView.swift:12-18`) - Low/Medium/High effort levels

#### Data Management  
- **`TodoListStore`** (`TodoListStore.swift`) - Singleton store for task management
  - AppStorage persistence with demo mode support
  - Comprehensive CRUD operations with metadata updates
  - Smart priority management and reordering
- **`CalendarService`** (`CalendarService.swift`) - Google Calendar API integration
  - URLSession-based implementation (no deprecated GTLRService)
  - Full CRUD operations for today's events
  - Robust error handling and token refresh

#### AI Integration
- **`ChatViewModel`** (`ChatViewModel.swift`) - AI conversation management
  - 13+ specialized tools for task and calendar operations
  - Smart message history truncation
  - Async tool execution with proper error handling
- **`OpenAIService`** (`OpenAIService.swift`) - OpenAI API wrapper
  - GPT-4o-mini/4o model selection
  - Comprehensive tool definitions
  - Secure API key management (DEBUG only)

#### UI Components
- **Theme System** (`Theme.swift`) - Consistent color scheme
- **Settings Management** (`SettingsView.swift`) - App configuration
- **Authentication** (`AuthenticationService.swift`) - Google Sign-In

## ADHD-Focused Design Patterns

### Reducing Cognitive Load
```swift
// Expandable task rows - minimize visual clutter until needed
@State private var expandedItemId: UUID? = nil

// Smart defaults - auto-assign priority to reduce decisions  
let defaultPriority = maxPriority + 1
```

### Friction Reduction
```swift
// Swipe actions for common operations
.swipeActions(edge: .leading) { 
    Button { todoListStore.toggleDone(item: item) }
}

// Suggested prompts to reduce decision paralysis
let suggestedPrompts: [String] = [
    "What's on my calendar today?",
    "Plan my day", 
    "Add 'Writing Time' 2 PM to 3 PM today"
]
```

### Action-Oriented AI
```swift
// System prompt emphasizes next small steps
systemPromptContent += "\n5. **Action Focus:** Guide to next small action."

// Tool calls automatically suggest metadata to reduce manual entry
// After adding a task, AI can guess category, project, difficulty
```

## Development Guidelines

### 1. Incremental Changes Only
- **Never break existing functionality**
- Test thoroughly on device before committing
- Maintain backward compatibility for data models
- Use feature flags (`AppSettings`) for experimental features

### 2. ADHD-First Design
```swift
// Good: Clear, immediate feedback
"Task added successfully."

// Bad: Verbose, cognitive overhead  
"The task has been successfully added to your comprehensive task management system."
```

### 3. Data Integrity
```swift
// Always guard against demo mode when saving
guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
    print("DEBUG [Store]: Demo Mode Active: Preventing save operation.")
    return
}
```

### 4. Error Handling
```swift
// Graceful degradation - never crash the user experience
guard let data = data else {
    completion([], nil) // Return empty array, not nil
    return
}
```

## AI Tool Development

### Adding New Tools
1. **Define in OpenAIService** (`OpenAIService.swift:150+`)
```swift
private let newToolDefinition = FunctionDefinition(
    name: "functionName",
    description: "Clear description of what this tool does",
    parameters: .init(
        properties: ["param": .init(type: "string", description: "Parameter description")],
        required: ["param"]
    )
)
```

2. **Add to allTools array** (`OpenAIService.swift:326`)
3. **Implement handler in ChatViewModel** (`ChatViewModel.swift:320+`)
4. **Update system prompt** if needed (`ChatViewModel.swift:140+`)

### Tool Design Principles
- **Specific over generic** - Better to have many focused tools than few complex ones
- **Clear parameter validation** - Always validate and provide helpful error messages
- **Async-friendly** - Use proper async/await patterns for UI responsiveness
- **ADHD-optimized** - Minimize cognitive load in tool interactions

## State Management

### Demo Mode Support
```swift
// All mutating operations must check demo mode
guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
    print("DEBUG: Demo Mode Active: Ignoring operation.")
    return
}
```

### Settings Architecture
```swift
// Use AppSettings constants for keys
static let enableCategoriesKey = "enableCategories"

// Dynamic system prompt based on settings
func updateSystemMessage() {
    let areCategoriesEnabled = UserDefaults.standard.bool(forKey: AppSettings.enableCategoriesKey)
    // Adjust AI behavior based on user preferences
}
```

## Testing & Debugging

### Debug Logging
```swift
if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
    print("DEBUG [Component]: Descriptive message with context")
}
```

### API Key Management
- **Development**: Uses `Secrets.plist` (DEBUG builds only)
- **Production**: Requires secure implementation (currently fatal errors)

### Calendar Integration Testing
- Requires real Google account for full testing
- Use Calendar service error handling for offline scenarios
- Test token refresh scenarios

## Common Improvement Areas

### 1. Enhanced Time Estimation
- Add preset duration buttons (5min, 15min, 30min, 1hr)
- Learn from user patterns to suggest better estimates
- Visual time blocking in calendar view

### 2. Better Priority Visualization
- Color-coded priority indicators
- Progress bars for project completion
- "What's next?" smart suggestions

### 3. Focus Features
- Single-task focus mode
- Distraction logging
- Pomodoro timer integration

### 4. Smarter AI Guidance
- Proactive task breakdown suggestions
- Energy-level aware scheduling
- Cognitive load assessment

## File Structure Reference
```
deep_app/
├── deep_app/
│   ├── ContentView.swift          # Main UI + TodoItem model
│   ├── TodoListStore.swift        # Task data management
│   ├── ChatView.swift            # AI chat interface  
│   ├── ChatViewModel.swift       # AI conversation logic
│   ├── OpenAIService.swift       # OpenAI API integration
│   ├── CalendarService.swift     # Google Calendar API
│   ├── RoadmapView.swift         # Visual project canvas
│   ├── Theme.swift               # Color system
│   ├── SettingsView.swift        # App configuration
│   └── AuthenticationService.swift # Google Sign-In
└── agent_backend/                 # Future multi-agent system (unused)
```

## Remember: ADHD Users First
Every feature should ask: "Does this reduce friction or add it?" If it adds cognitive load without clear benefit, reconsider the approach. The goal is to help users capture thoughts, structure their day, and maintain momentum - not to build the most feature-rich app possible.