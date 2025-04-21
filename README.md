# Bryan's Brain (deep_app)

An iOS app integrating an AI chat assistant (powered by OpenAI's `gpt-4o-mini`) with a functional to-do list and Google Calendar integration. The core motivation is to provide a **fluid, conversational interface for task management and planning**, specifically designed to reduce friction for users with ADHD.

## Core Concept: Conversational & Agentic Productivity

The app goes beyond a simple chatbot. It leverages an **agentic AI architecture** where the AI assistant can:

1.  **Understand** user requests in natural language.
2.  **Reason** about the user's goals and the current context (tasks, conversation history).
3.  **Plan** sequences of actions.
4.  **Utilize Tools** autonomously (via OpenAI function calling / tool use) to interact with the app's features, such as:
    *   Managing the To-Do List (`addTaskToList`, `listCurrentTasks`, `updateTaskPriorities`, etc.)
    *   Managing Calendar Events (`createCalendarEvent`, reading events)
    *   Updating Task Metadata (`updateTaskEstimatedDuration`)

This allows for a seamless experience where task capture, planning, and calendar integration happen within a single conversational flow.

**Future Vision: Multi-Agent Collaboration:** The ultimate goal is to evolve towards a system potentially involving multiple specialized AI agents working in parallel. These agents could proactively analyze the chat, to-do list, and calendar to offer suggestions, identify conflicts, assist with time blocking (aligning with methodologies like Cal Newport's), and maintain alignment across the user's productivity landscape.

## Benefits for ADHD

*   **Low-Friction Capture:** Simply talking or typing to the AI assistant removes the barrier of opening specific apps, navigating menus, and manually entering task details.
*   **Reduced Cognitive Load:** The AI handles organizing, prioritizing (with guidance), and potentially scheduling tasks, freeing up mental energy.
*   **Externalized Structure:** Time blocking suggestions and calendar integration provide the external structure that can be highly beneficial for managing time blindness and transitions.
*   **Action-Oriented:** The AI is designed to gently guide towards the next actionable step.

## Current Features

*   **iOS Application:** Built natively using SwiftUI.
*   **Tabbed Interface:** Separate views for Chat, To-Do List, and Today's Calendar.
*   **AI Chat:**
    *   Connects to OpenAI's `gpt-4o-mini` model.
    *   Conversation starter prompts.
*   **To-Do List:**
    *   Add, toggle completion, delete, prioritize, drag-reorder items.
    *   Display estimated task durations.
    *   Persisted locally.
*   **Google Calendar Integration:**
    *   Secure Google Sign-In authentication.
    *   View today's calendar events in a dedicated tab.
*   **Agentic AI Capabilities:**
    *   Uses tools (`addTaskToList`, `listCurrentTasks`, `removeTaskFromList`, `updateTaskPriorities`, `updateTaskEstimatedDuration`, `createCalendarEvent`) triggered by conversation.
    *   AI can estimate task durations.
    *   AI can assist with time blocking suggestions (asking user for calendar constraints).
    *   AI can create events in the user's primary Google Calendar upon request.
*   **Secure API Key Handling (Debug):** Uses `Secrets.plist`.

## Planned Features / Roadmap

*   **Calendar Creation Enhancement:** Allow AI to create events based on time blocking suggestions.
*   **UI/UX:** Improve Dark Mode support, general UI polish.
*   **Task Metadata:** Add Deep/Shallow work categorization.
*   **AI Enhancement:** Refine prompts, explore multi-agent concepts more deeply.
*   **Release Build Security:** Secure API key handling for release.

See `TODO.md` for more granular items.

## Development

*   Language: Swift
*   UI Framework: SwiftUI
*   Platform: iOS
*   IDE: Xcode 