import SwiftUI

struct PopUpTesterView: View {
    
    @State private var showHint = false
    @State private var showQuestion = false
    @State private var showCorrect = false
    @State private var showDim = false
    
    var body: some View {
        ZStack {
            
            // ── Main screen ─────────────────────────────
            VStack(spacing: 20) {
                
                // Header
                HStack {
                    Button {
                        
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                    
                    ProgressView(value: 0.25)
                        .progressViewStyle(.linear)
                        .tint(.green)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                
                // Word
                Text("Hello")
                    .font(.system(size: 45, weight: .bold))
                
                
                // Image card
                ZStack(alignment: .top) {
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: 0xF2F2F7))
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                                .padding(40)
                        )
                    
                    // Top buttons
                    HStack {
                        
                        // Bookmark
                        Button {
                            // placeholder
                        } label: {
                            Image(systemName: "bookmark")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Hint
                        Button {
                            showHintPopup()
                        } label: {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                        
                        // Question
                        Button {
                            showQuestionPopup()
                        } label: {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(12)
                }
                .frame(height: 320)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3))
                )
                .padding(.horizontal)
                
                
                Spacer()
                
                
                // ── Answer choices ───────────────────────
                
                Button {
                    showCorrectPopup()
                } label: {
                    Text("Hello")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)
                
                
                Button {
                    
                } label: {
                    Text("Goodbye")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray)
                        )
                }
                .padding(.horizontal)
                
                
                Button {
                    
                } label: {
                    Text("Please")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray)
                        )
                }
                .padding(.horizontal)
            }
            .padding(.top)
            
            
            // ── Dim background ─────────────────────────
            if showDim {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        dismiss()
                    }
                    .zIndex(1)
            }
            
            
            // ── Hint popup ─────────────────────────────
            if showHint {
                popupContainer {
                    HintPopUpComponent(
                        hintText: "This sign resembles a B shape"
                    ) {
                        dismiss()
                    }
                }
            }
            
            
            // ── Question popup ─────────────────────────
            if showQuestion {
                popupContainer {
                    QuestionMarkPopUpComponent(
                        explanationText: "Are you sure you want to move on?"
                    ) {
                        dismiss()
                    }
                }
            }
            
            
            // ── Correct answer popup ───────────────────
            if showCorrect {
                popupContainer {
                    CorrectAnswerPopUpComponent {
                        dismiss()
                    }
                }
            }
        }
    }
    
    
    // ── Popup container (shared layout) ──────────────
    
    func popupContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack {
            Spacer()
            content()
        }
        .transition(.move(edge: .bottom))
        .ignoresSafeArea(edges: .bottom)
        .zIndex(2)
    }
    
    
    // ── Show functions ───────────────────────────────
    
    func showHintPopup() {
        withAnimation(.easeInOut(duration: 0.32)) {
            showDim = true
            showHint = true
        }
    }
    
    func showQuestionPopup() {
        withAnimation(.easeInOut(duration: 0.32)) {
            showDim = true
            showQuestion = true
        }
    }
    
    func showCorrectPopup() {
        withAnimation(.easeInOut(duration: 0.32)) {
            showDim = true
            showCorrect = true
        }
    }
    
    
    // ── Dismiss ─────────────────────────────────────
    
    func dismiss() {
        withAnimation(.easeInOut(duration: 0.35)) {
            showHint = false
            showQuestion = false
            showCorrect = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.35)) {
                showDim = false
            }
        }
    }
}

#Preview {
    PopUpTesterView()
}
