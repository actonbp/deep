# Bryan's Brain - AI Development Guide

## Developer Notes
- Bryan is new to Xcode - provide exact click-by-click instructions
- Always specify exact menu paths and button locations
- Break down complex changes into small steps
- Test after each change before proceeding

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
  - **CloudKit sync integration for cross-device synchronization**
- **`CloudKitManager`** (`CloudKitManager.swift`) - iCloud sync operations
  - Full CRUD operations for TodoItem sync
  - Automatic container and zone setup
  - Subscription for change notifications
  - Graceful offline handling
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
- **Theme System** (`Theme.swift`) - Comprehensive design system with colors, typography, spacing
- **Gamified Roadmap** (`RoadmapView.swift`) - Interactive project island visualization
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
    "I don't know where to start",
    "Help me get unstuck", 
    "What should I do next?"
]
```

### Action-Oriented AI
```swift
// System prompt emphasizes next small steps
systemPromptContent += "\n5. **Action Focus:** Guide to next small action."

// Special guidance for overwhelmed users
systemPromptContent += "\n**SPECIAL GUIDANCE: \"Getting Unstuck\" Responses**"
```

## Development Guidelines

### 0. Prerequisites
- **Apple Developer Program membership** ($99/year) required for:
  - CloudKit sync functionality
  - Push notification capabilities
  - Increased memory limits
  - TestFlight beta distribution
  - App Store release
- Xcode with paid developer team configured
- Test devices signed into iCloud

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

## 🚀 Future Direction: Apple Foundation Models

### Transition to On-Device AI (Coming June 2025)

Bryan's Brain is planning to transition from OpenAI to Apple's Foundation Models framework, which will enable:

- **Free AI Chat**: No API costs - everything runs on-device
- **Privacy-First**: User data never leaves their device
- **Offline Support**: Works without internet connection
- **Native Performance**: Optimized for Apple Silicon
- **Instant Responses**: No network latency

**Why This Matters for ADHD Users:**
- Zero cost barrier to access AI assistance
- Always available, even without internet
- Fast, immediate responses reduce friction
- Complete privacy for sensitive thoughts/tasks

**Technical Details:**
- Apple's on-device model (~3B parameters) excels at task-oriented AI
- Native Swift integration with tool calling support
- Guided generation for structured task creation
- Custom adapters can be trained for ADHD-specific behaviors

**Timeline:**
- June 2025: Developer access begins
- Fall 2025: Expected general release with iOS 18.x

For more information: https://developer.apple.com/documentation/foundationmodels

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

## CloudKit Sync Implementation

### Overview
Bryan's Brain now includes full CloudKit sync, allowing tasks to synchronize across all devices signed into the same iCloud account. This addresses a key ADHD need: consistent access to tasks regardless of which device is at hand.

### Architecture
```swift
// CloudKitManager singleton handles all sync operations
private let cloudKitManager = CloudKitManager.shared

// Every data mutation includes CloudKit sync
func addItem(text: String, category: String? = nil, projectOrPath: String? = nil) {
    // ... local operations ...
    cloudKitManager.saveTodoItem(newItem)
}
```

### Key Features
- **Auto-sync on app lifecycle** - Syncs when app enters foreground/background
- **Visual feedback** - Sync status indicator shows current state
- **Manual control** - Refresh button for immediate sync
- **Smart error handling** - "Already exists" errors treated as success
- **Automatic schema creation** - No manual CloudKit setup needed

### Sync Coverage
- ✅ **Create**: New tasks sync immediately
- ✅ **Read**: Tasks fetched from CloudKit on app launch  
- ✅ **Update**: All metadata changes sync (completion, priority, category, etc.)
- ✅ **Delete**: All deletion methods sync to CloudKit
- ✅ **Lifecycle**: Auto-sync on foreground/background transitions

### User Experience
```swift
// Visual sync status in toolbar
SyncStatusView() // Shows: Synced ✅, Syncing... 🔄, Error ❌

// Manual refresh available
Button("Refresh") { 
    await todoListStore.manualRefreshFromCloudKit() 
}
```

### ADHD Benefits
- **Device Flexibility**: Add tasks on iPhone, complete on iPad
- **Reduced Anxiety**: Tasks won't be "lost" on another device
- **Visual Confidence**: Always see sync status
- **Control When Needed**: Manual refresh for peace of mind

### Implementation Notes
```swift
// Always check CloudKit availability
guard cloudKitManager.iCloudAvailable else { 
    print("☁️ iCloud not available, using local storage only")
    return 
}

// Sync operations are fire-and-forget for performance
cloudKitManager.saveTodoItem(item) // Non-blocking

// Current limitation: Requires app restart to see changes from other devices
// Future: Implement push notifications for real-time sync
```

### Debugging CloudKit Issues
```swift
// Console messages indicate sync status
"☁️ iCloud is available" // Good - sync active
"☁️ No iCloud account" // User needs to sign in
"☁️ Failed to save item: ..." // Network or permission issue
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
- Visual hierarchy in task lists

### 3. Improved Getting Started Experience
- Context-aware guidance for overwhelmed users
- Micro-action suggestions (2-5 minute tasks)
- Momentum-based task recommendations

## Security Best Practices

### API Keys
- Always use `Secrets.plist` for development
- Never commit sensitive files to version control
- Use `.gitignore` properly for `.env` and secret files

### User Data
- Respect demo mode in all data operations
- Graceful offline handling
- Secure token storage for Google services

## ⚠️ CRITICAL: Git Recovery Operations

### Lessons Learned from Major Recovery Incident

On May 31, 2025, a git reset operation resulted in the loss of critical features, particularly the **expandable task metadata editing UI**. This feature allows users to click tasks to expand and edit category/project metadata - essential for the roadmap functionality.

### What Can Go Wrong
1. **File presence ≠ Feature completeness** - ContentView.swift existed but was missing expandable task UI
2. **Newer commits may have critical fixes** - CalendarService had ISO date fixes in a later commit
3. **Untracked files disappear** - `.cursor/rules/` folder was lost in reset
4. **Feature interdependencies** - Missing expandable tasks breaks roadmap organization

### Required Verification After ANY Recovery

```bash
# Critical feature checks
grep -q "expandedItemId" deep_app/deep_app/ContentView.swift || echo "❌ MISSING: Expandable tasks!"
grep -q "demonstrationModeEnabled" deep_app/deep_app/TodoListStore.swift || echo "❌ MISSING: Demo mode!"
grep -q "I don't know where to start" deep_app/deep_app/ChatViewModel.swift || echo "❌ MISSING: Getting started!"

# File size sanity checks
wc -l deep_app/deep_app/ContentView.swift # Should be ~500+ lines
wc -l deep_app/deep_app/TodoListStore.swift # Should be ~400+ lines
```

### Safe Recovery Pattern

```bash
# 1. Document current state
git status > recovery_backup.txt
git stash list >> recovery_backup.txt

# 2. Create safety backup
git stash push -m "Pre-recovery backup $(date)"

# 3. Check commit history for the file
git log --oneline -10 -- deep_app/deep_app/ContentView.swift

# 4. Preview changes before applying
git diff HEAD 1de9b7f -- deep_app/deep_app/ContentView.swift

# 5. Recover with specific files (never use --hard without backup)
git checkout 1de9b7f -- deep_app/deep_app/ContentView.swift

# 6. IMMEDIATELY run feature verification
# See .cursor/rules/feature_verification.mdc
```

### Red Flags Requiring Investigation
- ContentView.swift < 400 lines (missing expandable UI)
- No `expandedItemId` in ContentView (missing click-to-edit)
- No `updateTaskCategory` methods (missing metadata updates)
- Missing `.cursor/rules/` folder (documentation lost)

**Remember**: After any recovery operation, manually test in Xcode that you can click tasks to expand and edit metadata! 

## 🎮 Gamified Roadmap Implementation

### Overview (December 2024)
The roadmap has been completely reimplemented as an interactive "quest map" using gaming principles to make project management more engaging for ADHD users.

### Key Features
- **🏝️ Project Islands** - Each project is visualized as a floating island with gradients and shadows
- **🎯 Quest Dots** - Tasks displayed as small circles in a grid (green when completed)
- **📊 Progress Rings** - Circular progress indicators around each island
- **🏆 Level System** - Projects have levels (Lv 1-5) based on task count
- **💎 XP System** - 10 experience points awarded per completed task
- **🌟 Achievement Badges** - Floating gold stars for projects with 5+ completed tasks or 80%+ progress
- **🌉 Bridges** - Curved connecting lines between related projects
- **🌤️ Sky Background** - Beautiful cyan-to-blue gradient background
- **🔍 Zoom/Pan Controls** - Pinch to zoom, drag to explore, reset button

### Implementation Details

#### Project Types & Colors
```swift
enum ProjectType: String, Codable, CaseIterable, Identifiable {
    case work = "Work"        // 💼 Blue (ProjectBlue)
    case personal = "Personal" // 🚀 Purple (ProjectPurple)
    case health = "Health"     // 💚 Green (ProjectGreen)
    case learning = "Learning" // 📚 Yellow (ProjectYellow)
}
```

#### Gamification Logic
```swift
// Calculate progress
let progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0

// Calculate level based on number of tasks
let level = min(5, max(1, totalTasks / 3))

// Calculate XP (10 points per completed task)
let xp = completedTasks * 10

// Achievement criteria
let hasAchievement = completedTasks >= 5 || progress >= 0.8
```

#### Color System Integration
```swift
// Assets.xcassets colors used:
- ProjectBlue: #DBEAFE (light) / #1E40AF (dark)
- ProjectPurple: #EDE9FE (light) / #6B21A8 (dark)  
- ProjectGreen: #DCFCE7 (light) / #166534 (dark)
- ProjectYellow: #FEF3C7 (light) / #A16207 (dark)
```

### ADHD Benefits
- **Visual Progress** - Dopamine reward from seeing islands fill up
- **Clear Hierarchy** - Levels and achievement badges show importance
- **Micro-Rewards** - Immediate feedback for task completion
- **Spatial Memory** - Remember projects by their visual position
- **Engaging Metaphor** - "Conquering islands" feels more rewarding than "managing tasks"

### Technical Architecture
- **ProjectIsland** model stores island data and position
- **GameMapCanvasView** handles layout and rendering
- **ProjectIslandView** creates individual island UI
- **BridgeView** draws curved connections between islands
- Zoom/pan gestures with momentum and bounds checking
- Automatic island positioning with overflow handling

### Performance Optimizations
- Islands positioned statically (no real-time physics)
- Efficient SwiftUI rendering with proper view composition
- Gesture handling optimized for smooth interactions
- Color system integrated with existing theme architecture