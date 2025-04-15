//
//  ContentView.swift
//  deep_app
//
//  Created by bacton on 4/15/25.
//

import SwiftUI

// Define the structure for a To-Do item
struct TodoItem: Identifiable, Codable {
    var id = UUID() // Make id mutable to allow decoding
    var text: String
    var isDone: Bool = false // Status flag
}

// Main View hosting the TabView
struct ContentView: View {
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
        }
    }
}

// Placeholder for the Chat Interface View
struct ChatView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer() // Push text to center
                Text("Chat Coming Soon")
                    .font(.title)
                    .foregroundColor(.secondary) // Make it a bit dimmer
                Spacer() // Push text to center
            }
            .navigationTitle("Bryan's Brain")
        }
    }
}


// View for displaying and managing the To-Do List
struct TodoListView: View {
    // Store the encoded data in AppStorage
    @AppStorage("todoItemsData") private var itemsData: Data = Data()
    @State private var newItem: String = ""

    // Computed property to handle encoding/decoding the [TodoItem] array
    private var items: [TodoItem] {
        get {
            // Try to decode the data, return empty array if fails
            (try? JSONDecoder().decode([TodoItem].self, from: itemsData)) ?? []
        }
        set {
            // Try to encode the new array, store empty data if fails
            itemsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var body: some View {
        NavigationView { 
            VStack {
                HStack {
                    TextField("Enter new item", text: $newItem)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add") {
                        addItem()
                    }
                    .disabled(newItem.isEmpty)
                }
                .padding()

                List { // Display the list of items
                    ForEach(items) { item in // Iterate over TodoItem objects
                        HStack {
                            Text(item.text)
                                .strikethrough(item.isDone, color: .gray) // Add strikethrough if done
                                .foregroundColor(item.isDone ? .gray : .primary) // Dim text if done
                            Spacer() // Push text to the left
                        }
                        .contentShape(Rectangle()) // Make the whole row tappable
                        .onTapGesture { // Toggle done status on tap
                            toggleDone(item: item)
                        }
                    }
                    .onDelete(perform: deleteItems) // Enable swipe-to-delete
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("To-Do List")
            .toolbar { 
                EditButton()
            }
        }
    }

    // Function to add a new item
    private func addItem() {
        if !newItem.isEmpty {
            let todo = TodoItem(text: newItem) // Create a new TodoItem
            var updatedItems = items // Get current array via computed property
            updatedItems.append(todo)
            // Encode the updated array and assign directly to itemsData
            if let encodedData = try? JSONEncoder().encode(updatedItems) {
                itemsData = encodedData // Directly modify the @AppStorage variable
            }
            newItem = ""
        }
    }
    
    // Function to toggle the done status of an item
    private func toggleDone(item: TodoItem) {
        // Find the index of the item to toggle
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            var updatedItems = items // Get current array via computed property
            updatedItems[index].isDone.toggle() // Flip the isDone status
            
            // Encode the updated array and save
            if let encodedData = try? JSONEncoder().encode(updatedItems) {
                itemsData = encodedData // Directly modify the @AppStorage variable
            }
        }
    }
    
    // Function to delete items from the list
    private func deleteItems(at offsets: IndexSet) {
        var updatedItems = items // Get current array via computed property
        updatedItems.remove(atOffsets: offsets)
        // Encode the updated array and assign directly to itemsData
        if let encodedData = try? JSONEncoder().encode(updatedItems) {
            itemsData = encodedData // Directly modify the @AppStorage variable
        }
    }
}

#Preview {
    ContentView()
}
