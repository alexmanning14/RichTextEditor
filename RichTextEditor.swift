import SwiftUI
import UIKit

// SwiftUI view for the rich text editor
struct RichTextEditor: View {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    @State private var typingAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16),
        .foregroundColor: UIColor.black
    ]

    @State private var isBoldActive = false
    @State private var isItalicActive = false
    @State private var isUnderlineActive = false
    @State private var isStrikethroughActive = false
    @State private var selectedTitleType = "Body"
    @State private var isBulletActive = false

    let titleTypes = ["Title", "Headline", "Subheadline", "Body", "Footnote"]

    var body: some View {
        VStack {
            HStack {
                ToggleButton(symbolName: "bold", isActive: isBoldActive, action: toggleBold)
                ToggleButton(symbolName: "italic", isActive: isItalicActive, action: toggleItalic)
                ToggleButton(symbolName: "underline", isActive: isUnderlineActive, action: toggleUnderline)
                ToggleButton(symbolName: "strikethrough", isActive: isStrikethroughActive, action: toggleStrikethrough)
                ToggleButton(symbolName: "list.bullet", isActive: isBulletActive, action: toggleBulletedList)
                
                // Dropdown for title types
                Menu {
                    Picker(selection: $selectedTitleType, label: EmptyView()) {
                        ForEach(titleTypes, id: \.self) { title in
                            Text(title)
                        }
                    }
                    .onChange(of: selectedTitleType) { oldValue, newValue in
                        applyTextStyle(newValue)
                    }
                } label: {
                    Image(systemName: "textformat.size")
                        .foregroundStyle(Color.black)
                }

                ColorPicker("", selection: $textColor)
                    .onChange(of: textColor) { oldValue, newValue in changeTextColor() }
                    .labelsHidden()
                    .padding(.horizontal)
            }
            RichTextEditorUIViewRepresentable(attributedText: $attributedText, selectedRange: $selectedRange, typingAttributes: $typingAttributes, isBulletActive: $isBulletActive)
        }
    }

    // Button for toggling formatting
    func ToggleButton(symbolName: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .foregroundColor(isActive ? .blue : .black)
                .padding()
                .background(isActive ? Color.gray.opacity(0.2) : Color.clear)
                .cornerRadius(8)
        }
    }
    
    // Toggle bulleted list formatting
    func toggleBulletedList() {
        isBulletActive.toggle()
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
        
        // Ensure we calculate the paragraph range only if there's a selected range
        guard selectedRange.length >= 0 else { return }
        let paragraphRange = (attributedText.string as NSString).paragraphRange(for: selectedRange)

        if isBulletActive {
            let bullet = "• "
            
            // Insert the bullet at the start of the paragraph
            mutableAttributedString.insert(NSAttributedString(string: bullet, attributes: typingAttributes), at: paragraphRange.location)
            attributedText = mutableAttributedString
            
            // Move cursor to the end of the bullet
            let newCursorLocation = paragraphRange.location + bullet.count
            selectedRange = NSRange(location: newCursorLocation, length: 0) // Set cursor after the bullet
        } else {
            // Remove bullet from the current line
            let paragraphText = (attributedText.string as NSString).substring(with: paragraphRange)
            if paragraphText.hasPrefix("• ") {
                mutableAttributedString.replaceCharacters(in: NSRange(location: paragraphRange.location, length: 2), with: "")
                attributedText = mutableAttributedString
                
                // Move cursor to the end of the line after removing the bullet
                let newCursorLocation = paragraphRange.location
                selectedRange = NSRange(location: newCursorLocation, length: 0) // Set cursor at the end of the line
            }
        }
    }

    // Toggle bold formatting (disables italic if active)
    func toggleBold() {
        isBoldActive.toggle()
        if isBoldActive {
            isItalicActive = false
            applyAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16))
        } else {
            applyAttribute(.font, value: UIFont.systemFont(ofSize: 16))
        }
    }

    // Toggle italic formatting (disables bold if active)
    func toggleItalic() {
        isItalicActive.toggle()
        if isItalicActive {
            isBoldActive = false
            let fontDescriptor = (typingAttributes[.font] as? UIFont)?.fontDescriptor
            let newFontDescriptor = fontDescriptor?.withSymbolicTraits(.traitItalic)
            if let newDescriptor = newFontDescriptor {
                applyAttribute(.font, value: UIFont(descriptor: newDescriptor, size: 16))
            }
        } else {
            applyAttribute(.font, value: UIFont.systemFont(ofSize: 16))
        }
    }

    // Toggle underline formatting
    func toggleUnderline() {
        isUnderlineActive.toggle()
        applyAttribute(.underlineStyle, value: isUnderlineActive ? NSUnderlineStyle.single.rawValue : nil)
    }

    // Toggle strikethrough formatting
    func toggleStrikethrough() {
        isStrikethroughActive.toggle()
        applyAttribute(.strikethroughStyle, value: isStrikethroughActive ? NSUnderlineStyle.single.rawValue : nil)
    }

    // Apply formatting attribute to selected text or future text input
    func applyAttribute(_ key: NSAttributedString.Key, value: Any?) {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.length > 0 {
            mutableAttributedString.addAttribute(key, value: value ?? NSNull(), range: selectedRange)
            attributedText = mutableAttributedString
        } else {
            typingAttributes[key] = value
        }
    }

    // Apply text style based on dropdown selection
    func applyTextStyle(_ style: String) {
        let font: UIFont
        switch style {
        case "Title":
            font = UIFont.boldSystemFont(ofSize: 28)
        case "Headline":
            font = UIFont.boldSystemFont(ofSize: 24)
        case "Subheadline":
            font = UIFont.boldSystemFont(ofSize: 20)
        case "Body":
            font = UIFont.systemFont(ofSize: 16)
        case "Footnote":
            font = UIFont.systemFont(ofSize: 12)
        default:
            font = UIFont.systemFont(ofSize: 16)
        }
        applyAttribute(.font, value: font)
    }

    // Change text color
    @State private var textColor: Color = .black
    func changeTextColor() {
        let uiColor = UIColor(textColor)
        applyAttribute(.foregroundColor, value: uiColor)
    }
}

// UIViewRepresentable for added UIKit functionality
struct RichTextEditorUIViewRepresentable: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    @Binding var typingAttributes: [NSAttributedString.Key: Any]
    @Binding var isBulletActive: Bool

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.attributedText = attributedText
        textView.typingAttributes = typingAttributes
        textView.inputAccessoryView = createKeyboardToolbar(coordinator: context.coordinator)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
        uiView.selectedRange = selectedRange
        uiView.typingAttributes = typingAttributes
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditorUIViewRepresentable

        init(_ parent: RichTextEditorUIViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.attributedText = textView.attributedText
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.selectedRange = textView.selectedRange
                self.parent.typingAttributes = textView.typingAttributes
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" { // User pressed Enter
                if parent.isBulletActive {
                    let bullet = "• "
                    let mutableAttributedString = NSMutableAttributedString(attributedString: textView.attributedText)

                    // Add a newline character followed by a bullet
                    mutableAttributedString.replaceCharacters(in: range, with: "\n" + bullet)

                    // Update the text view's attributed text without triggering another change event
                    textView.attributedText = mutableAttributedString

                    // Move the cursor to the end of the newly inserted bullet
                    let newCursorLocation = range.location + 1 + bullet.count
                    textView.selectedRange = NSRange(location: newCursorLocation, length: 0)

                    // Update the parent attributed text here to ensure consistency
                    DispatchQueue.main.async {
                        self.parent.attributedText = mutableAttributedString
                    }

                    return false // Prevent the default newline behavior
                }
            }
            return true // Allow other text changes
        }

        // Method to dismiss the keyboard
        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }


    // Create the toolbar with a button to dismiss the keyboard
    private func createKeyboardToolbar(coordinator: Coordinator) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        // Create a button with the SF Symbol "keyboard.chevron.compact.down"
        let dismissButton = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .plain, target: coordinator, action: #selector(coordinator.dismissKeyboard))
        dismissButton.tintColor = .systemBlue // Optional: set the tint color of the button
        
        // Add a flexible space to push the button to the right
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.items = [flexibleSpace, dismissButton]
        return toolbar
    }
}
