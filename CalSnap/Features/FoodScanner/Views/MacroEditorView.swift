import SwiftUI


struct MacroEditorView: View {
    let macroType: MacroType
    @Binding var value: Int
    let maxValue: Int?
    let onRevert: () -> Void
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var tempValue: String = "" // Initialize as empty
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Back button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                // Title
                Text("Edit \(macroType.title)")
                    .font(.largeTitle).bold()
                    .padding(.top, 8)
                // Summary card
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 6)
                            .frame(width: 56, height: 56)
                        Image(systemName: macroType.icon)
                            .font(.title2)
                            .foregroundColor(macroType.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(value)")
                            .font(.title2).bold()
                        if let maxValue = maxValue {
                            Text("Out of \(maxValue) left today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                // Text field
                VStack(alignment: .leading, spacing: 4) {
                    Text(macroType.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("", text: $tempValue)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .font(.title2)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.primary, lineWidth: 1))
                        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isFocused = true } }
                }
                // Place buttons directly below the TextField
                // (Rule: UI Development, DebugLogs, Comments, RuleEcho)
                HStack(spacing: 16) {
                    Button(action: {
                        tempValue = String(value)
                        onRevert()
                        dismiss()
                    }) {
                        Text("Revert")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Button(action: {
                        if let intVal = Int(tempValue) {
                            value = intVal
                        }
                        onDone()
                        dismiss()
                    }) {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 2)
                .onAppear { print("[MacroEditorView] Button bar below TextField") } // DebugLogs
                Spacer(minLength: 0)
            }
            .padding()
        }
        .onAppear {
            // Initialize tempValue from value if empty (fixes blank screen bug)
            if tempValue.isEmpty { tempValue = String(value) }
        }
        .presentationDetents([.large])
    }
} 