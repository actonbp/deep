# Bryan's Brain (deep) 🧠

An ADHD-focused productivity iOS app that combines conversational AI with task management, calendar integration, and visual roadmapping.

## Current Status (July 2025) ✨

### Recent Updates

#### July 22, 2025 - iOS 26 Beta 4 Integration
- **iOS 26 Beta 4 Support**: JSON Schema integration for @Generable models enabling cross-LLM compatibility
- **Enhanced Liquid Glass UI**: Improved transparency with ultraThinMaterial and better visibility
- **Chat Interface Polish**: Bryan's Brain title now uses accent color for better readability
- **Platform API Discovery**: Documented Apple's private liquid glass APIs and public limitations
- **Stable Architecture**: Fully functional with OpenAI, Apple Foundation Models, and multimodal support

#### June 30, 2025 - Major UI/UX Enhancements
- **ChatGPT-Style Image Upload**: Full multimodal AI with photo analysis capability
- **AI Agent Mode**: Background task refinement with ADHD time-blocking insights
- **Enhanced To-Do UI**: Compact metadata cards with improved visual hierarchy
- **Quest Map**: Working chronological task progression for projects
- **Performance**: Fixed type-checking timeouts and rendering issues

### Core Features
- 🤖 **Conversational AI Assistant** - Natural language task management with 22+ tool functions
- 📝 **Smart To-Do List** - Expandable metadata, priority management, drag-to-reorder
- 📅 **Calendar Integration** - Google Calendar sync with natural language scheduling
- 🗺️ **Visual Roadmap** - Quest-style visualization of tasks and projects
- ☁️ **CloudKit Sync** - Seamless cross-device synchronization
- 🧠 **Local AI Option** - Toggle between OpenAI and on-device Foundation Models

## Tech Stack

- **iOS 17+** (iOS 26 for local models)
- **SwiftUI** with modern glass effects
- **OpenAI GPT-4o-mini** (primary)
- **Apple Foundation Models** (beta)
- **Google Calendar API**
- **CloudKit**

## Key Features in Detail

### AI-Powered Task Management
- Create tasks: "Add task: prepare presentation for Monday"
- Update metadata: "Set the presentation task to high priority"
- Schedule events: "Schedule a meeting tomorrow at 2pm"
- Get organized: "What should I focus on today?"

### Visual Design
- Modern iOS 26 glass morphism effects
- Dark blue (#142B8B) accent color optimized for ADHD focus
- Subtle transparency and shimmer effects
- Clean, distraction-free interface

### ADHD-Optimized Features
- Quick capture for wandering thoughts
- Visual progress tracking
- Time estimates and difficulty ratings
- "Getting unstuck" prompts
- Gentle gamification elements

## Project Structure

```
deep/
├── deep_app/           # iOS app source
│   ├── ChatView.swift  # AI chat interface with glass effects
│   ├── ContentView.swift # Main tab view & task list
│   ├── TodoListStore.swift # Task state management
│   ├── OpenAIService.swift # AI integration
│   └── ...
├── archive/            # Backend experiments
└── README.md          # You are here!
```

## Getting Started

1. Clone the repository
2. Open `deep_app/deep_app.xcodeproj` in Xcode
3. Add your OpenAI API key to `Secrets.plist`:
   ```xml
   <key>OPENAI_API_KEY</key>
   <string>your-key-here</string>
   ```
4. Build and run on iOS 17+ device/simulator

## Recent Improvements (December 2024)

- ✅ Implemented iOS 26 glass effects throughout the app
- ✅ Enhanced chat bubble design with better contrast
- ✅ Added drag-to-reorder for tasks with visual feedback
- ✅ Fixed all ContentView structural issues
- ✅ Improved error handling and stability

## Roadmap

### Phase 1: Polish Current Features
- [ ] Complete iOS 26 glass effect implementation
- [ ] Enhance animation fluidity
- [ ] Optimize performance

### Phase 2: Enhanced AI
- [ ] Multi-step task breakdowns
- [ ] Proactive suggestions
- [ ] Context-aware reminders

### Phase 3: Gamification
- [ ] XP and level system
- [ ] Achievement badges
- [ ] Streak tracking

### Phase 4: Advanced Features
- [ ] Voice input/output
- [ ] Widget support
- [ ] Apple Watch app

## Known Issues

- Local Foundation Models (iOS 26 beta) have limited tool response capabilities
- Some glass effects may appear different on older iOS versions

## Contributing

This is a personal project, but feedback and suggestions are welcome! Feel free to open issues or reach out.

## License

Copyright © 2024 Bryan Acton. All rights reserved.

---

*Built with ❤️ for the ADHD community* 
## July 9th, 2025 Updates 🎨

### UI/UX Improvements
- **Enhanced Chat Interface**: Implemented subtle iOS 26 glass effects with carefully balanced transparency
- **Improved Color Contrast**: Changed accent color from light blue to dark blue (#142B8B) for better readability
- **Task Reordering**: Added drag-to-reorder functionality with visual drag handles
- **Glass Effects**: Added modern glass morphism to task rows with priority-based tinting
- **Visual Polish**: Refined shadows, borders, and transparency levels throughout the app

### Technical Improvements
- Fixed ContentView structural issues with proper Swift organization
- Resolved all Xcode compilation errors
- Improved error handling and stability
- Enhanced CloudKit sync reliability

### Design Philosophy
- Balanced modern iOS aesthetics with ADHD-friendly clarity
- Maintained high contrast for better focus
- Subtle effects that enhance without distracting
- Consistent visual language across all views

These updates represent a significant step toward a more polished, professional app while maintaining the core ADHD-focused functionality.
