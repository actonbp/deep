//
//  ContentView.swift
//  deep_app
//
//  Created by bacton on 4/15/25.
//

import SwiftUI
import AVFoundation // <-- Import AVFoundation for audio

// --- ADDED: Difficulty Enum ---
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
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
    // ------------------------
    
    // --- Corrected Custom Init (only assigns properties not already defaulted) ---
    init(id: UUID = UUID(), text: String, isDone: Bool = false, priority: Int? = nil, estimatedDuration: String? = nil, dateCreated: Date = Date(), difficulty: Difficulty? = nil, category: String? = nil, projectOrPath: String? = nil) {
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
        // -----------------------------
    }
    // ------------------------------------------------------------------------
    
    // --- Custom Codable Implementation --- 
    enum CodingKeys: String, CodingKey {
        case id, text, isDone, priority, estimatedDuration, dateCreated, difficulty
        // --- Add Roadmap Keys ---
        case category, projectOrPath
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
        // -----------------------------
    }
    // -------------------------------------
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
        // --- Add selection binding --- 
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
        // --- Apply background material to the TabView bar --- 
        .background(.ultraThinMaterial)
        // -----------------------------------------------------
        .environmentObject(authService) // <-- Inject the service into the environment
        // --- Add onChange to play sound --- 
        .onChange(of: selectedTab) { oldValue, newValue in
            // Play sound if navigating AWAY from Roadmap
            if oldValue == roadmapTabIndex && newValue != roadmapTabIndex {
                playSound(sound: "tab_switch.wav") // <-- REPLACE with your sound file name
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

    var body: some View {
        NavigationView { 
            VStack {
                // --- Input Bar --- 
                HStack {
                    TextField("Enter new item", text: $newItemText)
                        .textFieldStyle(.plain) // Use plain style
                        .padding(.vertical, 8) // Add some vertical padding
                    
                    Spacer() // Push button to the right

                    Button {
                        todoListStore.addItem(text: newItemText)
                        newItemText = "" 
                    } label: {
                        Image(systemName: "plus.circle.fill") // Use an icon button
                            .font(.title2)
                    }
                    .disabled(newItemText.isEmpty)
                    .foregroundColor(Color.theme.accent)
                    .buttonStyle(.borderless) // Use borderless style
                }
                .padding(.horizontal)
                .padding(.vertical, 5) // Less vertical padding for the bar itself
                .background(Color(UIColor.systemGray6)) // Subtle background
                .cornerRadius(10)
                .padding(.horizontal) // Padding around the bar
                .padding(.top, 5) // Padding from the top edge / title
                // ---------------

                List { // Display the list of items from the store
                    // Sort items by priority (nil is lowest), then alphabetically
                    ForEach(todoListStore.items.sorted { 
                        // Handle nil priorities: non-nil priority comes before nil
                        guard let p1 = $0.priority else { return false } // item 1 has nil priority, sort it last
                        guard let p2 = $1.priority else { return true }  // item 2 has nil priority, sort item 1 first
                        // Both have non-nil priority, sort numerically
                        return p1 < p2 
                    }) { item in // Iterate over sorted items
                        // --- Wrap Row Content in VStack for Expandability --- 
                        VStack(alignment: .leading, spacing: 4) { // Added spacing
                            // --- Main Tappable Row Content --- 
                            HStack(spacing: 15) { 
                                // Tappable Done/Undone Icon
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .resizable()
                                    .frame(width: 24, height: 24) 
                                    .foregroundColor(item.isDone ? Color.theme.accent : Color.theme.secondaryText)
                                    .onTapGesture { 
                                         // Allow toggling done even when expanded
                                        todoListStore.toggleDone(item: item)
                                    }
                                
                                // Text, Priority, Duration 
                                VStack(alignment: .leading, spacing: 2) { 
                                    if let priority = item.priority {
                                        Text("(\(priority))")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color.theme.accent)
                                    }
                                    Text(item.text)
                                        .strikethrough(item.isDone, color: .gray) 
                                        .foregroundColor(item.isDone ? Color.theme.secondaryText : Color.theme.text) 
                                    
                                    if let duration = item.estimatedDuration, !duration.isEmpty {
                                        Text(duration)
                                            .font(.caption2)
                                            .foregroundColor(Color.theme.secondaryText)
                                            .padding(.leading, item.priority == nil ? 0 : 5) 
                                    }
                                } 
                                Spacer()
                            }
                            .contentShape(Rectangle()) // Make the whole HStack tappable area
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) { // Add animation
                                    // --- Save changes when collapsing --- 
                                    if let currentlyExpanded = expandedItemId,
                                       let expandedIndex = todoListStore.items.firstIndex(where: { $0.id == currentlyExpanded }) {
                                        // Only update if text actually changed to avoid unnecessary saves
                                        let currentItem = todoListStore.items[expandedIndex]
                                        if currentItem.category ?? "" != editingCategory || currentItem.projectOrPath ?? "" != editingProject {
                                            print("DEBUG [TodoView]: Saving edits for \(currentItem.text)")
                                            todoListStore.updateTaskCategory(description: currentItem.text, category: editingCategory)
                                            todoListStore.updateTaskProjectOrPath(description: currentItem.text, projectOrPath: editingProject)
                                        }
                                    }
                                    // ----------------------------------
                                    
                                    if expandedItemId == item.id {
                                        expandedItemId = nil // Collapse
                                    } else {
                                        expandedItemId = item.id // Expand this item
                                        // --- Load current data into editing state --- 
                                        editingCategory = item.category ?? ""
                                        editingProject = item.projectOrPath ?? ""
                                        // --------------------------------------
                                    }
                                }
                            }
                            // -----------------------------------
                            
                            // --- Expanded Metadata Section ---
                            if expandedItemId == item.id {
                                // --- Use VStack for editable fields --- 
                                VStack(alignment: .leading, spacing: 8) { 
                                    // --- Conditionally Show Category Field --- 
                                    if UserDefaults.standard.bool(forKey: AppSettings.enableCategoriesKey) {
                                        HStack {
                                            Text("Category:").font(.caption).foregroundColor(.gray).frame(width: 70, alignment: .leading)
                                            TextField("None", text: $editingCategory)
                                                .font(.caption)
                                                .textFieldStyle(.roundedBorder)
                                                .onSubmit { saveEdits(for: item) } // Save on submit
                                        }
                                    }
                                    // -----------------------------------------
                                    // --- Project/Path Picker + New Button --- 
                                    HStack {
                                        Text("Project/Path:")
                                            .font(.caption)
                                            .foregroundColor(Color.theme.secondaryText)
                                            .frame(width: 90, alignment: .leading) // Align labels
                                        
                                        Picker("Project/Path", selection: $editingProject) {
                                            Text("Unassigned").tag("") // Option for no project
                                            // Use the modified list for the picker options
                                            ForEach(existingProjectsForPicker, id: \.self) { project in
                                                Text(project).tag(project)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(Color.theme.text) // Match other controls
                                        
                                        Button {
                                            showingNewProjectAlert = true
                                            newProjectName = "" // Clear previous entry
                                        } label: {
                                            Image(systemName: "plus.circle")
                                        }
                                        .buttonStyle(.borderless)
                                        .foregroundColor(Color.theme.accent)
                                    }
                                    .padding(.bottom, 10) // More bottom padding
                                    // ----------------------------------------
                                    
                                    // --- RE-ADD Other Metadata Display --- 
                                    // Difficulty
                                    if let difficulty = item.difficulty {
                                        HStack(spacing: 5) { 
                                            Image(systemName: "gauge.medium") 
                                            Text("Effort: \(difficulty.rawValue)")
                                        }
                                        .font(.caption)
                                        .foregroundColor(Color.theme.secondaryText)
                                    }
                                    
                                    // Estimated Duration (already displayed in main row, maybe omit here? Or display again)
                                    /* // Example if we wanted to show duration again here
                                    if let duration = item.estimatedDuration, !duration.isEmpty {
                                        HStack(spacing: 5) { 
                                            Image(systemName: "clock") 
                                            Text("Est: \(duration)")
                                        }
                                        .font(.caption)
                                        .foregroundColor(Color.theme.secondaryText)
                                    }
                                    */
                                    
                                    // Date Created
                                    HStack(spacing: 5) { 
                                        Image(systemName: "calendar") 
                                        Text("Created: \(item.dateCreated, formatter: dateFormatter)")
                                    }
                                    .font(.caption)
                                    .foregroundColor(Color.theme.secondaryText)
                                    // ---------------------------------------
                                }
                                .padding(.leading, 39) // Indent metadata section consistently
                                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top))) // Add transition
                            }
                            // -----------------------------------
                        }
                        // --- End Row VStack ---
                        .padding(.vertical, 4) 
                        .listRowSeparator(.hidden) 
                        .swipeActions(edge: .leading) { 
                            Button {
                                todoListStore.toggleDone(item: item)
                            } label: {
                                Label(item.isDone ? "Mark Undone" : "Mark Done", systemImage: item.isDone ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                            }
                            .tint(item.isDone ? Color.theme.secondaryText : Color.theme.done)
                        }
                        .swipeActions(edge: .trailing) { // Swipe from right (trailing edge)
                            Button(role: .destructive) {
                                todoListStore.deleteItem(item: item) // Use new single item delete
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                    .onMove(perform: moveItems) // Keep .onMove for drag-reorder
                }
                .listStyle(PlainListStyle())
                .background(Color.theme.background)
                .foregroundColor(Color.theme.text)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .foregroundColor(Color.theme.text)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { 
                ToolbarItem(placement: .principal) {
                    Text("Objectives")
                        .font(.custom(sciFiFont, size: titleFontSize))
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.titleText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton().foregroundColor(Color.theme.accent)
                }
            }
            // --- Apply background color and ensure visibility --- 
            .toolbarBackground(.indigo, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar) // Keep this to suggest light status bar items
            // -----------------------------------------------------
            // --- ADDED: Alert for New Project ---
            .alert("New Project", isPresented: $showingNewProjectAlert) {
                TextField("Project Name", text: $newProjectName)
                    .autocapitalization(.words)
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    if !newProjectName.isEmpty {
                        // Update the editing state directly
                        editingProject = newProjectName 
                        // If we want this to be immediately reflected in the store 
                        // for the expanded item, we'd need access to the item's ID here.
                        // For now, rely on the collapse logic to save.
                    }
                }
            } message: {
                Text("Enter the name for the new project.")
            }
            // -------------------------------------
        }
    }
    
    // --- ADDED: Function to handle moving items in the list --- 
    private func moveItems(from source: IndexSet, to destination: Int) {
        // 1. Get the current sorted list as displayed
        var orderedItems = todoListStore.items.sorted { 
            guard let p1 = $0.priority else { return false } 
            guard let p2 = $1.priority else { return true }  
            return p1 < p2 
        }
        
        // 2. Perform the move on this mutable copy
        orderedItems.move(fromOffsets: source, toOffset: destination)
        
        // 3. Pass the newly ordered list to the store to update persistent priorities
        todoListStore.updateOrder(itemsInNewOrder: orderedItems)
    }
    
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
    // ---------------------------------------------
}

#Preview {
    ContentView()
}
