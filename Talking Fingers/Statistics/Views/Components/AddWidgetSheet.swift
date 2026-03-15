//
//  AddWidgetSheet.swift
//  Talking Fingers
//
//  Created by Jagat Sachdeva on 2/19/26.
//

import SwiftUI

struct AddWidgetSheet: View {
    private enum WidgetSize: String, CaseIterable { case small, medium, large }
    @State private var selectedSize: WidgetSize = .medium

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    var onAdd: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Widget")
                .font(.title)
                .fontWeight(.semibold)
            TextField("Widget name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            // Selection of size
            HStack(spacing: 12) {
                // Small
                Button(action: { selectedSize = .small }) {
                    Text("Small")
                        .frame(height: 36)
                        .padding(.horizontal, 12)
                        .background(selectedSize == .small ? Color.secondary : Color.white)
                        .foregroundColor(selectedSize == .small ? .white : .secondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.quaternary, lineWidth: 1)
                                .opacity(selectedSize == .small ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 8))

                // Medium
                Button(action: { selectedSize = .medium }) {
                    Text("Medium")
                        .frame(height: 36)
                        .padding(.horizontal, 12)
                        .background(selectedSize == .medium ? Color.secondary : Color.white)
                        .foregroundColor(selectedSize == .medium ? .white : .secondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.quaternary, lineWidth: 1)
                                .opacity(selectedSize == .medium ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 8))

                // Large
                Button(action: { selectedSize = .large }) {
                    Text("Large")
                        .frame(height: 36)
                        .padding(.horizontal, 12)
                        .background(selectedSize == .large ? Color.secondary : Color.white)
                        .foregroundColor(selectedSize == .large ? .white : .secondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.quaternary, lineWidth: 1)
                                .opacity(selectedSize == .large ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .animation(.easeInOut(duration: 0.15), value: selectedSize)
            
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    let finalTitle = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    onAdd(finalTitle.isEmpty ? "Untitled Widget" : finalTitle)
                    dismiss()
                }) {
                    Text("Confirm")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}
#Preview {
    AddWidgetSheet { _ in }
}

