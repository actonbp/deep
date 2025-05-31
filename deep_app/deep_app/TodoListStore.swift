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
    
    // CloudKit sync manager
    private let cloudKitManager = CloudKitManager.shared
    private var hasLoadedFromCloud = false
    
    // Notification observers
    private var notificationObservers: [NSObjectProtocol] = []
    
    // Make initializer private to prevent creating other instances
    private init() {
        // Load initial data when the store is created
        loadItems()
        
        // --- MODIFIED: Populate with Sample Data based on Setting --- 
        if UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) {
            print("DEBUG [Store]: Demonstration Mode is ON. Overwriting items with sample data.")
            // Overwrite the published items array, but DO NOT save back to itemsData
            populateWithSampleData() 
        } else {
            // Ensure loaded items are used if demo mode is off
            // loadItems() already sets self.items, so nothing needed here usually,
            // but good place for a debug log.
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                 print("DEBUG [Store]: Demonstration Mode is OFF. Using saved user data (count: \(items.count)).")
            }
            
            // --- CloudKit Sync ---
            syncWithCloudKit()
            setupCloudKitSubscriptions()
            setupLifecycleObservers()
        }
        // ---------------------------------------------------------
    }
    
    deinit {
        // Clean up observers
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Lifecycle Observers
    
    private func setupLifecycleObservers() {
        // Sync when app enters foreground
        let foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("☁️ App entering foreground - syncing with CloudKit")
            self?.syncWithCloudKit()
        }
        
        // Sync when app is about to resign active
        let backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("☁️ App entering background - ensuring CloudKit sync")
            // Force sync all items to CloudKit before backgrounding
            self?.syncAllItemsToCloudKit()
        }
        
        notificationObservers = [foregroundObserver, backgroundObserver]
    }
    
    private func syncAllItemsToCloudKit() {
        guard cloudKitManager.iCloudAvailable else { return }
        
        // Upload all items to ensure everything is synced
        for item in items {
            cloudKitManager.saveTodoItem(item)
        }
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
        // --- ADDED Guard --- 
        // Prevent saving if demo mode is active
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Preventing saveItems() call.")
            return
        }
        // -----------------
        
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
    
    // Method to add a new item, now with optional metadata
    func addItem(text: String, category: String? = nil, projectOrPath: String? = nil) {
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring addItem().")
            return
        }
        // -----------------
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return } // Don't add empty tasks
        
        // Assign a default priority if none exists, or find the highest existing + 1
        let existingPriorities = items.compactMap { $0.priority }
        let maxPriority = existingPriorities.max() ?? 0
        let defaultPriority = maxPriority + 1
        
        let newItem = TodoItem(
            text: trimmedText,
            priority: defaultPriority, // Assign calculated default priority
            category: category, // Assign passed category
            projectOrPath: projectOrPath // Assign passed project/path
        )
        items.append(newItem)
        saveItems()
        
        // Sync to CloudKit
        cloudKitManager.saveTodoItem(newItem)
        
        if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
            print("DEBUG [Store]: Added item: \(trimmedText) [Priority: \(defaultPriority)] [Category: \(category ?? "nil")] [Project: \(projectOrPath ?? "nil")]")
        }
    }
    
    // Function to toggle the done status of an item
    func toggleDone(item: TodoItem) {
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring toggleDone().")
            return
        }
        // -----------------
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isDone.toggle()
            saveItems()
            
            // Sync to CloudKit
            cloudKitManager.saveTodoItem(items[index])
        }
    }
    
    // Function to delete items from the list
    func deleteItems(at offsets: IndexSet) {
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring deleteItems().")
            return
        }
        // -----------------
        
        // Get items to delete before removing them
        let itemsToDelete = offsets.map { items[$0] }
        
        items.remove(atOffsets: offsets)
        saveItems()
        
        // Sync deletions to CloudKit
        for item in itemsToDelete {
            cloudKitManager.deleteTodoItem(item)
        }
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
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring deleteItem().")
            return
        }
        // -----------------
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
            saveItems()
            
            // Sync deletion to CloudKit
            cloudKitManager.deleteTodoItem(item)
            
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Deleted single item '\(item.text)'")
            }
        }
    }
    
    // Method to remove a task by its description (removes first match)
    // Returns true if a task was found and removed, false otherwise.
    @discardableResult // Indicate that the return value doesn't always need to be used
    func removeTask(description: String) -> Bool {
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring removeTask().")
            return false // Return appropriate default
        }
        // -----------------
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = items.firstIndex(where: { $0.text.caseInsensitiveCompare(trimmedDescription) == .orderedSame }) {
            let itemToDelete = items[index]  // Save reference before deletion
            items.remove(at: index)
            saveItems()
            
            // Sync deletion to CloudKit
            cloudKitManager.deleteTodoItem(itemToDelete)
            
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
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring updatePriorities().")
            return
        }
        // -----------------
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
            
            // Sync updated items to CloudKit
            for item in items {
                if priorityMap[item.text.trimmingCharacters(in: .whitespacesAndNewlines)] != nil {
                    cloudKitManager.saveTodoItem(item)
                }
            }
            
            // Since `items` is @Published, this will trigger UI updates in views observing the store
            // We might need to explicitly trigger objectWillChange if sorting happens outside SwiftUI view update
            // But since sorting is in the View's ForEach, it should re-render correctly.
        }
    }

    // Method to update priorities based on a new manual sort order
    func updateOrder(itemsInNewOrder: [TodoItem]) {
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring updateOrder().")
            return
        }
        // -----------------
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
            
            // Sync all items with updated priorities to CloudKit
            for item in items {
                cloudKitManager.saveTodoItem(item)
            }
            
            // No need to manually publish changes here, the @Published items array modification
            // combined with saveItems() calling @AppStorage setter handles updates.
        }
    }

    // Method to update the estimated duration for a task by its description
    func updateTaskDuration(description: String, duration: String?) {
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring updateTaskDuration().")
            return
        }
        // -----------------
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = items.firstIndex(where: { $0.text.caseInsensitiveCompare(trimmedDescription) == .orderedSame }) {
            items[index].estimatedDuration = duration
            saveItems() // Save the change
            
            // Sync to CloudKit
            cloudKitManager.saveTodoItem(items[index])
            
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Updated duration for '\(trimmedDescription)' to '\(duration ?? "nil")'")
            }
        } else {
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Task '\(trimmedDescription)' not found for duration update.")
            }
        }
    }
    
    // --- ADDED: Method to update task difficulty --- 
    func updateTaskDifficulty(description: String, difficulty: Difficulty?) {
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring updateTaskDifficulty().")
            return
        }
        // -----------------
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = items.firstIndex(where: { $0.text.caseInsensitiveCompare(trimmedDescription) == .orderedSame }) {
            items[index].difficulty = difficulty
            saveItems() // Save the change
            
            // Sync to CloudKit
            cloudKitManager.saveTodoItem(items[index])
            
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Updated difficulty for '\(trimmedDescription)' to '\(difficulty?.rawValue ?? "nil")'")
            }
        } else {
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Task '\(trimmedDescription)' not found for difficulty update.")
            }
        }
    }
    // ------------------------------------------------
    
    // --- ADDED: Method to mark a task complete by description ---
    @discardableResult
    func markTaskComplete(description: String) async -> Bool {
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring markTaskComplete().")
            return false // Return appropriate default
        }
        // -----------------
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
                    
                    // Sync to CloudKit
                    cloudKitManager.saveTodoItem(items[index])
                    
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

    // --- ADDED: Methods to update Roadmap metadata ---
    func updateTaskCategory(description: String, category: String?) {
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring updateTaskCategory().")
            return
        }
        // -----------------
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        // Normalize empty string to nil for consistency
        let categoryToSet = (category?.isEmpty ?? true) ? nil : category
        
        if let index = items.firstIndex(where: { $0.text.caseInsensitiveCompare(trimmedDescription) == .orderedSame }) {
            if items[index].category != categoryToSet { // Only save if changed
                items[index].category = categoryToSet
                saveItems() 
                
                // Sync to CloudKit
                cloudKitManager.saveTodoItem(items[index])
                
                if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                    print("DEBUG [Store]: Updated category for '\(trimmedDescription)' to '\(categoryToSet ?? "nil")'")
                }
            }
        } else {
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Task '\(trimmedDescription)' not found for category update.")
            }
        }
    }

    func updateTaskProjectOrPath(description: String, projectOrPath: String?) {
        // --- ADDED Guard ---
        guard !UserDefaults.standard.bool(forKey: AppSettings.demonstrationModeEnabledKey) else {
            print("DEBUG [Store]: Demo Mode Active: Ignoring updateTaskProjectOrPath().")
            return
        }
        // -----------------
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        // Normalize empty string to nil
        let projectToSet = (projectOrPath?.isEmpty ?? true) ? nil : projectOrPath
        
        if let index = items.firstIndex(where: { $0.text.caseInsensitiveCompare(trimmedDescription) == .orderedSame }) {
             if items[index].projectOrPath != projectToSet { // Only save if changed
                items[index].projectOrPath = projectToSet
                saveItems() 
                
                // Sync to CloudKit
                cloudKitManager.saveTodoItem(items[index])
                
                if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                    print("DEBUG [Store]: Updated project/path for '\(trimmedDescription)' to '\(projectToSet ?? "nil")'")
                }
            }
        } else {
            if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                print("DEBUG [Store]: Task '\(trimmedDescription)' not found for project/path update.")
            }
        }
    }
    // ----------------------------------------------------

    // --- ADDED: Sample Data Population Logic ---
    private func populateWithSampleData() {
        let sampleItems = [
            // Teaching: LEAD 352
            TodoItem(text: "Plan Week 1 Lesson", category: "Teaching", projectOrPath: "LEAD 352"),
            TodoItem(text: "Grade Assignment 1", category: "Teaching", projectOrPath: "LEAD 352"),
            TodoItem(text: "Prepare Midterm", isDone: true, category: "Teaching", projectOrPath: "LEAD 352"), // Example done
            
            // Research: WFD Paper
            TodoItem(text: "Review Literature", isDone: true, category: "Research", projectOrPath: "WFD Paper"),
            TodoItem(text: "Collect Data", isDone: true, category: "Research", projectOrPath: "WFD Paper"),
            TodoItem(text: "Analyze Results", category: "Research", projectOrPath: "WFD Paper"),
            TodoItem(text: "Write Draft", category: "Research", projectOrPath: "WFD Paper"),
            TodoItem(text: "Submit Manuscript", category: "Research", projectOrPath: "WFD Paper"),
            
            // Research: New Grant Proposal
            TodoItem(text: "Outline Ideas", category: "Research", projectOrPath: "New Grant Proposal"),
            TodoItem(text: "Draft Budget", category: "Research", projectOrPath: "New Grant Proposal"),
            
            // Life
            TodoItem(text: "Grocery Shopping", category: "Life"), // No specific project
            TodoItem(text: "Schedule Dentist Appt", isDone: true, category: "Life")
        ]
        
        // We directly assign to items here because this is only called during init 
        // when items is guaranteed to be empty. No need to append.
        self.items = sampleItems
        // Again, explicitly DO NOT call saveItems()
    }
    // ------------------------------------------
    
    // MARK: - CloudKit Integration
    
    private func syncWithCloudKit() {
        guard cloudKitManager.iCloudAvailable else {
            print("☁️ iCloud not available, using local storage only")
            return
        }
        
        // Fetch all items from CloudKit
        cloudKitManager.fetchAllTodoItems { [weak self] cloudItems in
            guard let self = self else { return }
            
            if !self.hasLoadedFromCloud {
                self.hasLoadedFromCloud = true
                self.mergeCloudItemsWithLocal(cloudItems)
            }
        }
    }
    
    // Public method for manual refresh
    @MainActor
    func manualRefreshFromCloudKit() async {
        guard cloudKitManager.iCloudAvailable else {
            print("☁️ iCloud not available for manual refresh")
            return
        }
        
        // Set syncing status
        cloudKitManager.syncStatus = .syncing
        
        // Use async/await wrapper for the completion handler
        await withCheckedContinuation { continuation in
            cloudKitManager.fetchAllTodoItems { [weak self] cloudItems in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                // Always merge on manual refresh
                self.mergeCloudItemsWithLocal(cloudItems)
                
                // Set success status briefly
                self.cloudKitManager.syncStatus = .success
                
                // Reset to idle after a short delay
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    self.cloudKitManager.syncStatus = .idle
                }
                
                continuation.resume()
            }
        }
    }
    
    private func setupCloudKitSubscriptions() {
        cloudKitManager.subscribeToChanges()
    }
    
    private func mergeCloudItemsWithLocal(_ cloudItems: [TodoItem]) {
        // Simple merge strategy: combine both sets and remove duplicates by ID
        var mergedItems = self.items
        
        for cloudItem in cloudItems {
            if !mergedItems.contains(where: { $0.id == cloudItem.id }) {
                mergedItems.append(cloudItem)
            } else if let index = mergedItems.firstIndex(where: { $0.id == cloudItem.id }) {
                // If item exists, use the one with more recent modification
                // Since we don't have modification dates yet, prefer cloud version
                mergedItems[index] = cloudItem
            }
        }
        
        self.items = mergedItems
        saveItems() // Save the merged state locally
        
        // Upload any local-only items to CloudKit
        for item in self.items {
            cloudKitManager.saveTodoItem(item)
        }
    }
    
    // Override saveItems to also sync with CloudKit
    private func saveItemsWithCloudSync() {
        // Save locally first
        saveItems()
        
        // Then sync to CloudKit if available
        guard cloudKitManager.iCloudAvailable else { return }
        
        // Upload all items to CloudKit
        // In a production app, you'd want to track which items have changed
        for item in items {
            cloudKitManager.saveTodoItem(item)
        }
    }
} 