//
//  ContentView.swift
//  deep_app
//
//  Created by bacton on 4/15/25.
//

import SwiftUI
import AVFoundation // <-- Import AVFoundation for audio

// MARK: - iOS 26 UI Extensions
extension View {
    /// Conditionally applies iOS 26 tab bar styling
    @ViewBuilder
    func conditionalTabBarStyle() -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26: Liquid Glass tab bar
            self.background(.clear)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(.thinMaterial, for: .tabBar)
        } else {
            // Pre-iOS 26: Ultra thin material
            self.background(.ultraThinMaterial)
        }
    }
    
    /// iOS 26 glass input field style
    @ViewBuilder
    func glassInputStyle() -> some View {
        if #available(iOS 26.0, *) {
            self
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12)) // More transparent
                .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        } else {
            self
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12)) // More transparent fallback
        }
    }
    
    /// iOS 26 glass button style
    @ViewBuilder
    func glassButtonStyle(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if prominent {
                            RoundedRectangle(cornerRadius: 12).fill(.tint)
                        } else {
                            RoundedRectangle(cornerRadius: 12).fill(.thinMaterial)
                        }
                    }
                )
                .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(prominent ? .white : .primary)
        } else {
            self
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if prominent {
                            RoundedRectangle(cornerRadius: 12).fill(.tint)
                        } else {
                            RoundedRectangle(cornerRadius: 12).fill(.regularMaterial)
                        }
                    }
                )
                .foregroundStyle(prominent ? .white : .primary)
        }
    }
    
    /// iOS 26 glass form style
    @ViewBuilder
    func conditionalFormStyle() -> some View {
        if #available(iOS 26.0, *) {
            self
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial)
        } else {
            self
        }
    }
    
    /// Conditionally applies glass effect for iOS 26+, falls back to ultra thin material for older versions
    @ViewBuilder
    func conditionalGlassEffect<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26: Use new glass effect
            self.glassEffect(in: shape)
        } else {
            // Pre-iOS 26: Use ultra thin material as fallback
            self.background(.ultraThinMaterial, in: shape)
        }
    }
    
    /// Conditionally applies glass background for iOS 26+, falls back to more opaque background
    @ViewBuilder
    func conditionalGlassBackground<S: Shape>(_ color: Color, opacity: Double, in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26: Much more transparent for stronger glass effect
            self.background(shape.fill(color.opacity(opacity * 0.3))) // Even more transparent
        } else {
            // Pre-iOS 26: More opaque for better visibility without glass effect
            self.background(shape.fill(color.opacity(opacity * 2)))
        }
    }
    
    /// Ultra-transparent glass effect for maximum see-through
    @ViewBuilder
    func ultraGlassEffect<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self
                .background(.ultraThinMaterial, in: shape)
                .background(Color.white.opacity(0.02), in: shape) // Tiny white tint
                .modifier(SafeGlassEffectModifier(shape: shape))
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }
}

// Safe glass effect modifier to prevent console warnings
@available(iOS 26.0, *)
struct SafeGlassEffectModifier<S: Shape>: ViewModifier {
    let shape: S
    
    func body(content: Content) -> some View {
        // Try to apply glass effect, fall back gracefully if not available
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 {
            content.glassEffect(in: shape)
        } else {
            content
        }
    }
}

// --- ADDED: Difficulty Enum ---
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
}

// --- ADDED: ProjectType Enum for Gamified Roadmap ---
enum ProjectType: String, Codable, CaseIterable, Identifiable {
    case work = "Work"
    case personal = "Personal"
    case health = "Health"
    case learning = "Learning"
    
    var id: String { self.rawValue }
    
    // Icon for each project type
    var icon: String {
        switch self {
        case .work: return "💼"
        case .personal: return "🚀"
        case .health: return "💚"
        case .learning: return "📚"
        }
    }
    
    // Color for each project type
    var colorName: String {
        switch self {
        case .work: return "ProjectBlue"
        case .personal: return "ProjectPurple" 
        case .health: return "ProjectGreen"
        case .learning: return "ProjectYellow"
        }
    }
}
// ------------------------------

// Define the structure for a To-Do item
struct TodoItem: Identifiable, Codable {
    let id: UUID // Use let for stable identifier
    var text: String
    var isDone: Bool // Status flag
    var priority: Int? // Added priority field (optional integer)
    var estimatedDuration: String? // Added estimated duration (optional string)
    var dateCreated: Date
    var difficulty: Difficulty? = nil
    // --- Roadmap Metadata ---
    var category: String? = nil // e.g., "Research", "Teaching", "Life"
    var projectOrPath: String? = nil // e.g., "Paper XYZ", "LEAD 552"
    var shortSummary: String? = nil // e.g., "Call dentist" for "Call dentist to schedule cleaning appointment for next month"
    var projectType: ProjectType? = nil // e.g., .work, .personal, .health, .learning
    // ------------------------
    
    // --- Corrected Custom Init (only assigns properties not already defaulted) ---
    init(id: UUID = UUID(), text: String, isDone: Bool = false, priority: Int? = nil, estimatedDuration: String? = nil, dateCreated: Date = Date(), difficulty: Difficulty? = nil, category: String? = nil, projectOrPath: String? = nil, shortSummary: String? = nil, projectType: ProjectType? = nil) {
        self.id = id // Assign the provided or default ID
        self.text = text
        self.isDone = isDone
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.dateCreated = dateCreated
        self.difficulty = difficulty
        // --- Assign Roadmap Metadata ---
        self.category = category
        self.projectOrPath = projectOrPath
        self.shortSummary = shortSummary
        self.projectType = projectType
        // -----------------------------
    }
    // ------------------------------------------------------------------------
    
    // --- Custom Codable Implementation --- 
    enum CodingKeys: String, CodingKey {
        case id, text, isDone, priority, estimatedDuration, dateCreated, difficulty
        // --- Add Roadmap Keys ---
        case category, projectOrPath, shortSummary, projectType
        // -----------------------
    }
    
    // Custom Decoder Init for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isDone = try container.decode(Bool.self, forKey: .isDone)
        priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        estimatedDuration = try container.decodeIfPresent(String.self, forKey: .estimatedDuration)
        dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        difficulty = try container.decodeIfPresent(Difficulty.self, forKey: .difficulty)
        // --- Decode Roadmap Metadata ---
        category = try container.decodeIfPresent(String.self, forKey: .category)
        projectOrPath = try container.decodeIfPresent(String.self, forKey: .projectOrPath)
        shortSummary = try container.decodeIfPresent(String.self, forKey: .shortSummary)
        projectType = try container.decodeIfPresent(ProjectType.self, forKey: .projectType)
        // -----------------------------
    }
    
    // Explicit Encoder Implementation (Good practice when customizing init)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(isDone, forKey: .isDone)
        try container.encodeIfPresent(priority, forKey: .priority)
        try container.encodeIfPresent(estimatedDuration, forKey: .estimatedDuration)
        try container.encode(dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(difficulty, forKey: .difficulty)
        // --- Encode Roadmap Metadata ---
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(projectOrPath, forKey: .projectOrPath)
        try container.encodeIfPresent(shortSummary, forKey: .shortSummary)
        try container.encodeIfPresent(projectType, forKey: .projectType)
        // -----------------------------
    }
    // -------------------------------------
}

// Extension to provide display text for roadmap
extension TodoItem {
    // Get text for roadmap display (prefers short summary, falls back to truncated text)
    var roadmapDisplayText: String {
        if let summary = shortSummary, !summary.isEmpty {
            return summary
        } else {
            // Truncate long text to ~30 characters
            let maxLength = 30
            if text.count > maxLength {
                return String(text.prefix(maxLength)) + "..."
            }
            return text
        }
    }
    
    // Helper to check if task needs a summary
    var needsSummary: Bool {
        shortSummary == nil && text.count > 40
    }
}

// Main View hosting the TabView
struct ContentView: View {
    let sciFiFont = "Orbitron" // <<-- CHANGE FONT NAME HERE if needed
    let sciFiFontSize: CGFloat = 16 // Adjust size as needed
    
    // Create the shared AuthenticationService instance here
    @StateObject private var authService = AuthenticationService()
    
    // --- State for Tab Selection ---
    @State private var selectedTab: Int = 0 // Default to first tab (Chat)
    let roadmapTabIndex = 4 // Assign index for Roadmap tab
    // -----------------------------
    
    // --- State for Audio Player ---
    @State private var audioPlayer: AVAudioPlayer?
    // ----------------------------

    var body: some View {
        // --- iOS 26 Liquid Glass TabView --- 
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(0) // Assign tag for Chat
            
            TodoListView()
                .tabItem {
                    Label("To-Do List", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(1) // Assign tag for To-Do
            
            // --- NEW Calendar Tab --- 
            TodayCalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(2) // Assign tag for Calendar
            // ------------------------
            
            // --- NEW Notes Tab --- 
            NotesView()
                .tabItem {
                    Label("Scratchpad", systemImage: "note.text")
                }
                .tag(3) // Assign tag for Notes
            // ---------------------
            // --- ADDED Roadmap Tab ---
            RoadmapView()
                .tabItem {
                    Label("Roadmap", systemImage: "map.fill")
                }
                .tag(roadmapTabIndex) // Assign tag for Roadmap
                // --- Add ID modifier to reset state --- 
                .id(selectedTab == roadmapTabIndex) 
                // --------------------------------------
            // ------------------------
        }
        // .font(.custom(sciFiFont, size: sciFiFontSize)) // <-- REMOVE Global Font
        .accentColor(Color.theme.accent) // Set global accent color (for tab items, etc.)
        // --- iOS 26 Liquid Glass TabBar --- 
        .conditionalTabBarStyle()
        // ----------------------------------
        .environmentObject(authService) // <-- Inject the service into the environment
        // --- Add onChange to play sound --- 
        .onChange(of: selectedTab) { oldValue, newValue in
            // Play sound if navigating AWAY from Roadmap
            if oldValue == roadmapTabIndex && newValue != roadmapTabIndex {
                // TODO: Add tab_switch.wav to project resources
                // playSound(sound: "tab_switch.wav")
            }
        }
        // ----------------------------------
    }
    
    // --- Function to play sound --- 
    func playSound(sound: String) {
        guard let url = Bundle.main.url(forResource: sound, withExtension: nil) else {
            print("Error: Could not find sound file named \(sound)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            print("DEBUG: Playing sound \(sound)")
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    // ----------------------------
}

// View for displaying and managing the To-Do List
struct TodoListView: View {
    // Use the shared singleton instance
    // Use @ObservedObject because the view doesn't own the store's lifecycle
    @ObservedObject private var todoListStore = TodoListStore.shared
    
    // State for the text field input within this view
    @State private var newItemText: String = ""
    // --- ADDED: State to track expanded item --- 
    @State private var expandedItemId: UUID? = nil
    // --- ADDED: State for editing expanded item --- 
    @State private var editingCategory: String = ""
    @State private var editingProject: String = ""
    // --- ADDED: State for New Project Alert --- 
    @State private var showingNewProjectAlert = false
    @State private var newProjectName = ""
    // --------------------------------------------
    let sciFiFont = "Orbitron"
    let titleFontSize: CGFloat = 22 // Match ChatView title size

    // --- ADDED: Date Formatter --- 
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // e.g., "Jun 23, 2024"
        formatter.timeStyle = .none
        return formatter
    }()
    // -----------------------------

    // --- ADDED: Computed property for existing projects ---
    private var existingProjectsForPicker: [String] {
        // Get unique, non-nil, non-empty project paths from the store
        var projects = Set(todoListStore.items.compactMap { $0.projectOrPath?.isEmpty == false ? $0.projectOrPath : nil })
        
        // Ensure the currently selected/edited project is always included as an option
        if !editingProject.isEmpty && !projects.contains(editingProject) {
            projects.insert(editingProject)
        }
        
        return projects.sorted()
    }
    // -----------------------------------------------------
    
    // Computed property for sorted items
    private var sortedItems: [TodoItem] {
        todoListStore.items.sorted { 
            guard let p1 = $0.priority else { return false }
            guard let p2 = $1.priority else { return true }
            return p1 < p2 
        }
    }

    var body: some View {
        NavigationView { 
            VStack(spacing: 0) {
                inputBar
                taskList
            }
            .background(Color(UIColor.systemGray6).ignoresSafeArea())
            .foregroundColor(Color.theme.text)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { 
                ToolbarItem(placement: .navigationBarLeading) {
                    SyncStatusView()
                }
                ToolbarItem(placement: .principal) {
                    Text("Objectives")
                        .font(.custom(sciFiFont, size: titleFontSize))
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.titleText)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    refreshButton
                    EditButton().foregroundColor(Color.theme.accent)
                }
            }
            .toolbarBackground(.indigo, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("New Project", isPresented: $showingNewProjectAlert) {
                TextField("Project Name", text: $newProjectName)
                    .autocapitalization(.words)
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    if !newProjectName.isEmpty {
                        editingProject = newProjectName 
                    }
                }
            } message: {
                Text("Enter the name for the new project.")
            }
        }
    }
    
    private var inputBar: some View {
        HStack {
            TextField("What needs to be done?", text: $newItemText)
                .textFieldStyle(.plain)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            
            Spacer()

            Button {
                todoListStore.addItem(text: newItemText)
                newItemText = "" 
            } label: {
                Text("Add")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .glassButtonStyle(prominent: true)
            }
            .disabled(newItemText.isEmpty)
            .buttonStyle(.borderless)
        }
        .glassInputStyle() // Use the iOS 26 glass input styling from ContentView extensions
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // INCOMPLETE TASKS - Main focus area
                incompleteTasks
                
                // COMPLETED TASKS - Compact section
                completedTasks
                
                // Add some bottom padding
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(
            // iOS 26 glass background
            Group {
                if #available(iOS 26.0, *) {
                    Color.clear
                        .background(.ultraThinMaterial)
                } else {
                    Color(UIColor.systemGray6)
                }
            }
        )
    }
    
    private var incompleteTasks: some View {
        VStack(spacing: 12) {
            let incompleteItems = sortedItems.filter { !$0.isDone }
            
            if !incompleteItems.isEmpty {
                // Section header with total time estimate
                HStack {
                    Text("What needs to be done?")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let totalTime = calculateTotalTime(for: incompleteItems) {
                        Text(totalTime)
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Group {
                                    if #available(iOS 26.0, *) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.blue.opacity(0.1))
                                            .glassEffect(in: RoundedRectangle(cornerRadius: 6))
                                    } else {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.blue.opacity(0.1))
                                    }
                                }
                            )
                    }
                }
                .padding(.horizontal, 4)
                
                // Incomplete task rows
                ForEach(incompleteItems) { item in
                    TaskRowView(
                        item: item,
                        expandedItemId: $expandedItemId,
                        editingCategory: $editingCategory,
                        editingProject: $editingProject,
                        showingNewProjectAlert: $showingNewProjectAlert,
                        newProjectName: $newProjectName,
                        existingProjectsForPicker: existingProjectsForPicker,
                        dateFormatter: dateFormatter,
                        todoListStore: todoListStore,
                        saveEdits: saveEdits,
                        playSound: playSound
                    )
                    .background(
                        Group {
                            if #available(iOS 26.0, *) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            }
                        }
                    )
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("All done! 🎉")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Take a moment to appreciate your progress.")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            }
        }
    }
    
    @State private var showCompletedTasks = true
    
    private var completedTasks: some View {
        VStack(spacing: 8) {
            let completedItems = sortedItems.filter { $0.isDone }
            
            if !completedItems.isEmpty {
                // Completed section header with toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showCompletedTasks.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: showCompletedTasks ? "chevron.down" : "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Completed (\(completedItems.count))")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Tap to \(showCompletedTasks ? "hide" : "show")")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                
                // Completed task rows (compact)
                if showCompletedTasks {
                    ForEach(completedItems) { item in
                        CompactTaskRowView(
                            item: item,
                            dateFormatter: dateFormatter,
                            todoListStore: todoListStore,
                            playSound: playSound
                        )
                    }
                }
            }
        }
    }
    
    // Helper function to calculate total time for tasks
    private func calculateTotalTime(for items: [TodoItem]) -> String? {
        let timesWithEstimates = items.compactMap { item -> Int? in
            guard let duration = item.estimatedDuration else { return nil }
            
            // Parse common time formats: "30 min", "1 hour", "45 minutes", etc.
            let lowercased = duration.lowercased()
            if lowercased.contains("min") {
                let numbers = lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted)
                if let minutes = numbers.compactMap({ Int($0) }).first {
                    return minutes
                }
            } else if lowercased.contains("hour") {
                let numbers = lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted)
                if let hours = numbers.compactMap({ Int($0) }).first {
                    return hours * 60
                }
            }
            return nil
        }
        
        guard !timesWithEstimates.isEmpty else { return nil }
        
        let totalMinutes = timesWithEstimates.reduce(0, +)
        if totalMinutes < 60 {
            return "\(totalMinutes) min total"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 {
                return "\(hours)h total"
            } else {
                return "\(hours)h \(minutes)m total"
            }
        }
    }
    
    private var refreshButton: some View {
        Button {
            Task {
                await refreshFromCloudKit()
            }
        } label: {
            Image(systemName: "arrow.clockwise.icloud")
                .foregroundColor(Color.theme.accent)
        }
    }
    
    // Note: Move functionality removed since we switched to card-based layout
    // Users can still reorder by editing priority numbers in the expanded view
    
    // --- ADDED: Helper function to save edits --- 
    private func saveEdits(for item: TodoItem) {
        // Check if the item being saved is the currently expanded one
        // (Prevents saving stale data if user quickly collapses/expands)
        guard expandedItemId == item.id else { return }
        
        if let expandedIndex = todoListStore.items.firstIndex(where: { $0.id == item.id }) {
            let currentItem = todoListStore.items[expandedIndex]
            if currentItem.category ?? "" != editingCategory || currentItem.projectOrPath ?? "" != editingProject {
                 print("DEBUG [TodoView]: Saving edits (via onSubmit) for \(item.text)")
                todoListStore.updateTaskCategory(description: item.text, category: editingCategory)
                todoListStore.updateTaskProjectOrPath(description: item.text, projectOrPath: editingProject)
            }
        }
        // Optionally hide keyboard
        // hideKeyboard()
    }
    
    // --- Function to play sound --- 
    func playSound(sound: String) {
        // Simple implementation - can be enhanced
        print("Playing sound: \(sound)")
    }
    
    // Manual refresh from CloudKit
    private func refreshFromCloudKit() async {
        await todoListStore.manualRefreshFromCloudKit()
    }
    // ---------------------------------------------
}

// Separate view for task rows to reduce complexity
struct TaskRowView: View {
    let item: TodoItem
    @Binding var expandedItemId: UUID?
    @Binding var editingCategory: String
    @Binding var editingProject: String
    @Binding var showingNewProjectAlert: Bool
    @Binding var newProjectName: String
    let existingProjectsForPicker: [String]
    let dateFormatter: DateFormatter
    let todoListStore: TodoListStore
    let saveEdits: (TodoItem) -> Void
    let playSound: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mainRowContent
            
            if expandedItemId == item.id {
                expandedContent
            }
        }
    }
    
    private var mainRowContent: some View {
        HStack(spacing: 16) { 
            // Tappable Done/Undone Icon
            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 28, height: 28) 
                .foregroundColor(item.isDone ? Color.green : Color.gray)
                .onTapGesture { 
                    todoListStore.toggleDone(item: item)
                }
            
            // Main content area
            VStack(alignment: .leading, spacing: 6) { 
                // Task title
                Text(item.text)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .strikethrough(item.isDone, color: .gray) 
                    .foregroundColor(item.isDone ? Color.gray : Color.primary)
                    .multilineTextAlignment(.leading)
                
                // Summary text (if available)
                if let summary = item.shortSummary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // Metadata badges
                HStack(spacing: 8) {
                    // Priority badge
                    if let priority = item.priority {
                        Text(priorityText(for: priority))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(priorityColor(for: priority))
                            .foregroundColor(priorityTextColor(for: priority))
                            .cornerRadius(6)
                    }
                    
                    // Duration badge - more prominent for ADHD time awareness
                    if let duration = item.estimatedDuration, !duration.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(duration)
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.isDone ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                        .foregroundColor(item.isDone ? .secondary : .blue)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(item.isDone ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Project badge
                    if let project = item.projectOrPath, !project.isEmpty {
                        Text(project)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.secondary)
                            .cornerRadius(6)
                    }
                    
                    // Difficulty indicator for ADHD cognitive load awareness
                    if let difficulty = item.difficulty, !item.isDone {
                        HStack(spacing: 2) {
                            Image(systemName: difficultyIcon(for: difficulty))
                                .font(.system(size: 10))
                            Text(difficulty.rawValue)
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(difficultyColor(for: difficulty))
                        .foregroundColor(difficultyTextColor(for: difficulty))
                        .cornerRadius(4)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                handleTap()
            }
        }
    }
    
    private var expandedContent: some View {
        VStack(spacing: 12) {
            // METADATA GRID - Compact 2x2 cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                
                // Category Card
                if UserDefaults.standard.bool(forKey: AppSettings.enableCategoriesKey) {
                    MetadataCardView(
                        icon: "folder.circle",
                        title: "Category", 
                        value: editingCategory.isEmpty ? "None" : editingCategory,
                        color: .orange
                    ) {
                        TextField("Add category", text: $editingCategory)
                            .font(.caption)
                            .textFieldStyle(.plain)
                            .onSubmit { saveEdits(item) }
                    }
                }
                
                // Project Card - clean picker only
                MetadataCardView(
                    icon: "rectangle.3.group",
                    title: "Project",
                    value: editingProject.isEmpty ? "Unassigned" : truncateText(editingProject, maxLength: 15),
                    color: .purple
                ) {
                    Picker("Project", selection: $editingProject) {
                        Text("Unassigned").tag("")
                        ForEach(existingProjectsForPicker, id: \.self) { project in
                            Text(project).tag(project)
                        }
                        Text("+ Add New Project").tag("__ADD_NEW__")
                    }
                    .pickerStyle(.menu)
                    .font(.caption2)
                    .onChange(of: editingProject) { _, newValue in 
                        if newValue == "__ADD_NEW__" {
                            // Reset to previous value and show alert
                            editingProject = item.projectOrPath ?? ""
                            showingNewProjectAlert = true
                            newProjectName = ""
                        } else {
                            saveEdits(item)
                        }
                    }
                }
                
                // Difficulty Card (if available)
                if let difficulty = item.difficulty {
                    MetadataCardView(
                        icon: "gauge.medium.badge.plus",
                        title: "Difficulty",
                        value: difficulty.rawValue,
                        color: difficultyDisplayColor(for: difficulty),
                        isReadOnly: true
                    )
                }
                
                // Created Date Card
                MetadataCardView(
                    icon: "calendar.badge.clock",
                    title: "Created",
                    value: formatCompactDate(item.dateCreated),
                    color: .gray,
                    isReadOnly: true
                )
            }
            
            // SUMMARY SECTION - Only if needed, much more compact
            if item.needsSummary || !(item.shortSummary?.isEmpty ?? true) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                        Text("Roadmap Summary")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        if item.needsSummary {
                            Text("• Recommended")
                                .font(.caption2)
                                .foregroundColor(.blue.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    
                    TextField("Add 3-5 word summary for roadmap", text: Binding(
                        get: { item.shortSummary ?? "" },
                        set: { newValue in
                            todoListStore.updateTaskSummary(taskId: item.id, summary: newValue.isEmpty ? nil : newValue)
                        }
                    ))
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.04))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                    )
                    .onSubmit { saveEdits(item) }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.02))
        .cornerRadius(8)
        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
    }
    
    // Helper functions for the new design
    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength - 1)) + "…"
    }
    
    private func formatCompactDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "E" // Mon, Tue, etc.
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
    
    private func difficultyDisplayColor(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .low: return .green
        case .medium: return .orange  
        case .high: return .red
        }
    }
    
    // Priority helper functions
    private func priorityText(for priority: Int) -> String {
        switch priority {
        case 1...3: return "High Priority"
        case 4...6: return "Medium Priority"
        case 7...10: return "Low Priority"
        default: return "Priority \(priority)"
        }
    }
    
    private func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 1...3: return Color.red.opacity(0.1)
        case 4...6: return Color.orange.opacity(0.1)
        case 7...10: return Color.gray.opacity(0.1)
        default: return Color.gray.opacity(0.1)
        }
    }
    
    private func priorityTextColor(for priority: Int) -> Color {
        switch priority {
        case 1...3: return Color.red
        case 4...6: return Color.orange
        case 7...10: return Color.secondary
        default: return Color.secondary
        }
    }
    
    // MARK: - Difficulty Helper Functions for ADHD Cognitive Load Awareness
    private func difficultyIcon(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .low: return "circle"
        case .medium: return "circle.fill" 
        case .high: return "exclamationmark.circle.fill"
        }
    }
    
    private func difficultyColor(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .low: return Color.green.opacity(0.15)
        case .medium: return Color.orange.opacity(0.15)
        case .high: return Color.red.opacity(0.15)
        }
    }
    
    private func difficultyTextColor(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .low: return Color.green.opacity(0.8)
        case .medium: return Color.orange.opacity(0.8)
        case .high: return Color.red.opacity(0.8)
        }
    }
    
    private func handleTap() {
        // Save changes when collapsing
        if let currentlyExpanded = expandedItemId,
           let expandedIndex = todoListStore.items.firstIndex(where: { $0.id == currentlyExpanded }) {
            let currentItem = todoListStore.items[expandedIndex]
            if currentItem.category ?? "" != editingCategory || currentItem.projectOrPath ?? "" != editingProject {
                print("DEBUG [TodoView]: Saving edits for \(currentItem.text)")
                todoListStore.updateTaskCategory(description: currentItem.text, category: editingCategory)
                todoListStore.updateTaskProjectOrPath(description: currentItem.text, projectOrPath: editingProject)
            }
        }
        
        if expandedItemId == item.id {
            expandedItemId = nil
        } else {
            expandedItemId = item.id
            editingCategory = item.category ?? ""
            editingProject = item.projectOrPath ?? ""
        }
    }
}

// MARK: - Compact Task Row for Completed Items
struct CompactTaskRowView: View {
    let item: TodoItem
    let dateFormatter: DateFormatter  
    let todoListStore: TodoListStore
    let playSound: (String) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Small green checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
                .onTapGesture {
                    todoListStore.toggleDone(item: item)
                    playSound("task_completion")
                }
            
            // Compact task text
            VStack(alignment: .leading, spacing: 2) {
                Text(item.text)
                    .font(.system(.subheadline, design: .rounded))
                    .strikethrough(true, color: .gray)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                // Show completion time if available
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Text("Completed \(item.dateCreated, formatter: RelativeDateTimeFormatter())")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    // Show time estimate if available
                    if let duration = item.estimatedDuration {
                        Text("• \(duration)")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            // Quick undo button
            Button {
                todoListStore.toggleDone(item: item)
                playSound("task_undo")
            } label: {
                Image(systemName: "arrow.uturn.backward.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - MetadataCardView Component
struct MetadataCardView<Content: View>: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let isReadOnly: Bool
    let content: (() -> Content)?
    
    init(
        icon: String,
        title: String,
        value: String,
        color: Color,
        isReadOnly: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.isReadOnly = isReadOnly
        self.content = content
    }
    
    init(
        icon: String,
        title: String,
        value: String,
        color: Color,
        isReadOnly: Bool = true
    ) where Content == EmptyView {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.isReadOnly = isReadOnly
        self.content = nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            // Content
            if let content = content {
                content()
            } else {
                Text(value)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.08))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}