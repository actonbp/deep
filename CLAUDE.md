# Bryan's Brain - AI Development Guide

## Developer Notes
- Bryan is new to Xcode - provide exact click-by-click instructions
- Always specify exact menu paths and button locations
- Break down complex changes into small steps
- Test after each change before proceeding

## 🚦 Current Development Status (July 23, 2025)

### Recently Completed ✅
Major iOS 26 enhancements and stability improvements:

1. **✅ ChatGPT-Style Image Upload** - Full multimodal AI with photo analysis capability
2. **✅ AI Agent Mode** - Background task refinement with ADHD time-blocking insights
3. **✅ Enhanced To-Do UI** - Compact, elegant metadata cards with improved visual hierarchy
4. **✅ Advanced Project Management** - Clean picker interface with hidden "Add New" functionality
5. **✅ iOS 26 Liquid Glass Effects** - Complete app transformation with translucent glass materials
6. **✅ Quest Map Functionality** - Working chronological task progression for projects
7. **✅ Performance Optimizations** - Fixed type-checking timeouts and rendering issues
8. **✅ Tool Protocol Compliance** - All Apple Foundation Models tools now working correctly
9. **✅ iOS 26 Beta 4 JSON Schema Support** - Foundation Models now support cross-LLM compatibility
10. **✅ Liquid Glass UI Refinements** - Enhanced chat interface with improved visibility and transparency
11. **✅ Markdown Rendering Fix** - Chat messages now properly display formatted markdown
12. **✅ Repository Cleanup** - Removed duplicates, reorganized docs, pushed to GitHub

### Git Branch Structure
```
main (stable) ← CURRENT
├── feature/macos-compatibility  ← Cross-platform macOS support (experimental)
├── feature/image-upload         ← Merged: iOS 26 liquid glass enhancements
└── feature/enhanced-roadmap     ← Merged: Quest map functionality
```

**Important**: Always check which branch you're on before making changes!
- `main`: Stable, production-ready code with all features integrated
- `feature/macos-compatibility`: Experimental cross-platform work

### Recent Checkpoint (July 23, 2025)
- **Latest Session**: Markdown rendering fix and repository cleanup
- **Status**: ✅ **Stable build** with full markdown support in chat
- **Major Updates**: 
  - Fixed markdown rendering - now properly displays headers, bold, lists, etc.
  - Cleaned up repository - removed duplicate files, reorganized README
  - All 27 Foundation Models tools updated for PromptRepresentable API
  - Added JSON Schema utilities for cross-LLM compatibility
  - Successfully pushed all changes to GitHub
- **Safety**: All improvements tested, committed, and pushed to main branch

### Next Steps
1. **Feature Development**: Ready for new features or enhancements
2. **Subway Map UI**: Future enhancement for task dependency visualization
3. **Branch Cleanup**: Consider deleting merged feature branches
4. **Documentation**: Update outdated docs (TOOL_RESPONSE_FIX_SUMMARY.md, etc.)

## 🤖 AI Agent Handoff Guide

**If you're a new AI agent picking up this project, START HERE:**

### Essential First Steps
1. **Check current state**: `git status` and `git branch` (should be on `feature/image-upload`)
2. **Review latest commit**: `72b9b87` - iOS 26 Liquid Glass transformation complete
3. **Read this file**: CLAUDE.md contains all architecture and development guidelines
4. **Check compilation**: Open in Xcode and verify no errors (should compile clean)

### Current Branch Status ✅
- **Branch**: `main` 
- **Status**: Stable with all iOS 26 enhancements integrated
- **Last tested**: July 22, 2025 - iOS 26 Beta 4 improvements (compiles clean)
- **Ready for**: Production use and GitHub push

### Key Files to Understand
- `ContentView.swift` (~1400 lines) - Main to-do list with iOS 26 glass extensions
- `ChatView.swift` - Enhanced with floating glass input, transparent bubbles, accent-colored title
- `RoadmapView.swift` - Gamified roadmap with working quest map (tap projects)
- `QuestChainView.swift` - Quest chain visualization (chronological tasks)
- `MinimalRoadmapView.swift` - Alternative roadmap view modes
- `AIAgentManager.swift` - Background processing system
- `OpenAIService.swift` - API integration with Vision support + analyzeProject tool
- `iOS26TrueGlassExtensions.swift` - NEW: Experimental liquid glass effects (pushing public API limits)

### Development Guidelines
- **NEVER break existing functionality** - Test every change in Xcode
- **Incremental changes only** - Small, safe improvements
- **Follow ADHD-first design** - Reduce cognitive load, minimize friction
- **Use existing patterns** - Follow established code conventions

### Current Status Summary ✅ **All Working as of June 30, 2025**
- **Image Upload**: ✅ Working - Photo selection, Vision API, chat integration
- **AI Agent Mode**: ✅ Working - Background processing, ADHD analysis, metadata enrichment  
- **Enhanced UI**: ✅ Working - Metadata cards, compact completed tasks, time estimates
- **Project Management**: ✅ Working - Clean picker, hidden "Add New" functionality
- **CloudKit Sync**: ✅ Working - Cross-device task synchronization
- **All AI Models**: ✅ Working - OpenAI (gpt-4o, gpt-4o-mini, o3) + Foundation Models
- **Core Features**: ✅ Working - Chat, to-do list, calendar, scratchpad, roadmap
- **iOS 26 Glass**: ✅ Working - Complete liquid glass UI throughout app
- **Quest Map**: ✅ Working - Chronological task progression when tapping projects

**Build Status**: ✅ Compiles cleanly, no warnings, tested on device by Bryan

### ⚠️ Known Gotchas & Solutions
1. **GlassEffectContainer doesn't exist** - Use standard VStack instead
2. **Tool protocol conformance** - Foundation Models tools need `@Generable` with actual properties
3. **Type-checking timeouts** - Break complex expressions into computed properties
4. **Console warnings** - Use `SafeGlassEffectModifier` for iOS 26 glass effects
5. **Blank quest map** - Was caused by missing GlassEffectContainer, now fixed

### Emergency Recovery
If anything breaks, the `main` branch is always safe to return to. See "CRITICAL: Git Recovery Operations" section in this file for detailed recovery procedures.

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
  - **🖼️ Image Upload**: ChatGPT-style multimodal AI with photo selection and analysis
- **AI Agent Manager** (`AIAgentManager.swift`) - **Background task processing**
  - **ADHD Time-Blocking Analysis**: Comprehensive task metadata enrichment
  - **Background Processing**: iOS BackgroundTasks framework integration
  - **Energy Management**: Cognitive load assessment and scheduling recommendations
  - **Settings Integration**: Toggle with status indicators and manual testing

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

## 🌟 iOS 26 Liquid Glass Implementation

### Overview (June 30, 2025)
Bryan's Brain now features complete iOS 26 Liquid Glass integration throughout the app, providing an ethereal, translucent UI that allows background content to show through interface elements.

### Key Glass Effect Components
#### Glass Extensions (`ContentView.swift`)
```swift
// Core glass effect helpers - available throughout app
func glassInputStyle() -> some View // Input fields with glass background
func glassButtonStyle(prominent: Bool) -> some View // Buttons with glass effects
func conditionalGlassEffect<S: Shape>(in shape: S) -> some View // Safe glass application
func conditionalGlassBackground<S: Shape>(_ color: Color, opacity: Double, in shape: S) -> some View
```

#### Enhanced Views with Glass Effects
- **Chat Interface** (`ChatView.swift`):
  - **Ultra-thin material bubbles** for maximum transparency
  - **Floating input area** with glass background
  - **Translucent suggested prompts** with glass capsules
  - **Glass navigation bar** (transparent on iOS 26)

- **Task Management** (`ContentView.swift`):
  - **Glass input bar** for new task creation
  - **Glass task cards** with ultra-thin material
  - **Glass time estimate badges** with enhanced transparency
  - **Glass backgrounds** throughout list views

- **Settings & Forms** (`SettingsView.swift`):
  - **Glass form styling** with hidden scroll backgrounds
  - **Material-enhanced sections** for better depth

#### Technical Implementation
```swift
// iOS 26 availability checking with graceful fallback
if #available(iOS 26.0, *) {
    self.background(.ultraThinMaterial, in: shape)
        .glassEffect(in: shape) // Native iOS 26 glass
} else {
    self.background(.thinMaterial, in: shape) // Fallback for older iOS
}
```

#### Safe Glass Effect System
- **Console warning prevention** with `SafeGlassEffectModifier`
- **Progressive transparency** (ultraThinMaterial > thinMaterial > regularMaterial)
- **Automatic fallbacks** for unsupported configurations
- **Performance optimized** with computed properties to prevent type-checking timeouts

### Glass Effect Strength Levels
1. **Ultra-transparent** (`.ultraThinMaterial`): Maximum see-through for dramatic effect
2. **Enhanced transparency** (opacity multipliers reduced to 0.3x)
3. **Layered glass** (multiple material layers for depth)
4. **Conditional transparency** based on iOS version and device capabilities

### User Experience Benefits
- **Visual hierarchy** through varying transparency levels
- **Contextual awareness** - always see what's behind UI elements
- **Modern aesthetic** that feels native to iOS 26
- **Reduced cognitive load** through visual lightness
- **ADHD-friendly** minimal visual clutter

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

### 🎉 iOS 26 Beta 4 Update: JSON Schema for @Generable Models (July 22, 2025)

**Major breakthrough for cross-platform AI integration!**

Apple just released iOS 26 Beta 4 with a game-changing update:
- `GenerationSchema` is now **Codable** and exposes JSON Schema format
- `@Generable` models can now work with **any LLM** (OpenAI, Claude, etc.), not just Apple Foundation Models
- This enables truly unified tool definitions across all AI systems

**What this means for Bryan's Brain:**
1. **Single Tool Definition**: Define tools once using `@Generable`, use with both OpenAI and Apple
2. **Seamless Migration**: Export Apple tool schemas as JSON for OpenAI compatibility
3. **Reduced Complexity**: No more maintaining two separate tool systems
4. **Future-Proof**: Ready for hybrid AI (local + cloud) without code duplication

**Example Implementation:**
```swift
// Define once with @Generable
@Generable
struct CreateTaskModel {
    @Guide(description: "Task title")
    let title: String
    @Guide(description: "Estimated duration in minutes")
    let duration: Int?
}

// Export schema for OpenAI
let schema = GenerationSchema(CreateTaskModel.self)
let jsonSchema = try JSONEncoder().encode(schema)
// Now OpenAI can use the exact same model structure!
```

This update dramatically simplifies our planned transition to a hybrid AI system where users can seamlessly switch between free on-device AI and premium cloud AI features.

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

**⚠️ CRITICAL: Two Separate AI Pathways**

Bryan's Brain has **two completely different AI systems** with **different tool calling approaches**:

### 1. **OpenAI Tools** (Primary Path - Cloud-based)
- **File**: `OpenAIService.swift`
- **Structure**: Uses `FunctionDefinition` with JSON parameter schemas
- **Robust**: More error-tolerant, handles complex tool calls well
- **Usage**: Production-ready, main development path

### 2. **Apple Foundation Models Tools** (On-device AI)
- **Files**: `ToolCalling/*.swift` (CreateTaskTool, etc.)
- **Structure**: Uses `Tool` protocol with `@Generable` and `@Guide` annotations
- **Fragile**: iOS 26+ beta, more easily broken, content filters
- **Usage**: Experimental, requires careful handling
- **Important**: Arguments struct needs `@Generable` AND at least one `@Guide` property (no empty structs)

**🚨 NEVER MIX THE TWO APPROACHES!** Each has its own completely different syntax and architecture.

### Adding New OpenAI Tools (Recommended)
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

2. **Add to allTools array** (`OpenAIService.swift:540+`)
```swift
.init(function: newToolDefinition)
```

3. **Add argument structure** (`OpenAIService.swift:250+`)
```swift
struct NewToolArguments: Decodable {
    let param: String
}
```

4. **Implement handler in ChatViewModel** (`ChatViewModel.swift:600+`)
5. **Update system prompt** if needed (`ChatViewModel.swift:140+`)

### Adding Foundation Models Tools (Advanced Only)
**⚠️ Use with extreme caution - Foundation Models are fragile!**

1. **Create tool file** (`ToolCalling/NewTool.swift`)
```swift
@available(iOS 26.0, *)
struct NewTool: Tool {
    let name = "toolName"
    let description = "What this tool does"
    
    @Generable
    struct Arguments {
        @Guide(description: "Parameter description")
        let param: String
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        // Implementation
        return ToolOutput("Result")
    }
}
```

2. **Register in ToolCollection** (`ToolCalling/ToolCollection.swift`)

### Tool Design Principles
- **Specific over generic** - Better to have many focused tools than few complex ones
- **Clear parameter validation** - Always validate and provide helpful error messages
- **Async-friendly** - Use proper async/await patterns for UI responsiveness
- **ADHD-optimized** - Minimize cognitive load in tool interactions
- **Path consistency** - Never mix OpenAI and Foundation Models patterns

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

## iOS 26 Liquid Glass Implementation

### Overview
Bryan's Brain features comprehensive iOS 26 Liquid Glass integration, providing a modern translucent UI that allows background content to show through interface elements.

### Key Components
- **Chat Interface** (`ChatView.swift`): Ultra-thin material bubbles with floating input area
- **Extensions** (`iOS26Extensions.swift`): Reusable glass effect helpers
- **Experimental** (`iOS26TrueGlassExtensions.swift`): Advanced transparency techniques

### Implementation Details
```swift
// Safe glass effect application
if #available(iOS 26.0, *) {
    self.background(.ultraThinMaterial, in: shape)
        .glassEffect(in: shape)
} else {
    self.background(.thinMaterial, in: shape)
}
```

### Platform Limitations (Important!)
Apple reserves the most advanced liquid glass effects for their own apps through private APIs:
- **Private Methods**: `set_variant`, `set_scrimState`, `set_subduedState`
- **Public Access**: Limited to tint color and corner radius customization
- **Result**: Third-party apps cannot achieve Apple Music's "true floating" effect

### Best Practices
- Use `ultraThinMaterial` for maximum transparency
- Apply `.glassEffect()` modifier where available
- Implement graceful fallbacks for older iOS versions
- Accept platform limitations - don't attempt to use private APIs

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

## Recent Major Updates (June 2025)

### 🖼️ Image Upload Feature (`ChatView.swift` + `ImagePicker.swift`)
- **PHPickerViewController Integration**: Native iOS photo selection with SwiftUI wrapper
- **Vision API Support**: OpenAI GPT-4o with image analysis capabilities  
- **Base64 Encoding**: Efficient image compression and transmission
- **UI Integration**: Camera button with image preview area above text input
- **MessageContent System**: Enhanced chat messages supporting mixed text/image content

### 🤖 AI Agent Mode (`AIAgentManager.swift`)
- **Background Task Refinement**: iOS BackgroundTasks framework for autonomous processing
- **ADHD Time-Blocking Coach**: Comprehensive task analysis with cognitive load assessment
- **Metadata Enrichment**: Automatic duration estimates, difficulty ratings, and categorization
- **Energy Management**: Scheduling recommendations based on context switching costs
- **Productivity Insights**: JSON-structured analysis with time-blocking strategies

### 🎨 Enhanced To-Do List UI (`ContentView.swift`)
- **Separate Sections**: Clear visual separation of incomplete vs completed tasks
- **CompactTaskRowView**: Minimal display for completed items to reduce visual clutter  
- **MetadataCardView**: Card-based expandable metadata with 2x2 grid layout
- **Improved Text Handling**: Better truncation and overflow management
- **Time Estimation Display**: Total time calculations for incomplete task planning
- **Collapsible Completed**: Animated show/hide for completed tasks section

### 🔧 Project Management Improvements
- **Clean Picker Interface**: Removed cramped plus button from project selector
- **Hidden Add Functionality**: "Add New Project" integrated into picker dropdown menu
- **Better Space Usage**: Full-width project text display with elegant truncation
- **Smooth Interactions**: Automatic alert triggering for new project creation