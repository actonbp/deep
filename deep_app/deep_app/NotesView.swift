import SwiftUI

struct NotesView: View {
    // Use AppStorage to save notes persistently
    @AppStorage("userNotes") private var notes: String = ""
    
    let titleFontSize: CGFloat = 22 // Consistent title size
    let sciFiFont = "Orbitron" // Consistent font

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // Use TextEditor for multi-line input
                TextEditor(text: $notes)
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Allow it to expand
                    .padding(8) // Padding inside the editor
                    .background(Color(UIColor.systemGray6)) // Subtle background
                    .cornerRadius(10)
                    .font(.body) // Use standard body font for notes
                    .foregroundColor(Color.theme.text) // Use theme text color
                    .accessibilityLabel("Notes editor") // Accessibility

                // Add a small instruction or status if needed
                Text("Notes are saved automatically.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
            .padding() // Padding around the VStack
            .background(Color.theme.background.ignoresSafeArea()) // Use theme background
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