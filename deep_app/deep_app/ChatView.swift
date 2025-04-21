import SwiftUI
import GoogleSignInSwift // Needed for SettingsView presentation if that code is still here

// Define the structure for a To-Do item (Moved from ContentView)
// If this is used elsewhere, consider a dedicated Models file
// struct TodoItem: Identifiable, Codable { ... } // Assuming TodoItem is defined elsewhere now

// Main View hosting the TabView (Moved to ContentView.swift)
// struct ContentView: View { ... }

// --- Restored ChatView Definition ---
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSettingsSheet = false // State to control settings sheet
    @State private var showScrollToBottomButton = false // <-- State for button visibility
    // let sciFiFont = "Orbitron" // Font only used for title now
    // let bodyFontSize: CGFloat = 15 // No longer needed
    
    // Reference to the theme font for the title
    let sciFiFont = "Orbitron" // Keep for title
    let titleFontSize: CGFloat = 22 // Keep for title

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // --- Wrap ScrollViewReader content in ZStack for overlay ---
                ZStack(alignment: .bottomTrailing) { // Align overlay to bottom trailing
                    ScrollViewReader { scrollView in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                // Filter out system, tool messages, AND assistant messages that ONLY contain tool calls w/o content
                                ForEach(viewModel.messages.filter { $0.role != .system && $0.role != .tool && !($0.role == .assistant && $0.toolCalls != nil && ($0.content ?? "").isEmpty) }) { message in
                                    MessageBubble(message: message)
                                        // --- Track visibility of the LAST message --- 
                                        .if(message.id == viewModel.messages.last(where: { $0.role != .system && $0.role != .tool && !($0.role == .assistant && $0.toolCalls != nil && ($0.content ?? "").isEmpty) })?.id) { view in
                                            view.onAppear { showScrollToBottomButton = false }
                                               .onDisappear { showScrollToBottomButton = true }
                                        }
                                        // ---------------------------------------------
                                }
                                
                                // Loading indicator when waiting for API response
                                if viewModel.isLoading {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .tint(.gray)
                                        Text("...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id("loading")
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 6)
                        .padding(.top, 4)
                        .onTapGesture { // Add tap gesture to dismiss keyboard
                            hideKeyboard()
                        }
                        .onChange(of: viewModel.messages.count) { oldCount, newCount in
                            // Scroll to bottom when messages change
                            // Get the ID of the actual last message to display
                            let lastVisibleMessageId = viewModel.messages.last(where: { $0.role != .system && $0.role != .tool && !($0.role == .assistant && $0.toolCalls != nil && ($0.content ?? "").isEmpty) })?.id

                            withAnimation {
                                if let lastId = lastVisibleMessageId {
                                    scrollView.scrollTo(lastId, anchor: .bottom)
                                    showScrollToBottomButton = false // Hide button when auto-scrolling
                                } else if viewModel.isLoading {
                                    scrollView.scrollTo("loading", anchor: .bottom)
                                    showScrollToBottomButton = false // Hide button when auto-scrolling
                                }
                            }
                        }
                        
                        // --- Scroll To Bottom Button (Moved INSIDE ScrollViewReader) --- 
                        if showScrollToBottomButton {
                            Button {
                                // Get the ID of the actual last message to display
                                let lastVisibleMessageId = viewModel.messages.last(where: { $0.role != .system && $0.role != .tool && !($0.role == .assistant && $0.toolCalls != nil && ($0.content ?? "").isEmpty) })?.id
                                if let lastId = lastVisibleMessageId {
                                    withAnimation {
                                        scrollView.scrollTo(lastId, anchor: .bottom)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title)
                                    .padding(12)
                                    .background(.thinMaterial) // Use material background
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            .padding(.trailing) // Padding from edge
                            .padding(.bottom, 10) // Padding from input bar
                            .transition(.scale.combined(with: .opacity)) // Nice transition
                        }
                        // -------------------------------------------------------------
                    } // <-- End ScrollViewReader
                }
                // --- End ZStack ---
                
                // --- Suggested Prompts --- 
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.suggestedPrompts, id: \.self) { prompt in
                            Text(prompt)
                                .font(.caption) // Use system font
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5)) // Use system color
                                .clipShape(Capsule())
                                .foregroundColor(Color(.label)) // Use system color
                                .lineLimit(1) // Prevent wrapping
                                .onTapGesture { viewModel.newMessageText = prompt }
                        }
                    }
                    .padding(.horizontal) // Padding for the HStack
                    .padding(.bottom, 6) // Space below prompts
                }
                // -------------------------
                
                // Input area at bottom
                HStack {
                    // Message input field
                    TextField("Message Bryan's Brain...", text: $viewModel.newMessageText)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .textFieldStyle(.plain)
                        .padding(.leading)
                        // Removed custom font
                        .foregroundColor(Color.theme.text) // Keep theme color for now, might change later
                        // Use AttributedString for placeholder color if needed
                    
                    // Send button
                    Button {
                        Task {
                            await viewModel.processUserInput() 
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color.theme.accent) // Use theme accent
                    }
                    .disabled(viewModel.newMessageText.isEmpty || viewModel.isLoading)
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground)) // Use system background (adapts light/dark)
                // Optional: Add a subtle top border
                .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color(UIColor.systemGray4)), alignment: .top)
            }
            // Title and toolbar setup
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(Color.theme.background.ignoresSafeArea()) // Keep theme color for now
            .foregroundColor(Color.theme.text) // Keep theme color for now
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Bryan's Brain")
                        .font(.custom(sciFiFont, size: titleFontSize))
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.titleText) // Use theme title color
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color.theme.accent) // Keep theme accent
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                // Provide environment object if SettingsView needs it
                SettingsView()
                    .environmentObject(authService) // Pass the shared authService if Settings needs it
            }
        }
    }
    
    // Need access to authService for the sheet
    @EnvironmentObject var authService: AuthenticationService
}
// --- End Restored ChatView Definition ---

// Helper function to dismiss keyboard
private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// --- Restored MessageBubble Definition ---
struct MessageBubble: View {
    let message: ChatViewModel.ChatMessageItem
    // Removed font constants
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading) {
                Text(message.content ?? "")
                    .padding(12)
                    // Adjust background/foreground later based on new theme
                    .background(message.role == .user ? Color.theme.accent.opacity(0.8) : Color(.systemGray5)) // Example adjustment
                    .foregroundColor(message.role == .user ? .white : Color(.label)) // Example adjustment
                    .cornerRadius(16) // Slightly larger radius maybe?
                    // Removed custom font
                
                Text(formattedTime)
                    .font(.caption2) // Use smaller system font
                    .foregroundColor(Color.theme.secondaryText) // Use theme color for now
                    .padding(.horizontal, 4)
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
        .id(message.id) // For ScrollViewReader
    }
    
    // Format timestamp to show only time
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}
// --- End Restored MessageBubble Definition ---

// Preview (Optional - might need adjustments)
/*
#Preview {
    ChatView()
        .environmentObject(ChatViewModel()) // Provide dummy ViewModel
        .environmentObject(AuthenticationService()) // Provide dummy Auth Service
}
*/

// Helper view modifier for conditional modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
} 