import SwiftUI
import GoogleSignInSwift // <-- Import for GIDSignInButton

// Define the available models
struct AppSettings {
    // Use constants for model names to avoid typos
    static let gpt4oMini = "gpt-4o-mini"
    static let gpt4o = "gpt-4o"
    static let o3 = "o3"
    
    static let availableModels = [gpt4oMini, gpt4o, o3]
    
    // Key for UserDefaults
    static let selectedModelKey = "selectedApiModel"
    static let debugLogEnabledKey = "debugLogEnabled"
    static let demonstrationModeEnabledKey = "demonstrationModeEnabled"
    // --- ADDED Key ---
    static let enableCategoriesKey = "enableCategories"
    // --- NEW Key: toggle for future on-device model ---
    static let useLocalModelKey = "useLocalModel"
    // --------------------------------------------------
}

struct SettingsView: View {
    // Environment variable to dismiss the sheet
    @Environment(\.dismiss) var dismiss
    
    // Use AppStorage to read/write the selected model preference
    // Default to gpt-4o-mini
    @AppStorage(AppSettings.selectedModelKey) var selectedModel: String = AppSettings.gpt4oMini
    
    // Add AppStorage for debug logging toggle
    @AppStorage(AppSettings.debugLogEnabledKey) var isDebugLoggingEnabled: Bool = false // Default to off
    
    // --- ADDED Setting --- 
    @AppStorage(AppSettings.demonstrationModeEnabledKey) var isDemonstrationModeEnabled: Bool = false // Default to off
    // ---------------------
    // --- ADDED Setting --- 
    @AppStorage(AppSettings.enableCategoriesKey) var areCategoriesEnabled: Bool = false // Default to off
    // Toggle for future local LLM mode (placeholder)
    @AppStorage(AppSettings.useLocalModelKey) var useLocalModel: Bool = false // Default to off
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true // Default to on
    @AppStorage("healthKitEnabled") var healthKitEnabled: Bool = false // Default to off
    // ---------------------

    // --- Use shared Authentication Service from Environment --- 
    @EnvironmentObject var authService: AuthenticationService 
    // @StateObject private var authService = AuthenticationService() // <-- REMOVED
    // -------------------------------------------------------

    var body: some View {
        NavigationView { // Embed in NavigationView for a title and potential buttons
            Form { // Use a Form for standard settings layout
                
                // --- NEW: Google Account Section --- 
                Section("Google Account") {
                    if authService.isSignedIn {
                        // User is signed in - show info and sign out button
                        VStack(alignment: .leading) {
                            Text("Signed in as:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(authService.user?.profile?.name ?? "(Name not available)")
                            Text(authService.user?.profile?.email ?? "(Email not available)")
                                .font(.callout)
                        }
                        
                        Button("Sign Out", role: .destructive) {
                            authService.signOut()
                        }
                        
                    } else {
                        // User is not signed in - show sign in button
                        Text("Connect your Google Calendar to see today's events.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // Replace GIDSignInButton with a standard SwiftUI Button
                        Button {
                            authService.signIn()
                        } label: {
                            // Simple text label for now
                            Text("Sign in with Google")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6)) // Basic background
                                .foregroundColor(Color.primary) // Default text color
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain) // Use plain style to allow custom background
                        
                    }
                }
                // ------------------------------------
                
                Section("AI Model") {
                    // Picker to select the model
                    Picker("Selected Model", selection: $selectedModel) {
                        ForEach(AppSettings.availableModels, id: \.self) { modelName in
                            Text(modelName).tag(modelName) // Use model name as both text and tag
                        }
                    }
                    .disabled(useLocalModel) // Disable when using local model
                    
                    // Optional: Add description about models
                    if useLocalModel {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚠️ OpenAI models are disabled while using on-device model below.")
                                .font(.caption)
                                .foregroundColor(.orange)
                            if selectedModel == AppSettings.o3 {
                                Text("💡 For O3's advanced reasoning (5-min thinking time), turn OFF on-device model.")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        Text("gpt-4o-mini: Fast and economical. gpt-4o: More powerful. o3: Advanced reasoning model.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Section("Debugging") { // New section for debug settings
                    Toggle("Enable Debug Logging", isOn: $isDebugLoggingEnabled)
                    Text("Shows detailed logs in the Xcode console. May slightly impact performance when debugger is attached.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // --- Roadmap Settings Section --- 
                Section("Roadmap Customization") {
                    Toggle("Enable Categories", isOn: $areCategoriesEnabled)
                    Text("Group roadmap items by category (e.g., Research, Teaching) in addition to specific projects/paths. If off, all projects/paths appear together.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                // -----------------------------
                
                Section("Notifications") {
                    Toggle("ADHD Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            NotificationManager.shared.toggleNotifications(enabled: newValue)
                        }
                    Text("Gentle reminders to capture thoughts and check in with your tasks. Scheduled at 9 AM, 2 PM, and 6 PM daily.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section("Health Integration (Preview)") {
                    Toggle("Enable HealthKit", isOn: $healthKitEnabled)
                        .onChange(of: healthKitEnabled) { _, newValue in
                            if newValue {
                                // Request HealthKit permissions when enabled
                                Task {
                                    if #available(iOS 13.0, *) {
                                        let healthService = HealthKitService.shared
                                        let authorized = await healthService.requestAuthorization()
                                        if !authorized {
                                            // If authorization failed, turn the toggle back off
                                            await MainActor.run {
                                                healthKitEnabled = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    Text("Connect Apple Health for ADHD-specific insights based on sleep, activity, and heart rate. This is a basic connection - full health dashboard coming soon!")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section("Demonstration") {
                    Toggle("Enable Demo Mode", isOn: $isDemonstrationModeEnabled)
                    Text("Shows sample tasks and roadmap data for illustration purposes. Your actual data is preserved and will reappear when Demo Mode is turned off.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // --- NEW: Local Model Preview Section ---
                Section("On-Device AI (Preview)") {
                    Toggle("Use On-Device Model (Free)", isOn: $useLocalModel)
                    Text("When enabled, Bryan's Brain will run the assistant entirely on your device using Apple's upcoming Foundation Models. This is a **preview toggle** – no functional change yet, but stay tuned!")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                // ----------------------------------------
                
                Section("About") {
                    Text("App Version: 1.0.0") // Example
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss() // Dismiss the sheet
                    }
                }
            }
        }
    }
}

#Preview {
    // Provide a dummy service for the preview
    SettingsView()
        .environmentObject(AuthenticationService())
} 