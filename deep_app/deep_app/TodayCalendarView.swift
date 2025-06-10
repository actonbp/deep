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
    
    // State for day navigation (0 = today, 1 = tomorrow, 2 = day after tomorrow)
    @State private var currentDayOffset: Int = 0
    @State private var dragOffset: CGFloat = 0

    // --- Timeline Configuration ---
    let startHour = 7 // 7 AM
    let endHour = 23 // 11 PM (inclusive range for drawing last line)
    let hourHeight: CGFloat = 60 // Height per hour block
    // ---------------------------

    // Consistent title styling
    let titleFontSize: CGFloat = 22 
    let sciFiFont = "Orbitron"
    
    @ViewBuilder
    private var signedInContent: some View {
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
                        // --- Modern Timeline View ---
                        VStack(spacing: 0) {
                            // Date Header with Navigation
                            VStack(spacing: 8) {
                                HStack {
                                    Text(dayLabel())
                                        .font(.system(.title3, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.theme.titleText)
                                    Spacer()
                                }
                                
                                // Day Navigation Indicators
                                HStack(spacing: 12) {
                                    ForEach(0..<3, id: \.self) { dayIndex in
                                        Circle()
                                            .fill(currentDayOffset == dayIndex ? Color("Indigo500") : Color.gray.opacity(0.3))
                                            .frame(width: 8, height: 8)
                                            .animation(.spring(response: 0.3), value: currentDayOffset)
                                    }
                                    Spacer()
                                    
                                    if currentDayOffset > 0 {
                                        Button("Today") {
                                            withAnimation(.spring(response: 0.4)) {
                                                currentDayOffset = 0
                                            }
                                        }
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(Color("Indigo500"))
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                            
                            // Timeline with Swipe Gesture
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(startHour..<endHour, id: \.self) { hour in
                                        TimeSlotView(
                                            hour: hour,
                                            events: eventsForHour(hour),
                                            hourHeight: hourHeight
                                        )
                                    }
                                }
                                .padding(.horizontal)
                                .offset(x: dragOffset)
                                .animation(.spring(response: 0.3), value: dragOffset)
                            }
                            .refreshable { loadEvents() }
                            .gesture(
                                DragGesture(minimumDistance: 20)
                                    .onChanged { value in
                                        // Only respond to mostly horizontal swipes
                                        if abs(value.translation.width) > abs(value.translation.height) {
                                            dragOffset = max(-50, min(50, value.translation.width * 0.5))
                                        }
                                    }
                                    .onEnded { value in
                                        let threshold: CGFloat = 80
                                        
                                        // Only process if it's a horizontal swipe
                                        guard abs(value.translation.width) > abs(value.translation.height) else {
                                            withAnimation(.spring(response: 0.3)) {
                                                dragOffset = 0
                                            }
                                            return
                                        }
                                        
                                        if value.translation.width > threshold {
                                            // Swiped right - go to previous day
                                            if currentDayOffset > 0 {
                                                withAnimation(.spring(response: 0.4)) {
                                                    currentDayOffset -= 1
                                                    dragOffset = 0
                                                }
                                            } else {
                                                withAnimation(.spring(response: 0.3)) {
                                                    dragOffset = 0
                                                }
                                            }
                                        } else if value.translation.width < -threshold {
                                            // Swiped left - go to next day
                                            if currentDayOffset < 2 {
                                                withAnimation(.spring(response: 0.4)) {
                                                    currentDayOffset += 1
                                                    dragOffset = 0
                                                }
                                            } else {
                                                withAnimation(.spring(response: 0.3)) {
                                                    dragOffset = 0
                                                }
                                            }
                                        } else {
                                            // Not enough swipe distance - snap back
                                            withAnimation(.spring(response: 0.3)) {
                                                dragOffset = 0
                                            }
                                        }
                                    }
                            )
                        }
                        // ---------------------
        }
    }
    
    var body: some View {
        NavigationView { // For title and potential future toolbar items
            VStack {
                if authService.isSignedIn {
                    signedInContent
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
            .background(Color.white.ignoresSafeArea())
            .navigationTitle(navigationTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Calendar")
                        .font(.custom(sciFiFont, size: titleFontSize))
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.titleText)
                }
            }
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
            // --- React to day offset changes ---
            .onChange(of: currentDayOffset) { oldValue, newValue in
                if oldValue != newValue {
                    loadEvents()
                }
            }
            // -----------------------------------------
            // Optional: Add a refresh button later
            // --- Apply background color and ensure visibility --- 
            .toolbarBackground(.indigo, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar) // Keep this to suggest light status bar items
            // -----------------------------------------------------
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
    
    // Helper functions for the modern calendar view
    private func currentDisplayDate() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: currentDayOffset, to: Date()) ?? Date()
    }
    
    private func dayLabel() -> String {
        let date = currentDisplayDate()
        let formatter = DateFormatter()
        
        if currentDayOffset == 0 {
            formatter.dateFormat = "MMMM d, yyyy"
            return "Today • \(formatter.string(from: date))"
        } else if currentDayOffset == 1 {
            formatter.dateFormat = "MMMM d, yyyy"
            return "Tomorrow • \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "EEEE • MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: currentDisplayDate())
    }
    
    private func navigationTitle() -> String {
        switch currentDayOffset {
        case 0: return "Today's Calendar"
        case 1: return "Tomorrow's Calendar"
        default: return "Calendar"
        }
    }
    
    private func eventsForHour(_ hour: Int) -> [CalendarEvent] {
        return events.filter { event in
            guard let startDate = event.startDate else { return false }
            let calendar = Calendar.current
            let eventHour = calendar.component(.hour, from: startDate)
            return eventHour == hour
        }
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
        
        calendarService.fetchEventsForDate(date: currentDisplayDate()) { fetchedEvents, error in
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

// --- Modern Time Slot View ---
struct TimeSlotView: View {
    let hour: Int
    let events: [CalendarEvent]
    let hourHeight: CGFloat
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Time Label
            Text(hourLabel(hour))
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(Color.theme.secondaryText)
                .frame(width: 60, alignment: .trailing)
            
            // Event Content Area
            VStack(spacing: 8) {
                if events.isEmpty {
                    // Empty time slot
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: max(hourHeight - 16, 44))
                        .overlay(
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 1),
                            alignment: .top
                        )
                } else {
                    // Events for this hour
                    ForEach(events) { event in
                        ModernEventBlockView(event: event)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
    
    private func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        if let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) {
            return formatter.string(from: date)
        } else {
            return "\(hour):00"
        }
    }
}

// --- Modern Event Block View ---
struct ModernEventBlockView: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Color accent bar
            Rectangle()
                .fill(eventColor)
                .frame(width: 4)
                .cornerRadius(2)
            
            // Event content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.summary ?? "(No Title)")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(Color.theme.titleText)
                    .lineLimit(2)
                
                if let startDate = event.startDate, let endDate = event.endDate {
                    Text("\(timeString(from: startDate)) • \(durationString(from: startDate, to: endDate))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color.theme.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(eventBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var eventColor: Color {
        // Use different colors based on event characteristics
        if let summary = event.summary?.lowercased() {
            if summary.contains("meeting") || summary.contains("standup") {
                return Color("Indigo500")
            } else if summary.contains("suggested") || summary.contains("task") {
                return Color.gray
            }
        }
        return Color("Indigo500")
    }
    
    private var eventBackgroundColor: Color {
        if let summary = event.summary?.lowercased() {
            if summary.contains("meeting") || summary.contains("standup") {
                return Color("Indigo500").opacity(0.15)
            } else if summary.contains("suggested") || summary.contains("task") {
                return Color("Gray50")
            }
        }
        return Color("Indigo500").opacity(0.15)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func durationString(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}
// -------------------------------


#Preview {
    // Provide a dummy service for the preview
    TodayCalendarView()
        .environmentObject(AuthenticationService())
} 