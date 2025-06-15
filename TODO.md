# Project To-Do List for Deep Work App

This file tracks the planned features and improvements for the AI-powered deep work assistant app.

## ✅ Recently Completed (2025)

### CloudKit Sync Implementation
- [x] Enable CloudKit capability in Xcode project
- [x] Configure CloudKit container and entitlements
- [x] Implement CloudKitManager for sync operations
- [x] Full CRUD sync for TodoItems
- [x] Sync all task metadata (category, project, priority, etc.)
- [x] Handle offline/online states gracefully
- [x] Merge logic for initial sync from multiple devices
- [x] Auto-sync on app lifecycle (foreground/background)
- [x] Visual sync status indicators with tap for details
- [x] Manual refresh button in toolbar
- [x] Smart duplicate handling (no false errors)
- [x] Automatic schema creation on first run

### Core Functionality
- [x] Basic To-Do List UI (Add, View, Delete)
- [x] Persistence (Items saved between launches)
- [x] Expandable task metadata UI (click to edit category/project)
- [x] 5-tab structure (Chat, To-Do, Calendar, Scratchpad, Roadmap)
- [x] 🎮 **Gamified Roadmap Implementation** - Complete visual overhaul
- [x] Demo mode for testing without affecting real data

### 🎮 Gamified Roadmap (December 2024)
- [x] Project islands with floating design and gradients
- [x] Quest dots showing tasks as small circles (green when complete)
- [x] Progress rings around each island showing completion percentage
- [x] Level system (Lv 1-5) based on project task count
- [x] XP system awarding 10 points per completed task
- [x] Achievement badges (gold stars) for major milestones
- [x] Curved bridges connecting related projects
- [x] Sky gradient background (cyan to blue)
- [x] Zoom/pan controls with reset button
- [x] Project type system (Work 💼, Personal 🚀, Health 💚, Learning 📚)
- [x] Color system integration with Assets.xcassets

### AI Integration (Partial)
- [x] Chat-based interface with OpenAI
- [x] Tool-based task management (13+ tools)
- [x] Natural language task addition via tools
- [x] AI-powered task prioritization
- [x] "Getting unstuck" guidance for ADHD users
- [x] Task completion via AI command

## 📅 June 11, 2025 Update: Apple Foundation Models Integration

### ✅ Successfully Implemented
- [x] **Settings Toggle** - Switch between OpenAI and local Foundation Models
- [x] **AppleFoundationService** - Complete service implementation mirroring OpenAI API
- [x] **Basic Chat** - Text conversations work perfectly with local model
- [x] **Task Creation Tool** - "Add task: [description]" works reliably
- [x] **Tool Protocol Implementation** - 22 tools using Apple's `Tool` protocol
- [x] **@Generable Structs** - All tool arguments properly annotated
- [x] **Availability Checks** - Graceful handling of model unavailability
- [x] **Error Handling** - Comprehensive retry logic and user-friendly messages
- [x] **Progressive Degradation** - All tools → Essential tools → Text-only fallback
- [x] **Debug Infrastructure** - Logging and diagnostic tools

### 🚧 Known Issues (iOS 26 Beta Bugs)
- [ ] **Tool Response Recognition** - Model doesn't interpret tool responses that return data
  - Creating tasks (addTaskToList) ✅ WORKS
  - Retrieving tasks (listCurrentTasks) ❌ FAILS
  - Calendar queries ❌ FAILS
  - Scratchpad operations ❌ FAILS
- [ ] **IPC Crashes** - "Underlying connection interrupted" with complex tool sets
- [ ] **Content Filter Issues** - False positives on ADHD/mental health terminology
- [ ] **Session Cancellation** - "Attempting to send message using a canceled session"

### 🔧 Technical Workarounds Implemented
- [x] Retry logic with exponential backoff
- [x] Session prewarming
- [x] Timeout handling (30 seconds)
- [x] Content filter workarounds (simplified prompts)
- [x] Tool set reduction on failure
- [x] Diagnostic tool for testing

### 📊 Next Steps for Local Model
- [ ] Monitor iOS 26 beta releases for framework fixes
- [ ] Test with each new beta/RC version
- [ ] Document any API changes in Foundation Models framework
- [ ] Update tool implementations when Apple provides guidance
- [ ] Consider temporary hardcoded responses for demos
- [ ] Prepare migration path for when bugs are fixed

## 🚧 In Progress / High Priority

### CloudKit Enhancements
- [x] Auto-sync on app lifecycle ✅
- [x] Visual sync status indicators ✅
- [x] Manual refresh button ✅
- [ ] Real-time sync without app restart (push notifications)
- [ ] Notes/Scratchpad CloudKit sync
- [ ] Conflict resolution UI for simultaneous edits
- [ ] Batch sync operations for performance
- [ ] Pull-to-refresh gesture on lists
- [ ] Last sync timestamp display
- [ ] Offline changes queue indicator

### Performance & Responsiveness
- [ ] **Optimize List Sorting:** Move sorting logic from `TodoListView` into `TodoListStore` to avoid repeated sorting during view updates
- [ ] **Asynchronous Initial Load:** Refactor `TodoListStore.loadItems()` to run asynchronously in the background
- [x] **Asynchronous Saving:** Implemented (using Task.detached)

## 📋 Future Enhancements

### 🎓 Onboarding & Tutorial System (High Priority)
The app has grown in complexity and needs a comprehensive tutorial system to help users understand all features:

**Initial Onboarding Flow:**
- [ ] Welcome screen explaining Bryan's Brain philosophy for ADHD users
- [ ] Step-by-step tutorial for basic task creation and management
- [ ] Interactive guide showing expandable task metadata (click tasks to edit)
- [ ] Explanation of project organization and categories
- [ ] Gamified roadmap tutorial (islands, quests, levels, XP, achievements)
- [ ] AI chat introduction with example prompts ("I don't know where to start")
- [ ] Calendar integration setup and benefits
- [ ] CloudKit sync explanation and iCloud account requirements

**Tutorial Features:**
- [ ] Settings option to "Restart Tutorial" for returning users
- [ ] Contextual tips that appear when users first visit each tab
- [ ] Interactive overlay system with arrows pointing to key features
- [ ] "Getting Started" checklist that guides users through first tasks
- [ ] Video-style animated guides for complex features (roadmap navigation)
- [ ] Quick tips that appear based on user behavior patterns

**ADHD-Specific Guidance:**
- [ ] "Feeling Overwhelmed?" mode with simplified interface
- [ ] Tutorial focused on "next small step" philosophy
- [ ] Examples of how to break down large tasks into manageable pieces
- [ ] Demo project showing real-world task organization patterns
- [ ] Explanation of how visual progress (islands) helps with motivation

**Progressive Disclosure:**
- [ ] Basic mode that hides advanced features initially
- [ ] "Power User" mode unlock after completing basic tutorial
- [ ] Feature discovery system that introduces new capabilities gradually
- [ ] Achievement-based unlocking of advanced features

### AI Integration (Advanced)
- [ ] Explore on-device model integration (waiting for Apple's SDK in iOS 19)
- [ ] AI assistance in breaking down large tasks
- [ ] More sophisticated time estimation learning
- [ ] Contextual suggestions based on calendar availability

### Focus & Productivity Features
- [ ] Integration with Deep Work principles (e.g., timers, focus sessions)
- [ ] Time blocking visualization
- [ ] Task categorization as Deep/Shallow work
- [ ] Pomodoro timer integration
- [ ] Focus mode with notification blocking

### Technical Improvements
- [ ] Implement secure API key handling for Release builds (currently DEBUG only)
- [ ] Unit and UI tests for critical paths
- [ ] Accessibility improvements (VoiceOver support)
- [ ] Widget support for quick task addition
- [ ] App Intents for Siri integration

### UI/UX Refinements
**Visual Design System Implementation:**
- [ ] **Apply new color system throughout app** - Currently colors are added but not fully utilized
- [ ] Update task list to use Gray50/Gray600 for better text hierarchy
- [ ] Implement Indigo500 consistently across accent elements
- [ ] Color-coded priority indicators using the new palette
- [ ] Project-type color coding in task list (not just roadmap)
- [ ] Enhanced card designs using the new spacing system
- [ ] Typography improvements using the refined font scales

**Polish & Refinements:**
- [ ] Dark mode polish with proper new color variants
- [ ] Custom app icon options
- [ ] Enhanced haptic feedback for task actions (currently basic)
- [ ] Swipe gesture customization
- [ ] Task templates for recurring items
- [ ] Improved visual feedback for task completion
- [ ] Better contrast and accessibility with new color system
- [ ] Animated transitions between tab views

## 🗓️ Google Calendar Integration (Mostly Complete)

**Phase 1: Authentication & Setup** ✅
- [x] Configure Google Cloud Project
- [x] Add `GoogleSignIn-iOS` SDK
- [x] Implement "Sign in with Google" in app
- [x] Secure token storage using Keychain

**Phase 2: Basic Calendar Interaction** ✅
- [x] Create `CalendarService.swift`
- [x] OAuth token management
- [x] List calendars functionality
- [x] Create/Update/Delete events

**Phase 3: AI Integration** ✅
- [x] Calendar tools in OpenAI service
- [x] AI can create calendar events
- [x] AI can query today's events

**Phase 4: Advanced Features** 🚧
- [ ] Multi-calendar support
- [ ] Recurring event handling
- [ ] Calendar event templates
- [ ] Two-way sync with tasks

## 💻 macOS Companion App (Future - Lower Priority)

- [ ] **Project Setup:** Add macOS target
- [ ] **Code Sharing:** Configure shared files
- [ ] **Authentication:** macOS-compatible Google Sign-In
- [ ] **UI/UX Adaptation:** macOS-specific layouts
- [ ] **Menu Bar:** Quick task addition from menu bar
- [ ] **Keyboard Shortcuts:** Power user features

## ⚠️ Known Issues to Address

- [ ] Address warning regarding required interface orientations
- [ ] Resolve any remaining `Codable` warnings
- [ ] Fix any memory leaks in long chat sessions
- [ ] Improve error messages for user-facing failures

## 🔄 Refactoring Opportunities

- [ ] Consolidate repetitive time parsing logic in calendar tool handlers
- [ ] Extract common UI components into reusable views
- [ ] Create proper view models for all views (some still use direct store access)
- [ ] Implement proper dependency injection

## 📝 Documentation Needs

- [x] CloudKit setup guide ✅
- [ ] User manual for ADHD-specific features
- [ ] Developer onboarding guide
- [ ] API documentation for tool system
- [ ] Troubleshooting guide for common issues

---

*Note: This TODO list preserves all historical items while showing current progress. Items may move between sections as they're completed or reprioritized.* 