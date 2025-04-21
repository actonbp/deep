//
//  ContentView.swift
//  deep_app
//
//  Created by bacton on 4/15/25.
//

import SwiftUI

// Define the structure for a To-Do item
struct TodoItem: Identifiable, Codable {
    let id = UUID() // Use let for stable identifier
    var text: String
    var isDone: Bool = false // Status flag
    var priority: Int? = nil // Added priority field (optional integer)
    var estimatedDuration: String? = nil // Added estimated duration (optional string)
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
            
            // --- NEW Calendar Tab --- 
            TodayCalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            // ------------------------
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
                HStack {
                    TextField("Enter new item", text: $newItemText) // Use local state for input
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add") {
                        // Call the store's add method
                        todoListStore.addItem(text: newItemText)
                        newItemText = "" // Clear local input field
                    }
                    .disabled(newItemText.isEmpty)
                    .foregroundColor(Color.theme.accent)
                }
                .padding()

                List { // Display the list of items from the store
                    // Sort items by priority (nil is lowest), then alphabetically
                    ForEach(todoListStore.items.sorted { 
                        // Handle nil priorities: non-nil priority comes before nil
                        guard let p1 = $0.priority else { return false } // item 1 has nil priority, sort it last
                        guard let p2 = $1.priority else { return true }  // item 2 has nil priority, sort item 1 first
                        // Both have non-nil priority, sort numerically
                        return p1 < p2 
                    }) { item in // Iterate over sorted items
                        HStack {
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
                        .contentShape(Rectangle()) // Makes the whole row tappable
                        .onTapGesture { // Keep tap-to-toggle for accessibility/alternative
                            todoListStore.toggleDone(item: item)
                        }
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
