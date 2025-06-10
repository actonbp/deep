import Foundation
import UserNotifications

// Manager for ADHD-focused local notifications
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {
        requestPermission()
    }
    
    // Request notification permission on first launch
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("🔔 Notification permission granted")
                self.scheduleADHDNotifications()
            } else {
                print("🔔 Notification permission denied")
            }
        }
    }
    
    // Schedule ADHD-friendly reminder notifications
    func scheduleADHDNotifications() {
        let center = UNUserNotificationCenter.current()
        
        // Clear existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Morning capture reminder (9 AM daily)
        scheduleDailyNotification(
            id: "morning_capture",
            title: "What's important today? 🌅",
            body: "Take a moment to capture your priorities",
            hour: 9,
            minute: 0
        )
        
        // Afternoon check-in (2 PM daily)
        scheduleDailyNotification(
            id: "afternoon_checkin",
            title: "Quick brain dump 🧠",
            body: "Something on your mind? Add it before it escapes",
            hour: 14,
            minute: 0
        )
        
        // Evening reflection (6 PM daily)
        scheduleDailyNotification(
            id: "evening_reflection",
            title: "How did today go? ✅",
            body: "Celebrate what you completed today",
            hour: 18,
            minute: 0
        )
        
        print("🔔 Scheduled ADHD-focused notifications")
    }
    
    // Helper to schedule daily notifications
    private func scheduleDailyNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Set up daily trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("🔔 Error scheduling notification \(id): \(error)")
            } else {
                print("🔔 Scheduled notification: \(title)")
            }
        }
    }
    
    // Allow users to enable/disable notifications
    func toggleNotifications(enabled: Bool) {
        if enabled {
            scheduleADHDNotifications()
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            print("🔔 Disabled all notifications")
        }
    }
    
    // Check current notification settings
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    print("🔔 Notifications are authorized")
                case .denied:
                    print("🔔 Notifications are denied")
                case .notDetermined:
                    print("🔔 Notification permission not determined")
                    self.requestPermission()
                default:
                    print("🔔 Notification status: \(settings.authorizationStatus)")
                }
            }
        }
    }
}