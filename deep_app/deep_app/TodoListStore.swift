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
        do {
            let decodedItems = try JSONDecoder().decode([TodoItem].self, from: itemsData)
            self.items = decodedItems
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) && !items.isEmpty {
                print("DEBUG [Store]: Successfully loaded \(items.count) items.")
            }
        } catch {
            // Log the specific decoding error
            print("ERROR [Store]: Failed to decode items from AppStorage: \(error)")
            print("ERROR [Store]: Resetting items to empty list.")
            // It might be useful to log the raw data that failed to decode, if possible
            // print("ERROR [Store]: Raw data that failed: \(itemsData.map { String(format: "%02x", $0) }.joined())")
            self.items = [] // Initialize with empty array if decoding fails
            // Optionally, you could try backing up the corrupted itemsData here
        }
    }
    
    // Save items back to AppStorage asynchronously
    private func saveItems() {
        // Capture the current items state to save
        let itemsToSave = self.items
        
        // Perform encoding and saving in a detached background task
        Task.detached(priority: .background) { [itemsToSave] in
            do {
                let encodedData = try JSONEncoder().encode(itemsToSave)
                // Update AppStorage (UserDefaults) - this itself is thread-safe
                await MainActor.run { // Ensure AppStorage update is on main actor if needed, although UserDefaults is thread-safe
                    self.itemsData = encodedData
                }
            } catch {
                // Use await MainActor.run for print if you need UI updates based on error
                print("Error: Failed to encode items for saving: \(error)")
            }
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
    
    // Method to provide a formatted string of the current tasks
    func getFormattedTaskList() -> String {
        if items.isEmpty {
            return "Your to-do list is currently empty."
        }
        
        var formattedList = "Here are your current tasks:\n"
        for item in items {
            let status = item.isDone ? "[Done]" : "[ ]"
            formattedList += "- \(status) \(item.text)\n"
        }
        return formattedList
    }
    
    // Method to delete a single item
    func deleteItem(item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
            saveItems()
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Deleted single item '\(item.text)'")
            }
        }
    }
    
    // Method to remove a task by its description (removes first match)
    // Returns true if a task was found and removed, false otherwise.
    @discardableResult // Indicate that the return value doesn't always need to be used
    func removeTask(description: String) -> Bool {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = items.firstIndex(where: { $0.text.caseInsensitiveCompare(trimmedDescription) == .orderedSame }) {
            items.remove(at: index)
            saveItems()
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Removed task '\(trimmedDescription)'")
            }
            return true
        } else {
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Task '\(trimmedDescription)' not found for removal.")
            }
            return false
        }
    }
    
    // Method to update task priorities based on an ordered list of descriptions
    func updatePriorities(orderedTasks: [String]) {
        // Create a map for quick lookup: description -> priority
        var priorityMap: [String: Int] = [:]
        for (index, description) in orderedTasks.enumerated() {
            // Use case-insensitive comparison for robustness if needed, but store original case from AI
            // For simplicity here, we assume the AI sends back descriptions it received.
            priorityMap[description.trimmingCharacters(in: .whitespacesAndNewlines)] = index + 1 // Priority 1, 2, 3...
        }
        
        // Iterate through existing items and update priorities
        var changed = false
        for i in items.indices {
            let itemText = items[i].text.trimmingCharacters(in: .whitespacesAndNewlines)
            let newPriority = priorityMap[itemText] // Returns nil if task not in the ordered list
            
            if items[i].priority != newPriority {
                items[i].priority = newPriority
                changed = true
            }
        }
        
        // Save if any priorities were changed
        if changed {
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Priorities updated based on ordered list.")
            }
            saveItems()
            // Since `items` is @Published, this will trigger UI updates in views observing the store
            // We might need to explicitly trigger objectWillChange if sorting happens outside SwiftUI view update
            // But since sorting is in the View's ForEach, it should re-render correctly.
        }
    }

    // Method to update priorities based on a new manual sort order
    func updateOrder(itemsInNewOrder: [TodoItem]) {
        var changed = false
        guard itemsInNewOrder.count == items.count else {
            print("Error: Mismatch in item count during reorder.")
            return
        }
        
        // Create a map of ID -> New Index (Priority)
        var newPriorityMap: [UUID: Int] = [:]
        for (index, item) in itemsInNewOrder.enumerated() {
            newPriorityMap[item.id] = index + 1 // Priority 1, 2, 3...
        }
        
        // Update priorities in the original items array
        for i in items.indices {
            if let newPriority = newPriorityMap[items[i].id] {
                if items[i].priority != newPriority {
                    items[i].priority = newPriority
                    changed = true
                }
            } else {
                // Should not happen if counts match, but handle defensively
                if items[i].priority != nil {
                    items[i].priority = nil // Item somehow wasn't in the moved list, clear priority
                    changed = true
                }
            }
        }
        
        if changed {
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Priorities updated based on manual move.")
            }
            saveItems()
            // No need to manually publish changes here, the @Published items array modification
            // combined with saveItems() calling @AppStorage setter handles updates.
        }
    }

    // Method to update the estimated duration for a task by its description
    func updateTaskDuration(description: String, duration: String?) {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = items.firstIndex(where: { $0.text.caseInsensitiveCompare(trimmedDescription) == .orderedSame }) {
            items[index].estimatedDuration = duration
            saveItems() // Save the change
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Updated duration for '\(trimmedDescription)' to '\(duration ?? "nil")'")
            }
        } else {
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Task '\(trimmedDescription)' not found for duration update.")
            }
        }
    }
    
    // --- ADDED: Method to mark a task complete by description ---
    @discardableResult
    func markTaskComplete(description: String) async -> Bool {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Use await MainActor.run to ensure modification happens on the main thread
        let updated = await MainActor.run { () -> Bool in
            if let index = items.firstIndex(where: { $0.text.caseInsensitiveCompare(trimmedDescription) == .orderedSame }) {
                // Only mark as done if it's not already done
                if !items[index].isDone {
                    items[index].isDone = true
                    if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                        print("DEBUG [Store]: Marked task '\(trimmedDescription)' as complete.")
                    }
                    // Trigger save since we modified the items array
                    saveItems()
                    return true // Task found and marked done
                } else {
                    if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                        print("DEBUG [Store]: Task '\(trimmedDescription)' was already marked as complete.")
                    }
                    return true // Task found, but already done (still considered success in finding it)
                }
            } else {
                if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                    print("DEBUG [Store]: Task '\(trimmedDescription)' not found to mark as complete.")
                }
                return false // Task not found
            }
        }
        return updated
    }
    // -----------------------------------------------------------
} 