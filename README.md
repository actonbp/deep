# Bryan's Brain (iOS App)

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