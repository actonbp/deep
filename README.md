# Bryan's Brain (deep_app)

## 🚦 Development Status
- **Current Branch**: `feature/image-upload` ✅ **Major improvements just pushed** (June 29, 2025)
- **Stable Branch**: `main` (warning-free, production-ready)  
- **Latest Commit**: `8ef7e9f` - Major UI/UX improvements and AI Agent Mode
- **Previous**: `edb7e1f` - ChatGPT-style image upload feature
- **📖 Branch Guide**: See [BRANCH_GUIDE.md](BRANCH_GUIDE.md) for detailed git workflow

An iOS app integrating an AI chat assistant (powered by OpenAI's `gpt-4o`, `gpt-4o-mini`, and `o3` models) with a functional to-do list and Google Calendar integration. The core motivation is to provide a **fluid, conversational interface for task management and planning**, specifically designed to reduce friction for users with ADHD.

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
*   **Tabbed Interface:** Separate views for Chat, To-Do List, Calendar, Scratchpad, and Roadmap.
*   **AI Chat:**
    *   Connects to OpenAI models: `o3` (thinking model), `gpt-4o` (main), `gpt-4o-mini` (cost-effective).
    *   🖼️ **NEW: Image Upload** - ChatGPT-style multimodal AI with photo analysis
    *   🤖 **NEW: AI Agent Mode** - Background task processing and ADHD time-blocking insights
    *   Conversation starter prompts.
    *   Optional on-device Foundation Models (iOS 26+ beta).
*   **To-Do List:**
    *   🎨 **NEW: Enhanced UI** - Separate incomplete/completed sections with compact design
    *   📝 **NEW: Metadata Cards** - Elegant expandable task view with card-based layout
    *   ⏱️ **NEW: Time Estimates** - Total time calculations for incomplete tasks
    *   Add, toggle completion, delete, prioritize, drag-reorder items.
    *   Display estimated task durations.
    *   Expandable task metadata (category, project/path, difficulty).
    *   Persisted locally and **synced across devices via CloudKit**.
*   **CloudKit Sync (New!):**
    *   Automatic sync of all tasks across iPhone, iPad, and Mac.
    *   Syncs task content, completion status, priorities, and metadata.
    *   Supports add, update, and delete operations.
    *   **Auto-sync on app lifecycle** - syncs when entering foreground/background.
    *   **Visual sync status indicators** - see sync status in real-time.
    *   **Manual refresh button** - force sync when needed.
    *   **Smart error handling** - handles duplicate saves gracefully.
    *   Requires iCloud account and internet connection.
*   **Google Calendar Integration:**
    *   Secure Google Sign-In authentication.
    *   View today's calendar events in a dedicated tab.
*   **🎮 Gamified Roadmap View:**
    *   Interactive "quest map" visualization with project islands.
    *   Tasks displayed as quest dots with progress rings around islands.
    *   Level system (Lv 1-5) based on project complexity.
    *   XP system (10 points per completed task).
    *   Achievement badges for major milestones.
    *   Zoom/pan controls for exploration.
    *   Beautiful sky gradient background with connecting bridges.
*   **Notes/Scratchpad:**
    *   Quick capture for ideas and notes.
    *   Local persistence.
*   **Agentic AI Capabilities:**
    *   Uses tools (`addTaskToList`, `listCurrentTasks`, `removeTaskFromList`, `updateTaskPriorities`, `updateTaskEstimatedDuration`, `createCalendarEvent`) triggered by conversation.
    *   AI can estimate task durations and difficulty levels.
    *   AI can assist with time blocking suggestions (asking user for calendar constraints).
    *   AI can create events in the user's primary Google Calendar upon request.
    *   AI can mark tasks as complete.
*   **Secure API Key Handling (Debug):** Uses `Secrets.plist`.

## 🎉 Recent Major Updates (June 29, 2025)

### 🖼️ ChatGPT-Style Image Upload
- **Native Photo Selection**: PHPickerViewController integration with SwiftUI wrapper
- **Vision AI Analysis**: OpenAI GPT-4o processes images with text for comprehensive understanding
- **Seamless UI**: Camera button with image preview area, just like ChatGPT
- **Mixed Content**: Chat messages support both text and images simultaneously

### 🤖 AI Agent Mode - Your ADHD Time-Blocking Coach
- **Background Processing**: Runs autonomously using iOS BackgroundTasks framework
- **ADHD-Focused Analysis**: Comprehensive task analysis with cognitive load assessment
- **Smart Metadata**: Automatic duration estimates, difficulty ratings, and categorization
- **Energy Management**: Scheduling recommendations based on context switching costs
- **Productivity Insights**: Detailed time-blocking strategies and quick wins identification

### 🎨 Redesigned To-Do List Interface
- **Visual Clarity**: Clean separation of incomplete vs completed tasks
- **Compact Completed Items**: Minimal display to focus on what needs to be done
- **Metadata Cards**: Beautiful 2x2 grid layout for task details (category, project, difficulty, date)
- **Better Text Handling**: Smart truncation and improved overflow management
- **Time Awareness**: Total time estimates help with daily planning
- **Collapsible Sections**: Animated show/hide for completed tasks

### 🔧 Enhanced Project Management
- **Streamlined Interface**: Removed cramped buttons for cleaner project selection
- **Hidden Functionality**: "Add New Project" seamlessly integrated into picker menu
- **Full-Width Display**: Better space usage with elegant text truncation
- **Smooth Interactions**: Automatic workflows for creating new projects

## 🚀 Future: Free On-Device AI (Coming 2025)

**Bryan's Brain is planning to transition from OpenAI to Apple's Foundation Models**, enabling:

- **💸 FREE AI Chat** - No API costs, everything runs on-device
- **🔒 Complete Privacy** - Your data never leaves your device
- **✈️ Offline Support** - Works without internet connection
- **⚡ Instant Responses** - No network latency
- **🎯 ADHD-Optimized** - Fast, friction-free interaction

This means Bryan's Brain could be offered **completely free on the App Store**, removing all barriers for ADHD users to access AI-powered task management assistance.

**Timeline:** Developer access begins June 2025, with general release expected Fall 2025.

Learn more: https://developer.apple.com/documentation/foundationmodels

### 📅 June 11, 2025 Update: Local Model Integration Progress

**✅ Successfully Implemented:**
- **Settings Toggle** - Users can switch between OpenAI and on-device Foundation Models
- **Basic Chat Functionality** - Text conversations work perfectly with the local model
- **Task Creation** - "Add task: [description]" works reliably
- **Privacy-First Architecture** - All processing happens on-device when local model is enabled
- **Graceful Fallbacks** - App automatically handles unavailable models with clear user guidance
- **Tool Calling Infrastructure** - 22 tools implemented and ready for full functionality

**🚧 Known Issues (iOS 26 Beta):**
- **Tool Response Recognition Bug** - The local model can call tools but doesn't properly interpret responses that return data
  - ✅ Creating tasks works (e.g., "Add task: Buy groceries")
  - ❌ Retrieving tasks fails (e.g., "Show my tasks" - model says it can't see them)
  - This is a Foundation Models framework beta issue, not our implementation
- **IPC Crashes** - Occasional crashes when using complex tool sets (workaround: progressive tool degradation)
- **Content Filter False Positives** - Some prompts trigger safety filters unnecessarily (workaround: simplified prompts)

**🔧 Technical Implementation:**
- `AppleFoundationService` mirrors `OpenAIService` API for seamless switching
- Tools use Apple's `Tool` protocol with `@Generable` structs
- Progressive degradation: All tools → Essential tools → Text-only mode
- Comprehensive error handling and retry logic

**📊 Current Status:**
- Basic conversational AI: **WORKING** ✅
- Task creation: **WORKING** ✅
- Task retrieval/viewing: **BETA BUG** ❌
- Calendar integration: **BETA BUG** ❌
- Scratchpad operations: **BETA BUG** ❌

**🎯 Recommendation for Users:**
- For full functionality: Keep using OpenAI (Settings → disable "Use On-Device Model")
- For testing/basic chat: Try the local model (it's free and private!)
- Check back after iOS 26 stable release for full tool support

## Planned Features / Roadmap

*   **Enhanced CloudKit Sync:**
    *   Real-time sync without app restart.
    *   Notes/Scratchpad sync.
    *   Conflict resolution for simultaneous edits.
*   **Calendar Creation Enhancement:** Allow AI to create events based on time blocking suggestions.
*   **UI/UX:** Improve Dark Mode support, general UI polish.
*   **Task Metadata:** Add Deep/Shallow work categorization.
*   **AI Enhancement:** Refine prompts, explore multi-agent concepts more deeply.
*   **Release Build Security:** Secure API key handling for release.
*   **macOS Companion App:** Explore creating a companion app for macOS leveraging the shared SwiftUI codebase (lower priority currently).

See `future_directions.md` for complete roadmap and planned features.

## Solo Entrepreneur Philosophy

**Build for yourself first, then find others like you.**

Bryan's Brain is being developed with a clear philosophy:

1. **Personal Utility First**: The app must be incredibly useful to me (Bryan) as someone with ADHD/executive function challenges
2. **Daily Driver**: I use this app every day, ensuring rapid iteration based on real needs
3. **No Premature Scaling**: Won't release to App Store until it's genuinely transformative for my own productivity
4. **Find Your Tribe**: Once perfected for my needs, find other ADHD users who share similar challenges

This approach ensures:
- Deep understanding of the problem space
- Authentic solutions that actually work
- No feature bloat from imagined user needs
- Passionate development driven by personal necessity

## Vercel Backend Architecture (Coming Soon)

### Moving Beyond Personal API Credits

The next major technical evolution will implement a Vercel serverless backend:

**Architecture:**
```
iPhone App → Vercel Functions → OpenAI API
           ↓
    Auth & Rate Limiting
```

**Benefits:**
- **Scalable**: Serverless functions scale automatically
- **Secure**: API keys stored server-side
- **Cost-Effective**: Pay-per-request pricing
- **User Management**: Authentication and premium tiers
- **Rate Limiting**: Control costs per user

**Implementation Plan:**
1. JWT authentication system
2. User accounts with usage tracking
3. Free tier (Foundation Models) + Premium tier (OpenAI)
4. Stripe integration for premium subscriptions
5. Usage analytics and monitoring

## AI-Powered Marketing Strategy

### Leveraging AI for Solo Marketing

As a solo entrepreneur, all marketing will be AI-augmented:

**Content Creation:**
- **Google VEO3**: Creating high-quality product demo videos
- **AI Copywriting**: Social media posts optimized for ADHD community
- **Automated Scheduling**: AI-driven content calendar

**Channels:**
- Twitter/X: Daily tips for ADHD productivity
- TikTok/Reels: Short demos showing "aha" moments
- YouTube: Longer tutorials and ADHD life hacks
- Reddit: Authentic engagement in ADHD communities

**Key Messages:**
- "Built by someone with ADHD, for people with ADHD"
- "Your AI coach that actually gets it"
- "Stop fighting your brain, start working with it"

**Metrics:**
- Track which features resonate most
- A/B test messaging with AI assistance
- Focus on engagement over vanity metrics

## ⚠️ CRITICAL: Repository Recovery Warning

**Before performing ANY git reset, checkout, or major recovery operations:**

1. **Read `.cursor/rules/feature_verification.mdc`** - Contains comprehensive checklist
2. **Create a backup**: `git stash push -m "Safety backup"`
3. **Never trust file presence alone** - Features can be missing even when files exist
4. **Always verify the expandable task metadata feature** - It's been lost before!

See `.cursor/rules/feature_verification.mdc` for the complete verification protocol.

## Development

*   Language: Swift
*   UI Framework: SwiftUI
*   Platform: iOS
*   IDE: Xcode 

## Apple Developer Program Membership

This project requires an **Apple Developer Program membership** ($99/year) for full functionality:

### Benefits Utilized:
- ✅ **CloudKit** - Cross-device task synchronization
- ✅ **Increased Memory Limits** - Better performance for AI operations
- ✅ **Push Notifications** (capability enabled for future real-time sync)
- ✅ **TestFlight** - Beta testing distribution (when ready)
- ✅ **App Store Distribution** - Public release capability

### Setup Requirements:
1. Active Apple Developer Program membership
2. Xcode configured with paid developer team (not Personal Team)
3. Valid provisioning profiles for CloudKit capabilities
4. iCloud account on test devices

See `deep_app/DEVELOPER_ACCOUNT_SETUP.md` for detailed configuration instructions. 