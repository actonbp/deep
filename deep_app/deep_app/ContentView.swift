//
//  ContentView.swift
//  deep_app
//
//  Created by bacton on 4/15/25.
//

import SwiftUI

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
    var isDone: Bool = false // Status flag
    var priority: Int? = nil // Added priority field (optional integer)
    var estimatedDuration: String? = nil // Added estimated duration (optional string)
    var dateCreated: Date
    var difficulty: Difficulty? = nil
    // --- Roadmap Metadata ---
    var category: String? = nil // e.g., "Research", "Teaching", "Life"
    var projectOrPath: String? = nil // e.g., "Paper XYZ", "LEAD 552"
    // ------------------------
    
    // --- Custom Init ---
    init(id: UUID = UUID(), text: String, isDone: Bool = false, priority: Int? = nil, estimatedDuration: String? = nil, dateCreated: Date = Date(), difficulty: Difficulty? = nil, category: String? = nil, projectOrPath: String? = nil) {
        self.id = id
        self.text = text
        self.isDone = isDone
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.dateCreated = dateCreated
        self.difficulty = difficulty
        self.category = category
        self.projectOrPath = projectOrPath
    }
    
    // --- Custom Codable Implementation for backward compatibility --- 
    enum CodingKeys: String, CodingKey {
        case id, text, isDone, priority, estimatedDuration, dateCreated, difficulty, category, projectOrPath
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isDone = try container.decode(Bool.self, forKey: .isDone)
        priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        estimatedDuration = try container.decodeIfPresent(String.self, forKey: .estimatedDuration)
        dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        difficulty = try container.decodeIfPresent(Difficulty.self, forKey: .difficulty)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        projectOrPath = try container.decodeIfPresent(String.self, forKey: .projectOrPath)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(isDone, forKey: .isDone)
        try container.encodeIfPresent(priority, forKey: .priority)
        try container.encodeIfPresent(estimatedDuration, forKey: .estimatedDuration)
        try container.encode(dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(difficulty, forKey: .difficulty)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(projectOrPath, forKey: .projectOrPath)
    }
}

// Main View hosting the TabView
struct ContentView: View {
    let sciFiFont = "Orbitron" // <<-- CHANGE FONT NAME HERE if needed
    let sciFiFontSize: CGFloat = 16 // Adjust size as needed
    
    // Create the shared AuthenticationService instance here
    @StateObject private var authService = AuthenticationService()
    
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
            
            TodoListView()
                .tabItem {
                    Label("To-Do List", systemImage: "list.bullet.clipboard.fill")
                }
            
            // --- Calendar Tab --- 
            TodayCalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            // --------------------
            
            // --- Scratchpad Tab --- 
            NotesView()
                .tabItem {
                    Label("Scratchpad", systemImage: "note.text")
                }
            // ----------------------
            
            // --- Roadmap Tab ---
            RoadmapView()
                .tabItem {
                    Label("Roadmap", systemImage: "map.fill")
                }
            // ------------------
        }
        // .font(.custom(sciFiFont, size: sciFiFontSize)) // <-- REMOVE Global Font
        .accentColor(Color.theme.accent) // Set global accent color (for tab items, etc.)
        .environmentObject(authService) // <-- Inject the service into the environment
    }
}

// View for displaying and managing the To-Do List
struct TodoListView: View {
    // Use the shared singleton instance
    // Use @ObservedObject because the view doesn't own the store's lifecycle
    @ObservedObject private var todoListStore = TodoListStore.shared
    
    // State for the text field input within this view
    @State private var newItemText: String = ""
    let sciFiFont = "Orbitron"
    let titleFontSize: CGFloat = 22 // Match ChatView title size

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
                        HStack(spacing: 15) { // Added spacing
                            // --- Tappable Done/Undone Icon --- 
                            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                .resizable()
                                .frame(width: 24, height: 24) // Explicit frame
                                .foregroundColor(item.isDone ? Color.theme.accent : Color.theme.secondaryText)
                                .onTapGesture {
                                    todoListStore.toggleDone(item: item)
                                }
                            // --------------------------------
                            
                            VStack(alignment: .leading, spacing: 2) { // Use VStack for Text + Duration
                                // Display priority if available
                                if let priority = item.priority {
                                    Text("(\(priority))")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.theme.accent) // Use theme accent
                                }
                                Text(item.text)
                                    .strikethrough(item.isDone, color: .gray) 
                                    .foregroundColor(item.isDone ? Color.theme.secondaryText : Color.theme.text) // Theme colors
                                
                                // Display duration if available
                                if let duration = item.estimatedDuration, !duration.isEmpty {
                                    Text(duration)
                                        .font(.caption2)
                                        .foregroundColor(Color.theme.secondaryText)
                                        .padding(.leading, item.priority == nil ? 0 : 5) // Indent slightly if priority is shown
                                }
                            } // End VStack
                            Spacer()
                        }
                        .padding(.vertical, 4) // Add some vertical padding to the row
                        .listRowSeparator(.hidden) // Hide default separators
                        .swipeActions(edge: .leading) { // Swipe from left (leading edge)
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
            .toolbarColorScheme(.dark, for: .navigationBar) // Hint status bar
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
    // -----------------------------------------------------------
}

#Preview {
    ContentView()
}
