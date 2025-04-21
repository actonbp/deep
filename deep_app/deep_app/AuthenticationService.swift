import SwiftUI
import GoogleSignIn

// Service to manage Google Sign-In state and actions
final class AuthenticationService: ObservableObject {
    
    @Published var user: GIDGoogleUser? // Holds the signed-in user object
    
    // TODO: Potentially add other published properties like derived isSignedIn bool
    var isSignedIn: Bool { // Computed property based on user
        user != nil
    }

    init() {
        // Attempt to restore any previous sign-in when the service is initialized
        restorePreviousSignIn()
    }
    
    // MARK: - Public Methods
    
    func signIn() {
        print("AuthenticationService: Attempting sign in...")
        
        // 1. Get the presenting view controller
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            print("AuthenticationService: ERROR - Could not find root view controller.")
            // TODO: Handle this error more gracefully, maybe show an alert to the user
            return
        }
        
        // 2. Define the necessary scopes
        // Request read/write access to calendar events
        let calendarScope = "https://www.googleapis.com/auth/calendar.events"
        
        // 3. Start the sign-in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController, hint: nil, additionalScopes: [calendarScope]) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("AuthenticationService: ERROR during sign in: \(error.localizedDescription)")
                // Ensure user is nil on error
                self.user = nil
                // TODO: Handle error (e.g., show alert)
                return
            }
            
            guard let result = result else {
                print("AuthenticationService: ERROR - GIDSignInResult was nil.")
                // Ensure user is nil
                self.user = nil
                // TODO: Handle error
                return
            }
            
            // Sign-in successful
            print("AuthenticationService: Sign in successful for \(result.user.profile?.name ?? "User")")
            self.user = result.user
            
            // You can access granted scopes via result.user.grantedScopes
            if let grantedScopes = result.user.grantedScopes, grantedScopes.contains(calendarScope) {
                print("AuthenticationService: Calendar read/write scope was granted.")
            } else {
                print("AuthenticationService: WARNING - Calendar read/write scope was NOT granted.")
                // Handle cases where the user denied specific permissions if necessary
            }
        }
    }
    
    func signOut() {
        print("AuthenticationService: Signing out...")
        GIDSignIn.sharedInstance.signOut()
        // Update the user state after signing out
        self.user = nil 
    }
    
    // MARK: - Private Helpers

    private func restorePreviousSignIn() {
        print("AuthenticationService: Attempting to restore previous sign in...")
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            if let error = error {
                print("AuthenticationService: Error restoring previous sign-in: \(error.localizedDescription)")
                // Ensure user state is nil on error
                self?.user = nil
                return
            }
            
            guard let user = user else {
                print("AuthenticationService: No previous sign-in found.")
                // Ensure user state is nil
                self?.user = nil
                return
            }
            
            print("AuthenticationService: Successfully restored sign-in for \(user.profile?.name ?? "User")")
            // Update the published property
            self?.user = user
        }
    }
} 