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
    // @State private var showScrollToBottomButton = false // <-- State for button visibility (COMMENTED OUT)
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
                                        /* // (COMMENTED OUT)
                                        .if(message.id == viewModel.messages.last(where: { $0.role != .system && $0.role != .tool && !($0.role == .assistant && $0.toolCalls != nil && ($0.content ?? "").isEmpty) })?.id) { view in
                                            view.onAppear { showScrollToBottomButton = false }
                                               .onDisappear { showScrollToBottomButton = true }
                                        }
                                        */
                                        // ---------------------------------------------
                                }
                                
                                // Loading indicator when waiting for API response
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
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
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
                
                // --- Suggested Prompts --- 
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.suggestedPrompts, id: \.self) { prompt in
                            Text(prompt)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.regularMaterial, in: Capsule())
                                .foregroundColor(.primary)
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(0.4), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
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
                    // Image picker button
                    Button {
                        showingImagePicker = true
                    } label: {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(selectedImages.isEmpty ? Color.theme.accent.opacity(0.6) : Color.theme.accent)
                    }
                    .padding(.leading, 16)
                    
                    // Message input field
                    TextField("Message Bryan's Brain...", text: $viewModel.newMessageText)
                        .font(.system(.body, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .textFieldStyle(.plain)
                        .foregroundColor(.primary)
                    
                    // Send button with enhanced glass styling
                    Button {
                        Task {
                            await viewModel.processUserInput(with: selectedImages) 
                            selectedImages.removeAll() // Clear images after sending
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color.theme.accent)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.5), lineWidth: 0.5)
                                    )
                                    .frame(width: 32, height: 32)
                            )
                    }
                    .disabled((viewModel.newMessageText.isEmpty && selectedImages.isEmpty) || viewModel.isLoading)
                    .padding(.trailing, 16)
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground)) // Use system background (adapts light/dark)
                // Optional: Add a subtle top border
                .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color(UIColor.systemGray4)), alignment: .top)
            }
            // Title and toolbar setup
            .navigationBarTitleDisplayMode(.inline)
            // --- Apply background color and ensure visibility --- 
            .toolbarBackground(.indigo, for: .navigationBar) // Set background color
            .toolbarBackground(.visible, for: .navigationBar) // Make it always visible
            // -----------------------------------------------------
            .toolbarColorScheme(.dark, for: .navigationBar) // Keep this to suggest light status bar items
            .background(Color(UIColor.systemGray6).ignoresSafeArea()) // Match new clean design
            .foregroundColor(.primary) // Use primary color for main view text
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Bryan's Brain")
                        .font(.custom(sciFiFont, size: titleFontSize))
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.titleText) // Use theme title color
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
        let lastVisibleMessageId = viewModel.messages.last(where: { $0.role != .system && $0.role != .tool && !($0.role == .assistant && $0.toolCalls != nil && ($0.content ?? "").isEmpty) })?.id
        
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
                            }
                        }
                        .padding(message.images?.isEmpty ?? true ? 16 : 8)
                    }
                }
                .background(
                    message.role == .user ? 
                    Color.theme.accent : 
                    Color.white
                )
                .foregroundColor(
                    message.role == .user ? 
                    .white : 
                    .primary
                )
                .cornerRadius(12)
                .shadow(
                    color: .black.opacity(message.role == .user ? 0.1 : 0.05), 
                    radius: 3, 
                    x: 0, 
                    y: 1
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