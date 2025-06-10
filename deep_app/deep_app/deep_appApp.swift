//
//  deep_appApp.swift
//  deep_app
//
//  Created by bacton on 4/15/25.
//

import SwiftUI

@main
struct deep_appApp: App {
    // Initialize notification manager
    private let notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Check notification status when app launches
                    notificationManager.checkNotificationStatus()
                }
        }
    }
}
