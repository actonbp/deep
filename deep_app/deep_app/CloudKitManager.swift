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
    
    enum SyncStatus {
        case idle
        case syncing
        case error(String)
        case success
    }
    
    private init() {
        // Use your app's CloudKit container
        container = CKContainer(identifier: "iCloud.com.bryanacton.deep")
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
            case .failure(let error):
                print("☁️ Failed to create zones: \(error)")
            }
        }
        
        privateDatabase.add(operation)
    }
    
    // MARK: - Todo Item Sync
    
    func saveTodoItem(_ item: TodoItem) {
        guard iCloudAvailable else { return }
        
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
        record["createdAt"] = item.createdAt
        
        privateDatabase.save(record) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncStatus = .error(error.localizedDescription)
                } else {
                    self?.syncStatus = .success
                }
            }
        }
    }
    
    func fetchAllTodoItems(completion: @escaping ([TodoItem]) -> Void) {
        guard iCloudAvailable else { 
            completion([])
            return 
        }
        
        let query = CKQuery(recordType: todoItemType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: true)]
        
        privateDatabase.fetch(withQuery: query) { result in
            switch result {
            case .success(let matchResults):
                var items: [TodoItem] = []
                
                for (_, recordResult) in matchResults.matchResults {
                    switch recordResult {
                    case .success(let record):
                        if let item = self.todoItemFromRecord(record) {
                            items.append(item)
                        }
                    case .failure(let error):
                        print("☁️ Failed to fetch record: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    completion(items)
                }
                
            case .failure(let error):
                print("☁️ Query failed: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
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
        if let difficultyRaw = record["difficulty"] as? String {
            item.difficulty = Difficulty(rawValue: difficultyRaw)
        }
        item.createdAt = record["createdAt"] as? Date ?? Date()
        
        return item
    }
    
    // MARK: - Subscription for Real-time Updates
    
    func subscribeToChanges() {
        guard iCloudAvailable else { return }
        
        let subscription = CKQuerySubscription(
            recordType: todoItemType,
            predicate: NSPredicate(value: true),
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