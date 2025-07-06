import SwiftUI
import GoogleSignInSwift // <-- Import for GIDSignInButton

struct SettingsView: View {
    // Environment variable to dismiss the sheet
    @Environment(\.dismiss) var dismiss
    
    // Use AppStorage to read/write the selected model preference
    // Default to gpt-4o-mini
    @AppStorage(AppSettings.selectedModelKey) var selectedModel: String = AppSettings.gpt4oMini
    
    // AI Agent Manager
    @StateObject private var aiAgentManager = AIAgentManager.shared
    @State private var showingInsights = false
    
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
    // --- NEW: Advanced Manual Editing Settings ---
    @AppStorage(AppSettings.showDurationEditorKey) var showDurationEditor: Bool = false // Default to off
    @AppStorage(AppSettings.showDifficultyEditorKey) var showDifficultyEditor: Bool = false // Default to off
    @AppStorage(AppSettings.advancedRoadmapEditingKey) var advancedRoadmapEditing: Bool = false // Default to off
    // --- NEW: Glass strength setting ---
    @AppStorage(AppSettings.glassStrengthKey) var glassStrengthRaw: String = GlassStrength.regular.rawValue
    
    private var glassStrength: GlassStrength {
        GlassStrength(rawValue: glassStrengthRaw) ?? .regular
    }
    // ---------------------

    // --- Use shared Authentication Service from Environment --- 
    @EnvironmentObject var authService: AuthenticationService 
    // @StateObject private var authService = AuthenticationService() // <-- REMOVED
    // -------------------------------------------------------

    var body: some View {
        NavigationView { // Embed in NavigationView for a title and potential buttons
            Form { // iOS 26 glass-enhanced Form
                
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
                
                // --- NEW: Glass Effect Settings ---
                if #available(iOS 26.0, *) {
                    Section("Liquid Glass Effects") {
                        Picker("Glass Strength", selection: $glassStrengthRaw) {
                            ForEach(GlassStrength.allCases, id: \.self) { strength in
                                VStack(alignment: .leading) {
                                    Text(strength.rawValue)
                                    Text(strength.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(strength.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text("Adjust the visual style of the Liquid Glass interface. Regular provides adaptive tinting, Clear is ultra-transparent for media, and Off uses traditional materials.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                // ----------------------------------
                
                // --- NEW: Advanced Manual Editing Section ---
                Section("Advanced Manual Editing") {
                    Toggle("Show Duration Editor", isOn: $showDurationEditor)
                    Text("Add time picker in task details for manual duration estimates (5min, 15min, 30min, etc.). Complements AI-set durations.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Toggle("Show Difficulty Editor", isOn: $showDifficultyEditor)
                    Text("Add difficulty picker in task details (Low/Medium/High). Useful for manual cognitive load planning.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Toggle("Advanced Roadmap Editing", isOn: $advancedRoadmapEditing)
                    Text("Enable project information editing, task reordering, and advanced roadmap management features.")
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
                
                Section("AI Agent Mode (NEW!) 🤖") {
                    Toggle("Enable AI Agent Mode", isOn: $aiAgentManager.isEnabled)
                        .onChange(of: aiAgentManager.isEnabled) { _, newValue in
                            if newValue {
                                aiAgentManager.enableAIAgentMode()
                            } else {
                                aiAgentManager.disableAIAgentMode()
                            }
                        }
                    
                    if aiAgentManager.isEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("✨ AI Time-Blocking Coach will:")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text("• Add realistic time estimates (with ADHD buffer)\n• Assess cognitive load and energy requirements\n• Suggest optimal scheduling based on context switching\n• Break down overwhelming tasks into manageable steps\n• Provide time-blocking strategies and quick wins\n• Generate comprehensive productivity insights")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            if let lastDate = aiAgentManager.lastProcessingDate {
                                HStack {
                                    Text("Last processed: \(lastDate.formatted(.relative(presentation: .named)))")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                    
                                    if !aiAgentManager.latestInsights.isEmpty {
                                        Button("View Analysis") {
                                            showingInsights = true
                                        }
                                        .font(.caption2)
                                        .buttonStyle(.borderless)
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            #if DEBUG
                            Button("Test Time-Blocking Analysis (Debug)") {
                                Task {
                                    await aiAgentManager.processNow()
                                }
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            #endif
                        }
                    }
                    
                    Text("Your AI time-blocking coach analyzes tasks with ADHD-specific insights: realistic time estimates, energy management, context switching costs, and optimal scheduling. Works entirely on-device!")
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
            .conditionalFormStyle() // iOS 26 glass form styling
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss() // Dismiss the sheet
                    }
                }
            }
            .sheet(isPresented: $showingInsights) {
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if !aiAgentManager.latestInsights.isEmpty {
                                Text(aiAgentManager.latestInsights)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .textSelection(.enabled)
                            } else {
                                Text("No analysis available yet. Try running the 'Test Now' button to generate insights.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("AI Time-Blocking Analysis")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingInsights = false
                            }
                        }
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