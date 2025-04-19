# Bryan's Brain (deep_app)

An iOS app integrating an AI chat assistant (powered by OpenAI's `gpt-4o-mini`) with a functional to-do list. The assistant can understand natural language requests and automatically add tasks to the list using function calling.

## Current Features

*   **iOS Application:** Built natively using SwiftUI.
*   **Tabbed Interface:** Separate views for Chat and To-Do List management.
*   **AI Chat:**
    *   Connects to OpenAI's `gpt-4o-mini` model via the Chat Completions API.
    *   Conversation starter prompts provide usage examples.
*   **To-Do List:**
    *   Add, toggle completion status, and delete tasks.
    *   Data is persisted locally using `UserDefaults`.
*   **AI-Powered Task Management:**
    *   Function calling (`addTaskToList`) allows the AI assistant to automatically add tasks derived from the chat conversation.
    *   Proactive task adding: AI is prompted to add tasks immediately rather than asking excessive clarifying questions.
    *   Confirmation: AI confirms task additions in the chat after successful tool execution.
*   **Secure API Key Handling (Debug):** Uses `Secrets.plist` for the OpenAI API key during debug builds, correctly excluded from Git via `.gitignore`.

## Planned Features / Roadmap

*   **Release Build API Key Security:** Implement a secure method for providing the API key in release builds (e.g., server fetch, build configurations).
*   **AI Enhancement:**
    *   Refine system prompts for improved task understanding, error handling, and conversational flow.
    *   Explore additional tool functions (e.g., re-prioritizing tasks, summarizing lists, brainstorming).
*   **UI/UX Improvements:** Enhance the visual design and user experience of both chat and to-do list views.
*   **Platform:**
    *   Address warning regarding required interface orientations.
    *   Investigate and resolve any remaining build warnings (e.g., `Codable` warning on `TodoItem.id` if applicable).
*   **Exploration:** Potentially evaluate other AI models (like `gpt-4o`) or migrate to the OpenAI Assistants API for different state management capabilities.

## Vision: Your Conversational Productivity Partner

**Bryan's Brain** is conceived as a **real-time, conversational ADHD productivity assistant**. It's designed to be an ambient support system that listens, logs, prioritizes, and plans *with* you, eliminating the friction of context switching and complex interfaces.

The core idea is a **chat-first experience** where task management is seamlessly integrated into an ongoing conversation with an AI assistant.

## Core Philosophy

*   **Chat-First UX:** Your primary interaction is conversing with the AI assistant.
*   **Frictionless Capture:** Simply tell the AI what's on your mind (tasks, ideas, reminders), and it handles the logging and organizing.
*   **Always-There Assistant:** Like texting your most supportive and organized colleague.
*   **ADHD-Aware:** Designed to help you stay on track without judgment, offering gentle guidance and encouragement.
*   **Minimal & Powerful:** Simple interface, but deeply capable through AI integration.

## Core Components

1.  **AI Chat Assistant (Main Interface):** Your thinking partner and task butler. Handles requests like adding tasks, planning your day, breaking down goals, and finding focus.
2.  **Smart To-Do List (Assistant-Driven):** A live, structured task list populated and updated *by* the AI based on your conversation. Tasks can potentially be tagged, prioritized, and marked with context.

## Current State

The app is in the very early stages. It currently includes:

*   A basic SwiftUI view for a to-do list (add, delete, mark done).
*   Persistence for the list items.
*   This README and a `TODO.md` tracking future goals.

## Next Steps & Future Goals

*   Implement the `TabView` structure (Chat / List).
*   Build the basic Chat UI.
*   Integrate with an AI API (like OpenAI's GPT) for the chat assistant.
*   Develop the logic for the AI to parse commands and update the list.
*   Refine the task data model (tags, priorities, etc.).
*   Potential Google Calendar integration.
*   Explore notification reminders and cross-device sync.

See `TODO.md` for more details.

## Development

*   Language: Swift
*   UI Framework: SwiftUI
*   Platform: iOS
*   IDE: Xcode (with VS Code for editing) 