import SwiftUI

struct NotesView: View {
    // Use AppStorage to save notes persistently
    @AppStorage("userNotes") private var notes: String = ""
    
    let titleFontSize: CGFloat = 22 // Consistent title size
    let sciFiFont = "Orbitron" // Consistent font

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // iOS 26 glass-enhanced TextEditor
                TextEditor(text: $notes)
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Allow it to expand
                    .padding(16) // More generous padding inside the editor
                    .font(.system(.body, design: .rounded)) // Use rounded system font
                    .foregroundColor(.primary) // Use primary text color
                    .accessibilityLabel("Notes editor") // Accessibility
                    .scrollContentBackground(.hidden) // Hide default background for glass effect
                    .conditionalGlassBackground(Color.white, opacity: 0.8, in: RoundedRectangle(cornerRadius: 12))
                    .conditionalGlassEffect(in: RoundedRectangle(cornerRadius: 12))

                // Glass-styled status text
                Text("Notes are saved automatically.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .conditionalGlassBackground(Color.gray, opacity: 0.1, in: Capsule())
                    .conditionalGlassEffect(in: Capsule())
            }
            .padding(16) // Padding around the VStack
            .background(
                // iOS 26 glass background
                Group {
                    if #available(iOS 26.0, *) {
                        Color.clear
                            .background(.ultraThinMaterial)
                    } else {
                        Color(UIColor.systemGray6)
                    }
                }
                .ignoresSafeArea()
            )
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