import SwiftUI

struct SyncStatusView: View {
    @ObservedObject private var cloudKitManager = CloudKitManager.shared
    @State private var showingDetails = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption)
                .foregroundColor(statusColor)
                .animation(.easeInOut, value: cloudKitManager.syncStatus)
            
            Text(statusText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .conditionalGlassBackground(Color.gray, opacity: 0.1, in: Capsule())
        .conditionalGlassEffect(in: Capsule())
        .onTapGesture {
            showingDetails = true
        }
        .alert("Sync Status", isPresented: $showingDetails) {
            Button("OK") { }
        } message: {
            Text(detailMessage)
        }
    }
    
    private var statusIcon: String {
        if !cloudKitManager.iCloudAvailable {
            return "icloud.slash"
        }
        
        switch cloudKitManager.syncStatus {
        case .idle:
            return "icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .success:
            return "icloud.and.arrow.down"
        case .error:
            return "exclamationmark.icloud"
        }
    }
    
    private var statusColor: Color {
        if !cloudKitManager.iCloudAvailable {
            return .gray
        }
        
        switch cloudKitManager.syncStatus {
        case .idle, .success:
            return .green
        case .syncing:
            return .blue
        case .error:
            return .red
        }
    }
    
    private var statusText: String {
        if !cloudKitManager.iCloudAvailable {
            return "Offline"
        }
        
        switch cloudKitManager.syncStatus {
        case .idle:
            return "Synced"
        case .syncing:
            return "Syncing..."
        case .success:
            return "Updated"
        case .error:
            return "Sync Error"
        }
    }
    
    private var detailMessage: String {
        if !cloudKitManager.iCloudAvailable {
            return "iCloud is not available. Your tasks are saved locally only. Sign in to iCloud in Settings to enable sync."
        }
        
        switch cloudKitManager.syncStatus {
        case .idle:
            return "Your tasks are synced with iCloud and available on all your devices."
        case .syncing:
            return "Currently syncing your tasks with iCloud..."
        case .success:
            return "Successfully synced your latest changes to iCloud."
        case .error(let message):
            return "Sync error: \(message)\n\nYour changes are saved locally and will sync when the connection is restored."
        }
    }
}

// Compact version for toolbar
struct SyncStatusToolbarItem: ToolbarContent {
    @ObservedObject private var cloudKitManager = CloudKitManager.shared
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            HStack(spacing: 2) {
                if case .syncing = cloudKitManager.syncStatus {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: iconName)
                        .font(.caption)
                        .foregroundColor(iconColor)
                }
            }
        }
    }
    
    private var iconName: String {
        if !cloudKitManager.iCloudAvailable {
            return "icloud.slash"
        }
        
        switch cloudKitManager.syncStatus {
        case .error:
            return "exclamationmark.icloud"
        default:
            return "icloud"
        }
    }
    
    private var iconColor: Color {
        if !cloudKitManager.iCloudAvailable {
            return .gray
        }
        
        switch cloudKitManager.syncStatus {
        case .error:
            return .red
        default:
            return .green
        }
    }
} 