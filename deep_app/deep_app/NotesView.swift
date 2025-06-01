import SwiftUI

struct NotesView: View {
    // Use AppStorage to save notes persistently
    @AppStorage("userNotes") private var notes: String = ""
    
    let titleFontSize: CGFloat = 22 // Consistent title size
    let sciFiFont = "Orbitron" // Consistent font

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Use TextEditor for multi-line input
                TextEditor(text: $notes)
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Allow it to expand
                    .padding(16) // More generous padding inside the editor
                    .background(Color.white) // Clean white background
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                    .font(.system(.body, design: .rounded)) // Use rounded system font
                    .foregroundColor(.primary) // Use primary text color
                    .accessibilityLabel("Notes editor") // Accessibility

                // Add a small instruction or status if needed
                Text("Notes are saved automatically.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(16) // Padding around the VStack
            .background(Color(UIColor.systemGray6).ignoresSafeArea()) // Clean light background
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("Scratchpad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Scratchpad")
                        .font(.custom(sciFiFont, size: titleFontSize))
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.titleText)
                }
            }
            .toolbarBackground(.indigo, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    NotesView()
}

private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
} 