//
//  PopupHost.swift
//  Talking Fingers
//
//  Created by Ria Sharma/Isha Jain on 3/15/26.
//

import SwiftUI

struct PopupHostModifier<PopupContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var onDismiss: (() -> Void)?
    @ViewBuilder var popupContent: () -> PopupContent

    @State private var showDim: Bool = false
    @State private var showPopupContainer: Bool = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if showDim {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        dismiss()
                    }
                    .zIndex(1)
            }

            if showPopupContainer {
                VStack {
                    Spacer()
                    popupContent()
                }
                .transition(.move(edge: .bottom))
                .ignoresSafeArea(edges: .bottom)
                .zIndex(2)
            }
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.32)) {
                    showDim = true
                    showPopupContainer = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showPopupContainer = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showDim = false
                    }
                }
            }
        }
        .onAppear {
            if isPresented {
                showDim = true
                showPopupContainer = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.35)) {
            isPresented = false
        }
        onDismiss?()
    }
}

extension View {
    func popupHost<PopupContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> PopupContent
    ) -> some View {
        self.modifier(PopupHostModifier(isPresented: isPresented, onDismiss: onDismiss, popupContent: content))
    }
}
