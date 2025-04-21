import SwiftUI
import GoogleSignInSwift // <-- Import for GIDSignInButton

// Define the available models
struct AppSettings {
    // Use constants for model names to avoid typos
    static let gpt4oMini = "gpt-4o-mini"
    static let gpt4o = "gpt-4o"
    
    static let availableModels = [gpt4oMini, gpt4o]
    
    // Key for UserDefaults
    static let selectedModelKey = "selectedApiModel"
    static let debugLogEnabledKey = "debugLogEnabled"
}

struct SettingsView: View {
    // Environment variable to dismiss the sheet
    @Environment(\.dismiss) var dismiss
    
    // Use AppStorage to read/write the selected model preference
    // Default to gpt-4o-mini
    @AppStorage(AppSettings.selectedModelKey) var selectedModel: String = AppSettings.gpt4oMini
    
    // Add AppStorage for debug logging toggle
    @AppStorage(AppSettings.debugLogEnabledKey) var isDebugLoggingEnabled: Bool = false // Default to off
    
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
                    // Optional: Add description about models
                    Text("gpt-4o-mini is faster and cheaper. gpt-4o is more powerful.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section("Debugging") { // New section for debug settings
                    Toggle("Enable Debug Logging", isOn: $isDebugLoggingEnabled)
                    Text("Shows detailed logs in the Xcode console. May slightly impact performance when debugger is attached.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
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