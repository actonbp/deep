# Project To-Do List for Deep Work App

This file tracks the planned features and improvements for the AI-powered deep work assistant app.

## Core Functionality
- [x] Basic To-Do List UI (Add, View, Delete)
- [x] Persistence (Items saved between launches)

## Future Enhancements

### AI Integration
- [ ] Chat-based interface
- [ ] Natural Language Processing (NLP) to identify tasks from chat input (using commands currently)
- [ ] Explore OpenAI Function Calling for smarter task extraction
- [ ] AI-powered task prioritization suggestions
- [ ] AI assistance in breaking down large tasks
- [ ] Explore on-device model (Core ML) integration

### Focus & Productivity Features
- [ ] Integration with Deep Work principles (e.g., timers, focus sessions)
- [ ] Minimalist UI/UX design refinement
- [ ] Task categorization/tagging

### Integrations
- [ ] Google Calendar integration (View events, potentially add tasks as events)
- [ ] Other potential integrations (e.g., email, notes apps)

### Technical Improvements
- [ ] Refactor persistence (Consider Core Data or SwiftData for more complex data)
- [ ] Error handling and robustness
- [ ] Unit and UI tests 

## Performance & Responsiveness

*   **Optimize List Sorting:** Move sorting logic from `TodoListView` into `TodoListStore` to avoid repeated sorting during view updates. Publish a pre-sorted array from the store.
*   **Asynchronous Initial Load:** Refactor `TodoListStore.loadItems()` to run asynchronously in the background to prevent potential main thread blocking during app startup.
*   **Asynchronous Saving:** Implemented (using Task.detached).

## Other Potential Tasks (from previous discussions)

*   Implement secure API key handling for Release builds.
*   Address warning regarding required interface orientations.
*   Resolve `Codable` warning related to `TodoItem.id` (if still present and causing issues).
*   Refine AI prompting further (e.g., error handling, more complex scenarios, task breakdown implementation).
*   Explore adding explicit Date/Time handling for tasks/reminders.
*   UI/UX improvements for Chat and To-Do views.

## Google Calendar Integration (Future Goal)

Integrate with Google Calendar to allow the AI to schedule tasks as events.

**Phase 1: Authentication & Setup**
- [ ] Configure Google Cloud Project (Enable Calendar API, Create OAuth iOS Client ID, Configure Consent Screen).
- [ ] Add `GoogleSignIn-iOS` SDK via Swift Package Manager.
- [ ] Implement "Sign in with Google" button/flow in `SettingsView` using the SDK.
- [ ] Implement secure storage for OAuth tokens using iOS Keychain.
- [ ] Add UI in `SettingsView` to show signed-in status and provide a Sign Out option.

**Phase 2: Basic Calendar Interaction**
- [ ] Create `GoogleCalendarService.swift` class.
- [ ] Implement logic to retrieve/refresh OAuth tokens from Keychain.
- [ ] Implement basic API call function (e.g., `listCalendars`) using `URLSession` and authenticated requests.
- [ ] Implement core function `addEventToCalendar(...)` to create events via the Calendar API.

**Phase 3: AI Integration**
- [ ] Define new AI tool spec (`scheduleTaskOnCalendar`) in `OpenAIService` with parameters (description, date, time, duration).
- [ ] Add the tool to `allTools` list in `OpenAIService`.
- [ ] Add handler in `ChatViewModel` for the new tool call, parsing arguments and calling `GoogleCalendarService.addEventToCalendar`.
- [ ] Update system prompt to instruct AI on using the `scheduleTaskOnCalendar` tool. 