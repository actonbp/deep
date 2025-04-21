import SwiftUI
import GoogleSignIn

@main
struct deep_appApp: App {
    
    init() {
        configureGoogleSignIn()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
    
    private func configureGoogleSignIn() {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            fatalError("Could not find GIDClientID in Info.plist. Check configuration.")
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                print("Error restoring previous sign-in: \(error.localizedDescription)")
            } else if let user = user {
                print("Successfully restored previous sign-in for \(user.profile?.name ?? "User")")
            } else {
                print("No previous sign-in found.")
            }
        }
    }
} 