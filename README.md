# RichTextEditor
A rich text editor for SwiftUI (iOS)

### Preview
<img width="398" alt="image" src="https://github.com/user-attachments/assets/8d529c51-2ecd-44fc-b410-bc32c9d52d10">

### Example implementation
```
struct DemoView: View {

    @State private var attributedText = NSAttributedString(string: "")
    @State private var selectedRange = NSRange(location: 0, length: 0)

    var body: some View {
        RichTextEditor(attributedText: $attributedText, selectedRange: $selectedRange)
    }
}
```
