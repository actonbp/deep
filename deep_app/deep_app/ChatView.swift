import SwiftUI
import GoogleSignInSwift // Needed for SettingsView presentation if that code is still here

// Define the structure for a To-Do item (Moved from ContentView)
// If this is used elsewhere, consider a dedicated Models file
// struct TodoItem: Identifiable, Codable { ... } // Assuming TodoItem is defined elsewhere now

// Main View hosting the TabView (Moved to ContentView.swift)
// struct ContentView: View { ... }


// Markdown text view that renders basic markdown formatting
struct MarkdownText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        if let attributedString = try? AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributedString)
                .textSelection(.enabled) // Make text selectable
        } else {
            // Fallback to plain text if markdown parsing fails
            Text(text)
                .textSelection(.enabled) // Make text selectable
        }
    }
}

// --- Restored ChatView Definition ---
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSettingsSheet = false // State to control settings sheet
    @State private var selectedImages: [UIImage] = [] // Selected images for upload
    @State private var showingImagePicker = false // Show image picker sheet
    @ObservedObject private var aiAgentManager = AIAgentManager.shared
    // @State private var showScrollToBottomButton = false // <-- State for button visibility (COMMENTED OUT)
    // let sciFiFont = "Orbitron" // Font only used for title now
    // let bodyFontSize: CGFloat = 15 // No longer needed
    
    // Reference to the theme font for the title
    let sciFiFont = "Orbitron" // Keep for title
    let titleFontSize: CGFloat = 22 // Keep for title
    
    // Computed property to break down complex filtering logic
    private var visibleMessages: [ChatViewModel.ChatMessageItem] {
        return viewModel.messages.filter { message in
            // Filter out system and tool messages
            if message.role == .system || message.role == .tool {
                return false
            }
            
            // Filter out assistant messages that only contain tool calls without content
            if message.role == .assistant &&
               message.toolCalls != nil &&
               (message.content ?? "").isEmpty {
                return false
            }
            
            return true
        }
    }
    
    // Computed property for the last visible message ID
    private var lastVisibleMessageId: UUID? {
        return visibleMessages.last?.id
    }
    
    // Computed property for toolbar background
    private var toolbarBackgroundColor: Color {
        if #available(iOS 26.0, *) {
            return Color.clear
        } else {
            return .indigo.opacity(0.8)
        }
    }
    
    // Computed property for main background
    private var mainBackgroundColor: Color {
        if #available(iOS 26.0, *) {
            return Color.clear
        } else {
            return Color(UIColor.systemBackground)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // --- Wrap ScrollViewReader content in ZStack for overlay ---
                ZStack(alignment: .bottomTrailing) { // Align overlay to bottom trailing
                    ScrollViewReader { scrollView in
                        ScrollView {
                            if #available(iOS 26.0, *) {
                                // iOS 26: Enhanced glass effects with proper layering
                                LazyVStack(spacing: 16) {
                                    ForEach(visibleMessages) { message in
                                        MessageBubble(message: message)
                                    }
                                    
                                    // Loading indicator
                                    if viewModel.isLoading {
                                        HStack(spacing: 8) {
                                            ProgressView()
                                                .tint(.gray)
                                            Text(viewModel.isThinking ? "🧠 Thinking deeply..." : "...")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(12)
                                        .background(.ultraThinMaterial, in: Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                        )
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .id("loading")
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                            } else {
                                // Fallback for older iOS versions
                                LazyVStack(spacing: 16) {
                                    ForEach(visibleMessages) { message in
                                        MessageBubble(message: message)
                                    }
                                    
                                    // Loading indicator
                                    if viewModel.isLoading {
                                        HStack(spacing: 8) {
                                            ProgressView()
                                                .tint(.gray)
                                            Text(viewModel.isThinking ? "🧠 Thinking deeply..." : "...")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(12)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(.white.opacity(0.2), lineWidth: 0.5)
                                        )
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .id("loading")
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                            }
                        }
                        .scrollContentBackground(.hidden) // Hide default background for transparency
                        .background(Color.clear) // Ensure scroll view is transparent
                        .onAppear { // <-- Add onAppear for initial scroll
                            scrollToBottom(scrollView: scrollView, animated: false) // Scroll without animation initially
                        }
                        .padding(.horizontal, 6)
                        .padding(.top, 4)
                        .onTapGesture { // Add tap gesture to dismiss keyboard
                            hideKeyboard()
                        }
                        .onChange(of: viewModel.messages.count) { // Keep observing count
                            // Use the helper function to scroll
                            scrollToBottom(scrollView: scrollView, animated: true)
                        }
                        
                        // --- Scroll To Bottom Button (COMMENTED OUT) --- 
                        /*
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
                        */
                        // -------------------------------------------------------------
                    } // <-- End ScrollViewReader
                }
                // --- End ZStack ---
                
                // --- Image Preview Area ---
                if !selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    // Remove button
                                    Button {
                                        selectedImages.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.7), in: Circle())
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
                // -------------------------
                
                // Enhanced Suggested Prompts with Glass 
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.suggestedPrompts, id: \.self) { prompt in
                            Text(prompt)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    ZStack {
                                        if #available(iOS 26.0, *) {
                                            // iOS 26 Beta 3: More opaque glass for readability
                                            Capsule()
                                                .fill(.regularMaterial) // Changed to regularMaterial for better visibility
                                            Capsule()
                                                .fill(.white.opacity(0.1)) // Increased opacity
                                            Capsule()
                                                .fill(.clear)
                                                .glassEffect(in: Capsule())
                                        } else {
                                            Capsule()
                                                .fill(.thinMaterial)
                                        }
                                    }
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.5
                                        )
                                )
                                .foregroundColor(.primary)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                .shadow(color: .white.opacity(0.05), radius: 4, x: 0, y: -2) // Inner glow
                                .lineLimit(1)
                                .scaleEffect(1.0)
                                .onTapGesture { 
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        viewModel.newMessageText = prompt 
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                // -------------------------
                
                // Enhanced Floating Input Area with iOS 26 Glass
                VStack(spacing: 0) {
                    // Glass divider with subtle gradient
                    if #available(iOS 26.0, *) {
                        LinearGradient(
                            colors: [.white.opacity(0.05), .white.opacity(0.1), .white.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 0.5)
                        .blur(radius: 0.5)
                    } else {
                        Rectangle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(height: 0.5)
                    }
                    
                    HStack(spacing: 12) {
                        // Enhanced camera button with glass effect
                        Button {
                            showingImagePicker = true
                        } label: {
                            Image(systemName: selectedImages.isEmpty ? "camera" : "camera.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(selectedImages.isEmpty ? .secondary : Color.theme.accent)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                        )
                                )
                        }
                        
                        // Enhanced input field with deeper glass effect
                        HStack {
                            TextField("Message Bryan's Brain...", text: $viewModel.newMessageText)
                                .font(.system(.body, design: .rounded))
                                .textFieldStyle(.plain)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if #available(iOS 26.0, *) {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.white.opacity(0.02))
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.clear)
                                        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                                } else {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.thinMaterial)
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                        )
                        
                        // Enhanced send button with glass states
                        Button {
                            Task {
                                await viewModel.processUserInput(with: selectedImages) 
                                selectedImages.removeAll()
                            }
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    Group {
                                        if (viewModel.newMessageText.isEmpty && selectedImages.isEmpty) || viewModel.isLoading {
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    Circle()
                                                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                                )
                                        } else {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.theme.accent)
                                                if #available(iOS 26.0, *) {
                                                    Circle()
                                                        .fill(.clear)
                                                        .glassEffect(in: Circle())
                                                }
                                            }
                                        }
                                    }
                                )
                        }
                        .disabled((viewModel.newMessageText.isEmpty && selectedImages.isEmpty) || viewModel.isLoading)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.newMessageText.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        // Enhanced floating glass background
                        ZStack {
                            if #available(iOS 26.0, *) {
                                // iOS 26 Beta 3: More substantial glass for better definition
                                Rectangle()
                                    .fill(.regularMaterial) // Changed from ultraThinMaterial
                                
                                // Stronger gradient overlay
                                LinearGradient(
                                    colors: [.white.opacity(0.08), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                
                                // Glass effect
                                Rectangle()
                                    .fill(.clear)
                                    .glassEffect(in: Rectangle())
                            } else {
                                Color(UIColor.systemBackground).opacity(0.95)
                            }
                        }
                    )
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5) // Floating shadow
                }
            }
            // Enhanced Navigation Bar with iOS 26 Glass
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar) // Hide default background
            .toolbarColorScheme(.none, for: .navigationBar) // Let glass adapt
            .background(
                ZStack {
                    // Base background layer
                    if #available(iOS 26.0, *) {
                        Color.clear
                            .background(.ultraThinMaterial)
                    } else {
                        Color(UIColor.systemBackground)
                    }
                    
                    // Navigation bar glass effect
                    VStack {
                        if #available(iOS 26.0, *) {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    LinearGradient(
                                        colors: [.white.opacity(0.05), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .glassEffect(in: Rectangle())
                                .frame(height: 100) // Approximate nav bar height
                                .ignoresSafeArea(edges: .top)
                                .overlay(
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.white.opacity(0.1), .clear],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: 1)
                                        .offset(y: 50), // Position at bottom of nav bar
                                    alignment: .bottom
                                )
                        }
                        Spacer()
                    }
                }
                .ignoresSafeArea()
            )
            .foregroundColor(.primary)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Text("Bryan's Brain")
                            .font(.custom(sciFiFont, size: titleFontSize))
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.titleText) // Use theme title color
                        
                        if aiAgentManager.isEnabled {
                            Text("🤖")
                                .font(.system(size: 16))
                                .opacity(0.8)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.startNewChat()
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .foregroundColor(Color.theme.accent)
                    }
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
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImages: $selectedImages, selectionLimit: 5)
            }
        }
    }
    
    // Need access to authService for the sheet
    @EnvironmentObject var authService: AuthenticationService
    
    // --- Function to scroll to bottom (Helper - Moved Outside Body) ---
    private func scrollToBottom(scrollView: ScrollViewProxy, animated: Bool = true) {
        // Use the computed property instead of complex inline filtering
        let lastVisibleMessageId = self.lastVisibleMessageId
        
        if animated {
            withAnimation {
                if let lastId = lastVisibleMessageId {
                    scrollView.scrollTo(lastId, anchor: .bottom)
                } else if viewModel.isLoading {
                    scrollView.scrollTo("loading", anchor: .bottom)
                }
            }
        } else {
            if let lastId = lastVisibleMessageId {
                scrollView.scrollTo(lastId, anchor: .bottom)
            } else if viewModel.isLoading {
                scrollView.scrollTo("loading", anchor: .bottom)
            }
        }
        // showScrollToBottomButton = false // Always hide button when explicitly scrolling (COMMENTED OUT)
    }
    // -------------------------------------------------------------------
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
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                    // Display images if they exist (user messages only for now)
                    if let imageData = message.images, !imageData.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: min(imageData.count, 2)), spacing: 4) {
                            ForEach(Array(imageData.enumerated()), id: \.offset) { index, data in
                                if let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: 150, maxHeight: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(8)
                    }
                    
                    // Use markdown formatting for assistant messages, plain text for user
                    if !(message.content?.isEmpty ?? true) {
                        Group {
                            if message.role == .assistant {
                                MarkdownText(message.content ?? "")
                                    .font(.system(.callout, design: .rounded))
                            } else {
                                Text(message.content ?? "")
                                    .font(.system(.callout, design: .rounded))
                                    .textSelection(.enabled) // Enable text selection for user messages
                            }
                        }
                        .padding(message.images?.isEmpty ?? true ? 16 : 8)
                    }
                }
                .background(
                    Group {
                        if #available(iOS 26.0, *) {
                            // iOS 26: Beta 3 frosted glass style with better contrast
                            if message.role == .user {
                                ZStack {
                                    // Base colored background with slight transparency
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.theme.accent.opacity(0.95)) // Very slight transparency
                                    
                                    // Subtle glass material overlay
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.1) // Very low opacity for just a hint of glass
                                    
                                    // Gradient shimmer for depth
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(LinearGradient(
                                            colors: [.white.opacity(0.12), .clear, .white.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                    
                                    // Very subtle glass effect
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.clear)
                                        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                                        .opacity(0.3) // Low opacity glass effect
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.5
                                        )
                                )
                            } else {
                                ZStack {
                                    // Light background for assistant messages
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white)
                                    
                                    // Frosted glass overlay
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.thinMaterial)
                                        .opacity(0.4) // Slightly more opacity for definition
                                    
                                    // Glass effect
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.clear)
                                        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.black.opacity(0.3), lineWidth: 1.0) // Stronger dark border for definition
                                )
                            }
                        } else {
                            // Pre-iOS 26: Traditional bubbles with slightly more modern corners
                            RoundedRectangle(cornerRadius: 18)
                                .fill(message.role == .user 
                                    ? Color.theme.accent.opacity(0.92)  // Slight transparency for depth
                                    : Color.white.opacity(0.95))          // Slightly transparent assistant messages
                                .shadow(
                                    color: Color.theme.accent.opacity(message.role == .user ? 0.1 : 0),
                                    radius: 10,
                                    x: 0,
                                    y: 5
                                )

                            // Add subtle inner glow for depth
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(message.role == .user ? 0.3 : 0.2),
                                                Color.clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.5
                                    )
                            )
                        }
                    }
                )
                .foregroundColor(
                    message.role == .user ? .white : .primary
                )
                .shadow(
                    color: .black.opacity(0.08), 
                    radius: 16, // Stronger shadow for better depth
                    x: 0, 
                    y: 6 // More vertical offset for floating effect
                )
                .shadow(
                    color: Color.theme.accent.opacity(message.role == .user ? 0.1 : 0), 
                    radius: 20, // Colored glow for user messages
                    x: 0, 
                    y: 4
                )
                
                Text(formattedTime)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.secondary)
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