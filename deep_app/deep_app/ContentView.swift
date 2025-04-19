//
//  ContentView.swift
//  deep_app
//
//  Created by bacton on 4/15/25.
//

import SwiftUI

// Define the structure for a To-Do item
struct TodoItem: Identifiable, Codable {
    let id = UUID() // Use let for stable identifier
    var text: String
    var isDone: Bool = false // Status flag
}

// Main View hosting the TabView
struct ContentView: View {
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
            
            TodoListView()
                .tabItem {
                    Label("To-Do List", systemImage: "list.bullet.clipboard.fill")
                }
        }
    }
}

// Placeholder for the Chat Interface View
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // --- Model Selection Placeholder UI --- 
                HStack(spacing: 15) {
                    Text("Model:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("OpenAI GPT-4o mini") // Update model name display
                        .font(.caption.weight(.semibold))
                    
                    Spacer() // Push other options away
                        
                    Text("Claude 3.5 Sonnet") // Placeholder
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("On-Device") // Placeholder
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
                Divider() // Add a visual separator
                // -------------------------------------
                
                // Chat messages list
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Filter out system messages (instructions to the AI) from display
                            ForEach(viewModel.messages.filter { $0.role != .system }) { message in
                                MessageBubble(message: message)
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
                    .onTapGesture { // Add tap gesture to dismiss keyboard
                        hideKeyboard()
                    }
                    .onChange(of: viewModel.messages.count) { oldCount, newCount in
                        // Scroll to bottom when messages change
                        withAnimation {
                            if let lastMsg = viewModel.messages.last {
                                scrollView.scrollTo(lastMsg.id, anchor: .bottom)
                            } else if viewModel.isLoading {
                                scrollView.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // --- Suggested Prompts --- 
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.suggestedPrompts, id: \.self) { prompt in
                            Text(prompt)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                                .foregroundColor(.primary)
                                .lineLimit(1) // Prevent wrapping
                                .onTapGesture {
                                    viewModel.newMessageText = prompt
                                }
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
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .textFieldStyle(.plain)
                        .padding(.leading)
                    
                    // Send button
                    Button {
                        Task {
                            // Call the new processing function
                            await viewModel.processUserInput() 
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.newMessageText.isEmpty || viewModel.isLoading)
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color.white)
            }
            .navigationTitle("Bryan's Brain")
        }
    }
}

// Helper function to dismiss keyboard
private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// Message bubble component for chat
struct MessageBubble: View {
    let message: ChatViewModel.ChatMessageItem
    
    var body: some View {
        HStack {
            // User message on the right, assistant message on the left
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading) {
                // Message content - Use nil-coalescing for optional content
                Text(message.content ?? "") // Provide default empty string
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.role == .user ? .white : .black)
                    .cornerRadius(16)
                
                // Timestamp
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
        .id(message.id) // For ScrollViewReader to find
    }
    
    // Format timestamp to show only time
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}

// View for displaying and managing the To-Do List
struct TodoListView: View {
    // Use the shared singleton instance
    // Use @ObservedObject because the view doesn't own the store's lifecycle
    @ObservedObject private var todoListStore = TodoListStore.shared
    
    // State for the text field input within this view
    @State private var newItemText: String = ""

    var body: some View {
        NavigationView { 
            VStack {
                HStack {
                    TextField("Enter new item", text: $newItemText) // Use local state for input
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add") {
                        // Call the store's add method
                        todoListStore.addItem(text: newItemText)
                        newItemText = "" // Clear local input field
                    }
                    .disabled(newItemText.isEmpty)
                }
                .padding()

                List { // Display the list of items from the store
                    ForEach(todoListStore.items) { item in // Iterate over items from the store
                        HStack {
                            Text(item.text)
                                .strikethrough(item.isDone, color: .gray) 
                                .foregroundColor(item.isDone ? .gray : .primary)
                            Spacer() 
                        }
                        .contentShape(Rectangle()) 
                        .onTapGesture { // Call the store's toggle method
                            todoListStore.toggleDone(item: item)
                        }
                    }
                    .onDelete(perform: todoListStore.deleteItems) // Call the store's delete method
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("To-Do List")
            .toolbar { 
                EditButton()
            }
        }
    }
}

#Preview {
    ContentView()
}
