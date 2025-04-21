import SwiftUI

struct TodayCalendarView: View {
    // --- Use shared Authentication Service from Environment --- 
    @EnvironmentObject var authService: AuthenticationService
    // @StateObject private var authService = AuthenticationService() // <-- REMOVED
    // -------------------------------------------------------
    private let calendarService = CalendarService()
    
    // State for the calendar events and loading/error status
    @State private var events: [CalendarEvent] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView { // For title and potential future toolbar items
            VStack {
                if authService.isSignedIn {
                    // User is signed in, show events or loading/error state
                    if isLoading {
                        ProgressView("Loading today's events...")
                    } else if let errorMsg = errorMessage {
                        Text("Error loading calendar: \(errorMsg)")
                            .foregroundColor(.red)
                            .padding()
                    } else if events.isEmpty {
                        Text("No events scheduled for today.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        // Display the list of events
                        List(events) { event in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.startTimeString)
                                    Text("   to \(event.endTimeString)") // Indent slightly
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 90, alignment: .leading) // Fixed width for times
                                
                                Text(event.summary ?? "(No Title)")
                                    .fontWeight(.medium)
                                
                                Spacer() // Push content to left
                            }
                            .padding(.vertical, 4)
                        }
                        .listStyle(PlainListStyle())
                    }
                } else {
                    // User is not signed in
                    VStack {
                        Text("Please sign in with Google to view your calendar.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding()
                        Button("Go to Settings") {
                            // Need a way to switch tabs programmatically or guide user
                            print("TODO: Guide user to Settings tab")
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Today's Calendar")
            .onAppear(perform: loadEvents) // Load events when view appears first time
            // --- React to sign-in status changes --- 
            .onChange(of: authService.isSignedIn) { _, isSignedIn in
                if isSignedIn {
                    // User just signed in, load events
                    loadEvents()
                } else {
                    // User just signed out, clear events and error
                    self.events = []
                    self.errorMessage = nil
                }
            }
            // -----------------------------------------
            // Optional: Add a refresh button later
        }
    }
    
    // Function to load events from the service
    private func loadEvents() {
        guard authService.isSignedIn else {
            print("TodayCalendarView: Cannot load events, user not signed in.")
            self.events = [] // Clear events if user signs out
            self.isLoading = false
            self.errorMessage = nil
            return
        }
        
        guard !isLoading else { return } // Prevent multiple simultaneous loads
        
        print("TodayCalendarView: Starting to load events...")
        self.isLoading = true
        self.errorMessage = nil
        
        calendarService.fetchTodaysEvents { fetchedEvents, error in
            // Ensure UI updates are on the main thread
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("TodayCalendarView: Error loading events: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.events = [] // Clear events on error
                } else {
                    print("TodayCalendarView: Successfully loaded \(fetchedEvents?.count ?? 0) events.")
                    self.events = fetchedEvents ?? []
                    self.errorMessage = nil // Clear any previous error
                }
            }
        }
    }
}

#Preview {
    // Provide a dummy service for the preview
    TodayCalendarView()
        .environmentObject(AuthenticationService())
} 