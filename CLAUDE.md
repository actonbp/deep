# Bryan's Brain - AI Development Guide

## Developer Notes
- Bryan is new to Xcode - provide exact click-by-click instructions
- Always specify exact menu paths and button locations
- Break down complex changes into small steps
- Test after each change before proceeding

## 🚦 Current Development Status (December 28, 2024)

### Active Development
The project is currently in active development with two major features being worked on:

1. **ChatGPT-Style Image Upload** - Adding ability to upload images in chat for AI analysis
2. **Enhanced ADHD Roadmap** - Improving the roadmap tab with task dependencies and visual paths

### Git Branch Structure
```
main (stable)
├── feature/image-upload      ← Current branch for image functionality
└── feature/enhanced-roadmap  ← Branch for roadmap improvements
```

**Important**: Always check which branch you're on before making changes!
- `main`: Stable, production-ready code with all warnings fixed
- `feature/*`: Experimental branches for new features

### Recent Checkpoint
- **Commit**: `f6dd888` - Fixed all Xcode warnings (December 28, 2024)
- **Status**: Clean build, no warnings, ready for feature development
- **Safety**: Main branch is stable and can be returned to if features break

### Next Steps
1. **Image Upload**: Implement PHPickerViewController for ChatGPT-style image selection
2. **Roadmap Enhancement**: Add task dependency visualization and ADHD-specific path features

**Note for AI Agents**: If you're picking up development, check `git status` and `git branch` first to understand the current state. The main branch is always safe to return to. See [BRANCH_GUIDE.md](BRANCH_GUIDE.md) for detailed branch workflow instructions.

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
  - 20+ specialized tools for task, calendar, and health operations
  - Smart message history truncation with tool call preservation
  - Async tool execution with proper error handling
  - **Dual AI Support**: OpenAI + Apple Foundation Models
  - **O3 Model Support**: Advanced reasoning with 5-minute timeout
  - **Health-aware recommendations**: Uses HealthKit data for ADHD insights
- **`OpenAIService`** (`OpenAIService.swift`) - OpenAI API wrapper
  - **Model Selection**: gpt-4o-mini, gpt-4o, **o3** with adaptive timeouts
  - **Dynamic Model Selection**: Uses Settings preference instead of hardcoded
  - Comprehensive tool definitions with health integration
  - Secure API key management (DEBUG only)
- **`AppleFoundationService`** (`AppleFoundationService.swift`) - Apple on-device AI
  - **iOS 26+ Support**: Foundation Models framework integration
  - **Progressive Tool Degradation**: Falls back gracefully when tools fail
  - **Safety Optimizations**: Workarounds for iOS 26 beta content filters
  - **Complex Question Detection**: Adaptive 5-minute timeout for reasoning
  - **Better Error Messages**: Clear guidance when conflicts occur

#### UI Components
- **Theme System** (`Theme.swift`) - Comprehensive design system with colors, typography, spacing
- **Gamified Roadmap** (`RoadmapView.swift`) - Interactive project island visualization
- **Settings Management** (`SettingsView.swift`) - App configuration with health integration
- **Authentication** (`AuthenticationService.swift`) - Google Sign-In
- **Enhanced Chat UI** (`ChatView.swift`) - **Markdown support** and **Liquid Glass styling**
  - **Markdown Rendering**: AI responses with **bold**, *italic*, lists, and formatting
  - **Liquid Glass Effects**: Material backgrounds, glass overlays, enhanced depth
  - **O3 Thinking Indicator**: Shows "🧠 Thinking deeply..." during reasoning
  - **Selectable Text**: Copy-paste support for all messages

#### Health Integration
- **`HealthKitService`** (`HealthKitService.swift`) - Apple Health data access
  - **Sleep Quality Tracking**: REM, core, deep sleep analysis
  - **Activity Monitoring**: Steps, exercise, heart rate data
  - **ADHD Correlation**: Links health metrics to productivity recommendations
  - **Privacy-First**: All data stays on device
- **`GetHealthSummaryTool`** (`ToolCalling/GetHealthSummaryTool.swift`) - Health data tool
  - **Dual AI Support**: Works with both OpenAI and Foundation Models
  - **Smart Recommendations**: "Your sleep was short, focus on easier tasks today"
  - **Settings Integration**: Respects HealthKit toggle in Settings

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

### Foundation Models Best Practices (Based on Apple's Patterns)

**Tool Design Patterns from Apple's Sample Code:**
- **Simple, focused tools**: Each tool does one specific thing (e.g., CalendarTool only fetches calendar events, ContactsTool only fetches contacts)
- **Clear verb-first naming**: `getCalendarEvents`, `getContacts` - immediately clear what the tool does
- **Flexible response types**: Return simple strings for basic data, GeneratedContent for structured data
- **Robust error handling**: Always wrap in try/catch, return sensible fallbacks or throw errors
- **Concurrent execution**: Tools marked `async throws` to support parallel execution

**Key Implementation Differences:**
| Aspect | Current Implementation | Apple's Pattern |
|--------|----------------------|-----------------|
| Tool Names | `listCurrentTasks` | `getTasks` or `getTaskList` |
| Arguments | `retrieve: Bool` | Specific parameters only |
| Responses | Plain strings | Mixed: strings or GeneratedContent |
| Error Handling | Basic logging | Try/catch with fallbacks |

**Apple's 6-Phase Tool Process:**
1. Present available tools to the model
2. Submit prompt to the model
3. Model generates tool arguments
4. Tool executes with generated arguments
5. Tool returns output to model
6. Model produces final response using tool output

For detailed improvement suggestions, see `FoundationModelsImprovementGuide.md`

## 🌐 Future Direction: Vercel Functions Backend

### Production Architecture for OpenAI Integration
Bryan's Brain will use **Vercel Functions** for secure, scalable backend infrastructure:

```
iPhone App → Vercel Functions (Serverless) → OpenAI API
```

### Why Vercel Functions?
- **Serverless**: No server management, scales automatically
- **Pay-per-request**: Cost-effective for growing user base
- **Easy deployment**: Git push → Automatic deployment
- **Edge functions**: Fast response times globally
- **Built-in monitoring**: Analytics and error tracking included

### Implementation Plan
1. **Authentication Layer**
   - User accounts with secure token management
   - Rate limiting per user to control costs
   - Premium tier management for O3 access

2. **API Endpoints**
   ```javascript
   // Example: /api/chat
   export default async function handler(req, res) {
     const { message, tools } = req.body;
     const { userId } = req.auth;
     
     // Rate limiting check
     // Forward to OpenAI with server-side API key
     // Return response
   }
   ```

3. **Cost Management**
   - Free tier: Apple Foundation Models (on-device)
   - Premium tier: OpenAI GPT-4o/O3 via Vercel
   - Usage tracking and billing integration

4. **Security Features**
   - API keys stored in Vercel environment variables
   - JWT authentication for all requests
   - Request validation and sanitization

### Hybrid AI Strategy
```swift
// In ChatViewModel
if useLocalModel && appleFoundationAvailable {
    // Free: Apple Foundation Models
    return await processWithApple(message)
} else if userHasPremiumAccess {
    // Premium: OpenAI via Vercel
    return await processWithVercel(message)
} else {
    // Prompt to upgrade
    return "Upgrade to Premium for advanced AI features"
}
```

### Timeline
- **Phase 1** (Current): Direct OpenAI integration for development
- **Phase 2** (Q2 2025): Vercel Functions MVP with authentication
- **Phase 3** (Fall 2025): Full hybrid system with Apple Foundation Models

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

## Recent Enhancements (December 2024)

### Enhanced AI Integration
- **O3 Model Support**: Added OpenAI's advanced reasoning model to settings (`SettingsView.swift:9`)
  - Extended timeout to 5 minutes for complex reasoning tasks (`OpenAIService.swift:536-540`)
  - Added visual "🧠 Thinking deeply..." indicator during O3 processing (`ChatView.swift`)
  - Fixed model selection routing to properly use user's choice (`OpenAIService.swift:501`)
- **Adaptive Timeouts**: Dynamic timeout system based on question complexity
- **Improved Error Messages**: Better distinction between OpenAI and Foundation Models errors
- **Model Selection Warnings**: Visual indicators when on-device model overrides OpenAI selection (`SettingsView.swift:106-116`)

### UI/UX Improvements
- **Markdown Rendering**: AI chat messages now support rich formatting (`ChatView.swift`)
  - Uses AttributedString for native SwiftUI rendering with `MarkdownText` view
  - Preserves whitespace and inline formatting via `.inlineOnlyPreservingWhitespace`
  - Fallback to plain text if markdown parsing fails
- **Liquid Glass Enhancement**: Improved visual materials throughout the interface
  - Enhanced chat bubbles with `.ultraThinMaterial` and `.regularMaterial`
  - Better visual hierarchy and depth perception
  - Automatic Liquid Glass effects already working in iOS 26

### HealthKit Integration ✅ Working!
- **Basic Health Data Access**: Successfully integrated with proper entitlements
- **GetHealthSummaryTool**: AI tool for accessing sleep, activity, and heart rate data (`ToolCalling/GetHealthSummaryTool.swift`)
- **HealthKitService**: New service for basic health data access (`HealthKitService.swift`)
  - Sleep quality tracking (REM, core, deep sleep analysis)
  - Activity monitoring (steps, exercise, heart rate data)
  - ADHD correlation links health metrics to productivity recommendations
- **Privacy-First**: All data stays on device, respects user permissions
- **Info.plist Integration**: Added `NSHealthShareUsageDescription` for App Store compliance (`Info.plist:32-33`)
- **Entitlements**: Properly configured with HealthKit capability (`deep_app.entitlements`)

#### Future Health Features
- **Workout Celebrations**: "🎉 Great job on that workout! Your body will thank you with better focus today."
- **Sleep-Based Task Suggestions**: Adjust task difficulty recommendations based on sleep quality
- **Heart Rate Variability**: Detect stress levels and suggest break times
- **Activity Reminders**: "You've been sitting for 2 hours - time for a quick walk to reset your ADHD brain!"
- **Medication Reminders**: Track ADHD medication timing with health metrics correlation

### Foundation Models Improvements
- **Token Limit Fixes**: Reduced response size in GetTasksTool and SimpleShowTasksTool to prevent overflow
- **Extended Timeouts**: 5-minute timeout for complex questions vs 2 minutes for simple ones (`AppleFoundationService.swift`)
- **Better Error Handling**: More descriptive error messages for troubleshooting
- **System Prompt Optimization**: Enhanced prompts for more natural tool usage
- **Complex Question Detection**: Automatic timeout extension for build/tool commands

### Code Architecture Enhancements
- **ChatView.swift**: Added MarkdownText view and enhanced UI materials
- **SettingsView.swift**: Added O3 model option and HealthKit toggle with auto-permissions
- **OpenAIService.swift**: Dynamic model selection and adaptive timeouts
- **AppleFoundationService.swift**: Improved timeout handling and error messages
- **ChatViewModel.swift**: Added `isThinking` state for O3 reasoning indicator

### Technical Fixes
- **Model Selection Bug**: Fixed hardcoded model to use user's Settings preference
- **Timeout Conflicts**: Resolved confusion between OpenAI O3 and Foundation Models
- **Markdown Parsing**: Robust error handling with graceful fallback to plain text
- **Health Permissions**: Automatic HealthKit authorization flow with toggle feedback