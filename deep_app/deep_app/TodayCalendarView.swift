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

    // --- Timeline Configuration ---
    let startHour = 7 // 7 AM
    let endHour = 23 // 11 PM (inclusive range for drawing last line)
    let hourHeight: CGFloat = 60 // Height per hour block
    // ---------------------------

    var body: some View {
        NavigationView { // For title and potential future toolbar items
            VStack {
                if authService.isSignedIn {
                    // User is signed in, show events or loading/error state
                    if isLoading {
                        ProgressView("Loading today's events...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMsg = errorMessage {
                        VStack { // Wrap error message for better layout
                            Text("Error loading calendar: \(errorMsg)")
                                .foregroundColor(.red)
                                .padding()
                            Button("Retry") { loadEvents() } // Add retry button
                                .buttonStyle(.bordered)
                        }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if events.isEmpty {
                        Text("No events scheduled for today.")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .refreshable { loadEvents() } // Allow refresh even when empty
                    } else {
                        // --- Timeline View --- 
                        GeometryReader { geometry in
                            ScrollView {
                                ZStack(alignment: .topLeading) {
                                    TimelineBackground(startHour: startHour, endHour: endHour, hourHeight: hourHeight)
                                    
                                    // --- Draw Event Blocks ---
                                    ForEach(events) { event in
                                        // Skip events without a start date for positioning
                                        if let startDate = event.startDate {
                                            EventBlockView(event: event)
                                                .frame(height: height(for: event))
                                                .offset(x: 60, y: yOffset(for: startDate)) // Offset X to align past hour labels
                                                .padding(.trailing, 10) // Add some trailing padding
                                        }
                                    }
                                    // ------------------------
                                }
                                .frame(width: geometry.size.width)
                            }
                        }
                        .refreshable { loadEvents() } // Add pull-to-refresh to ScrollView
                        // ---------------------
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
    
    // --- Timeline Calculation Helpers ---
    private func yOffset(for date: Date?) -> CGFloat {
        guard let date = date else { return 0 } // Don't draw if no date
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        // Calculate position relative to the start hour
        let minutesFromStart = CGFloat((hour - startHour) * 60 + minute)
        
        // Ensure event is within the timeline bounds (clamp position)
        let totalMinutesInTimeline = CGFloat((endHour - startHour) * 60)
        let clampedMinutes = max(0, min(minutesFromStart, totalMinutesInTimeline))
        
        return (clampedMinutes / 60.0) * hourHeight
    }

    private func height(for event: CalendarEvent) -> CGFloat {
        guard let start = event.startDate, let end = event.endDate else { return hourHeight } // Default height if dates are missing
        
        let durationInMinutes = end.timeIntervalSince(start) / 60
        
        // Clamp duration to fit within timeline if necessary (e.g., event ends after 11 PM)
        let calendar = Calendar.current
        let startHourComponent = calendar.component(.hour, from: start)
        let startMinuteComponent = calendar.component(.minute, from: start)
        let minutesFromTimelineStart = CGFloat((startHourComponent - startHour) * 60 + startMinuteComponent)
        
        let totalMinutesInTimeline = CGFloat((endHour - startHour) * 60)
        let availableMinutes = totalMinutesInTimeline - max(0, minutesFromTimelineStart) // Max prevents negative if event starts before timeline
        
        let clampedDuration = max(15, min(CGFloat(durationInMinutes), availableMinutes)) // Ensure minimum height (e.g., 15 mins worth)
        
        return (clampedDuration / 60.0) * hourHeight
    }
    // ----------------------------------

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
                    
                    // --- Add Debugging for Parsed Dates ---
                    if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                        print("DEBUG [CalendarView Load]: Checking parsed start dates for loaded events:")
                        if self.events.isEmpty {
                            print("    (No events to check)")
                        } else {
                            for event in self.events {
                                let summary = event.summary ?? "(Nil Summary)"
                                let parsedDateStatus = event.startDate != nil ? "Successfully Parsed (\(event.startDate!))" : "Parsing FAILED (startDate is nil)"
                                print("    - \"\(summary)\": \(parsedDateStatus)")
                            }
                        }
                    }
                    // ---------------------------------------
                }
            }
        }
    }
}

// --- Timeline Background View ---
struct TimelineBackground: View {
    let startHour: Int
    let endHour: Int
    let hourHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 5) {
                    // Hour Label
                    Text(hourLabel(hour))
                        .font(.caption)
                        .foregroundColor(Color.theme.secondaryText)
                        .frame(width: 50, alignment: .trailing) // Fixed width for labels
                        
                    // Horizontal Line
                    Rectangle()
                        .fill(Color.theme.secondaryText.opacity(0.3))
                        .frame(height: 1)
                }
                .frame(height: hourHeight) // Set height for the hour block
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a" // Format like "7 AM", "1 PM"
        if let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) {
            return formatter.string(from: date)
        } else {
            return "\(hour):00" // Fallback
        }
    }
}
// -------------------------------

// --- View for a Single Event Block ---
struct EventBlockView: View {
    let event: CalendarEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.summary ?? "(No Title)")
                .font(.footnote)
                .fontWeight(.semibold)
            // Optionally add start/end time within the block if space permits
            // Text("\(event.startTimeString) - \(event.endTimeString)").font(.caption2)
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading) // Take available width
        .background(Color.blue.opacity(0.7)) // Example background
        .foregroundColor(.white)
        .cornerRadius(4)
        .clipped() // Prevent text overflow
    }
}
// ----------------------------------

#Preview {
    // Provide a dummy service for the preview
    TodayCalendarView()
        .environmentObject(AuthenticationService())
} 