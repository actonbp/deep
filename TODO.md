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
- [x] Roadmap view with category/project organization
- [x] Demo mode for testing without affecting real data

### AI Integration (Partial)
- [x] Chat-based interface with OpenAI
- [x] Tool-based task management (13+ tools)
- [x] Natural language task addition via tools
- [x] AI-powered task prioritization
- [x] "Getting unstuck" guidance for ADHD users
- [x] Task completion via AI command

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
- [ ] Dark mode polish
- [ ] Custom app icon options
- [ ] Haptic feedback for task actions
- [ ] Swipe gesture customization
- [ ] Task templates for recurring items

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