import Foundation
import CloudKit
import SwiftUI

/// Manager for CloudKit sync operations
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    // Record Types
    private let todoItemType = "TodoItem"
    private let noteType = "Note"
    
    // Zone Names
    private let todoZoneName = "TodoZone"
    private let notesZoneName = "NotesZone"
    
    @Published var iCloudAvailable = false
    @Published var syncStatus: SyncStatus = .idle
    
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case error(String)
        case success
    }
    
    private init() {
        // Use your app's CloudKit container
        // Option 1: Use default container (recommended for new setups)
        container = CKContainer.default()
        // Option 2: Use specific container (if you've already created one)
        // container = CKContainer(identifier: "iCloud.com.bryanacton.deep")
        
        privateDatabase = container.privateCloudDatabase
        
        checkiCloudAvailability()
        setupZones()
    }
    
    // MARK: - Setup
    
    private func checkiCloudAvailability() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.iCloudAvailable = true
                    print("☁️ iCloud is available")
                case .noAccount:
                    self?.iCloudAvailable = false
                    print("☁️ No iCloud account")
                case .restricted, .couldNotDetermine:
                    self?.iCloudAvailable = false
                    print("☁️ iCloud restricted or unknown")
                case .temporarilyUnavailable:
                    self?.iCloudAvailable = false
                    print("☁️ iCloud temporarily unavailable")
                @unknown default:
                    self?.iCloudAvailable = false
                }
            }
        }
    }
    
    private func setupZones() {
        guard iCloudAvailable else { return }
        
        // Create custom zones for better sync control
        let todoZone = CKRecordZone(zoneName: todoZoneName)
        let notesZone = CKRecordZone(zoneName: notesZoneName)
        
        let operation = CKModifyRecordZonesOperation(
            recordZonesToSave: [todoZone, notesZone],
            recordZoneIDsToDelete: nil
        )
        
        operation.modifyRecordZonesResultBlock = { result in
            switch result {
            case .success:
                print("☁️ Zones created successfully")
                // After zones are created, create initial schema
                self.createInitialSchema()
            case .failure(let error):
                print("☁️ Failed to create zones: \(error)")
            }
        }
        
        privateDatabase.add(operation)
    }
    
    // Create initial schema by saving a dummy record
    private func createInitialSchema() {
        // Create a dummy TodoItem to establish the schema
        let dummyRecord = CKRecord(recordType: todoItemType)
        dummyRecord["text"] = "Schema Setup"
        dummyRecord["isDone"] = false
        dummyRecord["priority"] = 0
        dummyRecord["estimatedDuration"] = ""
        dummyRecord["category"] = ""
        dummyRecord["projectOrPath"] = ""
        dummyRecord["difficulty"] = ""
        dummyRecord["dateCreated"] = Date()
        
        privateDatabase.save(dummyRecord) { _, error in
            if let error = error {
                print("☁️ Schema creation note: \(error)")
            } else {
                print("☁️ Schema initialized successfully")
                // Delete the dummy record
                self.privateDatabase.delete(withRecordID: dummyRecord.recordID) { _, _ in
                    print("☁️ Cleanup complete")
                }
            }
        }
    }
    
    // MARK: - Todo Item Sync
    
    func saveTodoItem(_ item: TodoItem) {
        guard iCloudAvailable else { return }
        
        // Set syncing status
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        let record = CKRecord(
            recordType: todoItemType,
            recordID: CKRecord.ID(recordName: item.id.uuidString)
        )
        
        // Map TodoItem properties to CloudKit record
        record["text"] = item.text
        record["isDone"] = item.isDone
        record["priority"] = item.priority ?? 0
        record["estimatedDuration"] = item.estimatedDuration
        record["category"] = item.category
        record["projectOrPath"] = item.projectOrPath
        record["difficulty"] = item.difficulty?.rawValue
        record["dateCreated"] = item.dateCreated
        record["shortSummary"] = item.shortSummary
        
        privateDatabase.save(record) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Check if it's just a duplicate record error
                    if error.localizedDescription.contains("already exists") {
                        print("☁️ Record already synced (this is OK)")
                        self?.syncStatus = .success
                    } else {
                        self?.syncStatus = .error(error.localizedDescription)
                    }
                } else {
                    self?.syncStatus = .success
                }
                
                // Reset to idle after 2 seconds for success states
                if case .success = self?.syncStatus {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if case .success = self?.syncStatus {
                            self?.syncStatus = .idle
                        }
                    }
                }
            }
        }
    }
    
    func deleteTodoItem(_ item: TodoItem) {
        guard iCloudAvailable else { return }
        
        // Set syncing status
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        let recordID = CKRecord.ID(recordName: item.id.uuidString)
        
        privateDatabase.delete(withRecordID: recordID) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("☁️ Failed to delete item: \(error)")
                    self?.syncStatus = .error(error.localizedDescription)
                } else {
                    print("☁️ Successfully deleted item from CloudKit")
                    self?.syncStatus = .success
                    
                    // Reset to idle after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if case .success = self?.syncStatus {
                            self?.syncStatus = .idle
                        }
                    }
                }
            }
        }
    }
    
    func fetchAllTodoItems(completion: @escaping ([TodoItem]) -> Void) {
        guard iCloudAvailable else { 
            completion([])
            return 
        }
        
        // Use perform query operation which is more flexible
        let query = CKQuery(recordType: todoItemType, predicate: NSPredicate(value: true))
        // Remove sort descriptors to avoid queryable field issues
        // We'll sort locally instead
        
        let operation = CKQueryOperation(query: query)
        operation.recordMatchedBlock = { _, _ in }
        operation.queryResultBlock = { result in
            var items: [TodoItem] = []
            
            switch result {
            case .success(_):
                // Process all matched records
                operation.recordMatchedBlock = { recordID, recordResult in
                    switch recordResult {
                    case .success(let record):
                        if let item = self.todoItemFromRecord(record) {
                            items.append(item)
                        }
                    case .failure(let error):
                        print("☁️ Failed to fetch record: \(error)")
                    }
                }
                
                // Complete with what we have
                DispatchQueue.main.async {
                    // Sort locally by priority
                    let sortedItems = items.sorted { (item1, item2) in
                        let p1 = item1.priority ?? Int.max
                        let p2 = item2.priority ?? Int.max
                        return p1 < p2
                    }
                    completion(sortedItems)
                }
                
            case .failure(let error):
                print("☁️ Query operation failed: \(error)")
                // If it's a schema issue, try without zones
                if error.localizedDescription.contains("Field") {
                    self.fetchAllTodoItemsSimple(completion: completion)
                } else {
                    DispatchQueue.main.async {
                        completion([])
                    }
                }
            }
        }
        
        // Set up the record matched block before adding to database
        var collectedItems: [TodoItem] = []
        operation.recordMatchedBlock = { recordID, recordResult in
            switch recordResult {
            case .success(let record):
                if let item = self.todoItemFromRecord(record) {
                    collectedItems.append(item)
                }
            case .failure(let error):
                print("☁️ Failed to fetch record: \(error)")
            }
        }
        
        operation.queryResultBlock = { result in
            DispatchQueue.main.async {
                // Sort locally by priority
                let sortedItems = collectedItems.sorted { (item1, item2) in
                    let p1 = item1.priority ?? Int.max
                    let p2 = item2.priority ?? Int.max
                    return p1 < p2
                }
                completion(sortedItems)
            }
        }
        
        privateDatabase.add(operation)
    }
    
    // Fallback simple fetch without sorting
    private func fetchAllTodoItemsSimple(completion: @escaping ([TodoItem]) -> Void) {
        print("☁️ Using simple fetch as fallback")
        
        let query = CKQuery(recordType: todoItemType, predicate: NSPredicate(value: true))
        
        privateDatabase.fetch(withQuery: query) { result in
            switch result {
            case .success(let (matchResults, _)):
                let records = matchResults.compactMap { (_, result) in
                    switch result {
                    case .success(let record):
                        return record
                    case .failure:
                        return nil
                    }
                }
                self.handleSimpleQuerySuccess(records: records, completion: completion)
            case .failure(let error):
                print("☁️ Simple query failed: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    private func handleSimpleQuerySuccess(records: [CKRecord], completion: @escaping ([TodoItem]) -> Void) {
        print("☁️ Simple query returned \(records.count) records")
        
        var items: [TodoItem] = []
        for record in records {
            if let item = self.todoItemFromRecord(record) {
                items.append(item)
            }
        }
        
        DispatchQueue.main.async {
            // Sort locally
            let sortedItems = items.sorted { (item1, item2) in
                let p1 = item1.priority ?? Int.max
                let p2 = item2.priority ?? Int.max
                return p1 < p2
            }
            completion(sortedItems)
        }
    }
    
    private func todoItemFromRecord(_ record: CKRecord) -> TodoItem? {
        guard let text = record["text"] as? String,
              let id = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        
        var item = TodoItem(id: id, text: text)
        item.isDone = record["isDone"] as? Bool ?? false
        item.priority = record["priority"] as? Int
        item.estimatedDuration = record["estimatedDuration"] as? String
        item.category = record["category"] as? String
        item.projectOrPath = record["projectOrPath"] as? String
        item.shortSummary = record["shortSummary"] as? String
        if let difficultyRaw = record["difficulty"] as? String {
            item.difficulty = Difficulty(rawValue: difficultyRaw)
        }
        item.dateCreated = record["dateCreated"] as? Date ?? Date()
        
        return item
    }
    
    // MARK: - Subscription for Real-time Updates
    
    func subscribeToChanges() {
        guard iCloudAvailable else { return }
        
        let subscription = CKQuerySubscription(
            recordType: todoItemType,
            predicate: NSPredicate(value: true),
            subscriptionID: "TodoItemChanges",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        
        privateDatabase.save(subscription) { _, error in
            if let error = error {
                print("☁️ Failed to create subscription: \(error)")
            } else {
                print("☁️ Subscription created successfully")
            }
        }
    }
} 