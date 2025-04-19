import Foundation
import SwiftUI

// ObservableObject to manage the To-Do list data centrally
class TodoListStore: ObservableObject {
    
    // Shared singleton instance
    static let shared = TodoListStore()
    
    // Use AppStorage to persist the encoded data
    // Make it accessible but private to modification outside defined funcs
    @AppStorage("todoItemsData") private var itemsData: Data = Data()
    
    // Published property holding the decoded TodoItem array
    // Views can subscribe to this
    @Published var items: [TodoItem] = []
    
    // Make initializer private to prevent creating other instances
    private init() {
        // Load initial data when the store is created
        loadItems()
    }
    
    // Load items from AppStorage
    private func loadItems() {
        guard let decodedItems = try? JSONDecoder().decode([TodoItem].self, from: itemsData) else {
            self.items = [] // Initialize with empty array if decoding fails
            return
        }
        self.items = decodedItems
    }
    
    // Save items back to AppStorage
    private func saveItems() {
        if let encodedData = try? JSONEncoder().encode(items) {
            itemsData = encodedData
        } else {
            print("Error: Failed to encode items for saving.")
        }
    }
    
    // Function to add a new item (now publicly accessible)
    func addItem(text: String) {
        let newItemText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newItemText.isEmpty else { return } 
        
        let todo = TodoItem(text: newItemText, isDone: false)
        items.append(todo)
        saveItems()
    }
    
    // Function to toggle the done status of an item
    func toggleDone(item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isDone.toggle()
            saveItems()
        }
    }
    
    // Function to delete items from the list
    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }
} 