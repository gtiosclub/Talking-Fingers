//
//  OnboardingView.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 4/23/26.
//

import Foundation
import SwiftUI
#if os(iOS)
import UIKit
struct OnboardingView: View {
    @Environment(AuthenticationViewModel.self) var authVM
    @State private var page = 0
    @State private var name = ""
    @State private var handedness: String? = nil
    let onFinished: (String, String?) -> Void
    init(onFinished: @escaping (String, String?) -> Void = { _, _ in }) {
        self.onFinished = onFinished
    }
    var body: some View {
        Group {
            if page == 0 {
                ObView1 {
                    page = 1
                }
            } else if page == 1 {
                ObView2(
                    onNext: {
                        page = 2
                    },
                    name: $name,
                    handedness: $handedness
                )
            } else if page == 2 {
                ObView3(
                    onNext: {
                        page = 3
                    },
                    name: name
                )
            } else if page == 3 {
                ObView4(onNext: {
                    onFinished(name, handedness)
                }, name: name)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            authVM.setSessionHandedness(handedness)
        }
        .onChange(of: handedness) { _, newValue in
            authVM.setSessionHandedness(newValue)
        }
    }
}

struct ObView1: View {
    let onNext: () -> Void
    var body: some View {
        ZStack {
            Rectangle()
                .ignoresSafeArea()
                .foregroundColor(Color(UIColor(hex: "#EAF3E3")))
            
            RadialGradient(colors: [Color(UIColor(hex: "#82C8FF")), Color(UIColor(hex: "#ADCE8F"))], center: .center, startRadius: 0, endRadius: 250)
                .frame(width: 500, height: 500)
                .clipShape(Circle())
                .blur(radius: 200)
                .offset(x:-160, y: -400)
            
            RadialGradient(colors: [Color(UIColor(hex: "#F8BC3A")), Color(UIColor(hex: "#ADCE8F"))], center: .center, startRadius: 0, endRadius: 250)
                .frame(width: 500, height: 500)
                .clipShape(Circle())
                .blur(radius: 200)
                .offset(x:160, y: 400)
            
            VStack (alignment: .leading) {
                Text("Welcome to")
                    .font(.system(size:40))
                    .fontWeight(.regular)
                    .foregroundColor(Color(UIColor(hex: "#464646")))
                Text("Talking Fingers")
                    .font(.system(size:48))
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor(hex: "#464646")))
                    .frame(alignment: .leading)
                Button (action: {onNext()}){
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .foregroundColor(Color(UIColor(hex: "#97C171")))
                            .frame(width: 338, height: 45)
                        Text("Get Started")
                            .font(Font.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct ObView2: View {
    let onNext: () -> Void
    enum Handedness {
        case left
        case right
    }
    @Binding var name: String
    @Binding var handedness: String?
    @State private var selectedHand: Handedness? = nil
    var body: some View {
        ScrollView {
            VStack {
                VStack (alignment: .leading) {
                    Text("Welcome to")
                        .font(.system(size:40))
                        .fontWeight(.regular)
                        .foregroundColor(Color(UIColor(hex: "#464646")))
                    Text("Talking Fingers")
                        .font(.system(size:48))
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor(hex: "#464646")))
                        .frame(alignment: .leading)
                }
                .padding(.trailing)
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom)
                VStack (alignment: .leading) {
                    Text ("Let's set you up.")
                        .font(Font.system(size: 20, weight: .bold))
                        .foregroundColor(Color(UIColor(hex: "#464646")))
                        .padding(.bottom)
                    TextField("Your Name", text: $name)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(width: 338, height: 56)
                        .background(Color.gray.opacity(0.1))
                        .border(Color(UIColor(hex: "#E2E2E2")))
                        .cornerRadius(12)
                        .padding(.bottom)
                    Text("In American Sign Language (ASL), dominant hand determines how you sign. ")
                        .font(Font.system(size: 20, weight: .regular))
                        .foregroundColor(Color(UIColor(hex: "#464646")))
                    +
                    Text("Select your dominant hand.")
                        .font(Font.system(size: 20, weight: .bold))
                        .foregroundColor(Color(UIColor(hex: "#464646")))
                    HStack {
                        Button {
                            selectedHand = .left
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .frame(width: 165, height: 181)
                                    .foregroundColor(selectedHand == .left ? Color(UIColor(hex: "#FDF2D8")): Color(UIColor(hex: "#FCFCFC")))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color(UIColor(hex: "#E2E2E2")), lineWidth: 1)
                                    )
                                VStack {
                                    Image("left")
                                    Text("Left")
                                        .font(Font.system(size: 20, weight: .regular))
                                        .foregroundColor(Color(UIColor(hex: "#464646")))
                                }
                            }
                        }
                        Button {
                            selectedHand = .right
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .frame(width: 165, height: 181)
                                    .foregroundColor(selectedHand == .right ? Color(UIColor(hex: "#FDF2D8")): Color(UIColor(hex: "#FCFCFC")))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color(UIColor(hex: "#E2E2E2")), lineWidth: 1)
                                    )
                                VStack {
                                    Image("right")
                                    Text("Right")
                                        .font(Font.system(size: 20, weight: .regular))
                                        .foregroundColor(Color(UIColor(hex: "#464646")))
                                }
                            }
                        }
                    }
                    .padding(.bottom)
                    .padding(.top)
                    
                    Button (action: {
                        if let hand = selectedHand {
                            handedness = hand == .left ? "left" : "right"
                        }
                        onNext()
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 100)
                                .foregroundColor(Color(UIColor(hex: "#97C171")))
                                .frame(width: 338, height: 45)
                            Text("Start Learning")
                                .font(Font.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            if selectedHand == nil || name.isEmpty {
                                RoundedRectangle(cornerRadius: 100)
                                    .foregroundColor(Color.white.opacity(0.4))
                                    .frame(width: 338, height: 45)
                            }
                        }
                    }
                    .disabled(selectedHand == nil || name.isEmpty)
                }
                .padding()
            }
        }
    }
}

struct ObView3: View {
    let onNext: () -> Void
    @State var name: String
    let signDescriptions: [Character: String] = [
        "a": "Fist with thumb on side",
        "b": "Open hand, thumb across palm",
        "c": "C-shaped curve",
        "d": "Index up, thumb touches middle finger",
        "e": "Fingers curled into palm",
        "f": "Index + thumb touch (circle)",
        "g": "Sideways point with index",
        "h": "Index + middle together, horizontal",
        "i": "Pinky finger up",
        "j": "Trace J shape with pinky",
        "k": "V shape with index + thumb",
        "l": "L shape with thumb + index",
        "m": "Thumb under three fingers",
        "n": "Thumb under two fingers",
        "o": "Fingers form a circle",
        "p": "Thumb and middle touching, pointer pointing down",
        "q": "Pointer curled + middle and thumb pointing down",
        "r": "Index + middle crossed",
        "s": "Fist with thumb over fingers",
        "t": "Thumb between fingers",
        "u": "Index + middle up together",
        "v": "V shape fingers",
        "w": "Three fingers up",
        "x": "Hooked index finger",
        "y": "Thumb + pinky extended",
        "z": "Trace Z in air"
    ]
    var body: some View {
        VStack {
            ScrollView {
                VStack (alignment: .leading){
                    Text("Nice to meet you,")
                        .font(Font.system(size: 40, weight: .regular))
                        .foregroundColor(Color(UIColor(hex: "#464646")))
                    Text("\(name)!")
                        .font(Font.system(size: 48, weight: .bold))
                        .foregroundColor(Color(UIColor(hex: "#559AD2")))
                        .padding(.bottom)
                    Text("Learning to fingerspell is essential for your ASL journey. ")
                        .font(Font.system(size: 20, weight: .regular))
                        .foregroundColor(Color(UIColor(hex: "#464646")))
                    +
                    Text("Let’s start with your name!")
                        .font(Font.system(size: 20, weight: .bold))
                        .foregroundColor(Color(UIColor(hex: "#464646")))
                }
                .padding(.bottom)
                .padding(.trailing)
                .padding(.leading)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom)
                
                VStack (alignment: .leading) {
                    ForEach(Array(name.lowercased()), id: \.self) { letter in
                        HStack {
                            Image("\(letter)")
                                .resizable()
                                .frame(width: 54, height: 72)
                            Text(letter.uppercased())
                                .font(Font.system(size: 32, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#464646")))
                            VStack {
                                Text(signDescription(for: letter))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(Font.system(size: 16, weight: .regular))
                                    .foregroundColor(Color(UIColor(hex: "#464646")))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                            }
                        }
                    }
                }
                .padding()
                
                
                Button (action: {onNext()}){
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .foregroundColor(Color(UIColor(hex: "#97C171")))
                            .frame(width: 338, height: 45)
                        Text("Try It Out")
                            .font(Font.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    func signDescription(for letter: Character) -> String {
        return signDescriptions[letter] ?? "No description available"
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)

        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

struct ObView4: View {
    let onNext: () -> Void
    @State var name: String
    @State private var currentIndex: Int = 0
    @State private var isPassed: Bool = false
    @State private var finished = false
    @State private var completedWords: Set<Int> = []
    private let passThreshold: Double = 0.85

    var body: some View {
        let letters = Array(name.uppercased())
        VStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Try fingerspelling your name!")
                    .font(Font.system(size: 17, weight: .regular))
                    .foregroundColor(Color(UIColor(hex: "#464646")))
            }
            HStack(spacing: 8) {
                ForEach(letters.indices, id: \.self) { i in
                    Text(String(letters[i]))
                        .font(Font.system(size: 32, weight: .semibold))
                        .foregroundColor(i == currentIndex ? Color(UIColor(hex: "#464646")) : Color(UIColor(hex: "#CCCCCC")))

                    if i != letters.count - 1 {
                        Text("-")
                            .font(Font.system(size: 32, weight: .semibold))
                            .foregroundColor(Color(UIColor(hex: "#CCCCCC")))
                    }
                }
            }

            // Practice view for the current letter
            if currentIndex < letters.count {
                SigningPracticeView(
                    signName: String(letters[currentIndex]),
                    onConfidenceChange: { score in
                        if score >= passThreshold && !isPassed {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isPassed = true
                                completedWords.insert(currentIndex)
                            }
                            // Advance to next letter after a brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isPassed = false
                                completedWords.insert(currentIndex)
                                if currentIndex < letters.count - 1 {
                                    currentIndex += 1
                                } else {
                                    finished = true
                                }
                            }
                        }
                    }
                )
                .id(currentIndex)
                nameProgressCircles
                    .padding(.bottom, 24)
            }
            if finished {
                Button(action: {
                    onNext()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .foregroundColor(Color(UIColor(hex: "#97C171")))
                            .frame(width: 338, height: 45)
                        Text("Next")
                            .font(Font.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
    private var nameProgressCircles: some View {
        let letters = Array(name.uppercased())
        return Group {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(letters.enumerated()), id: \.offset) { index, _ in
                            circleIcon2(for: index)
                                .id("circle-\(index)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .onChange(of: currentIndex) { _, newIndex in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("circle-\(newIndex)", anchor: .center)
                    }
                }
            }
        }
    }
    
    private static let progressCircleColumnWidth: CGFloat = 72
    private static let progressCircleDiameter: CGFloat = 52

    @ViewBuilder
    private func circleIcon2(for index: Int) -> some View {
        let letters = Array(name.uppercased())
        let isCompleted = completedWords.contains(index)
        let isCurrent = index == currentIndex && !finished
        let wordLabel = index < letters.count ? String(letters[index]) : ""
        let d = Self.progressCircleDiameter

        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(circleFill(isCompleted: isCompleted, isCurrent: isCurrent))
                    .frame(width: isCurrent ? d + 10 : d, height: isCurrent ? d + 10 : d)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#71A046"))
                } else if isCurrent {
                    Image(systemName: "lightbulb.max")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#F8BC3A"))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#B3B3B3"))
                }
            }
            .frame(width: Self.progressCircleColumnWidth, height: Self.progressCircleColumnWidth, alignment: .center)

            Text(wordLabel)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#767676"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(isCurrent ? 1 : 0)
                .frame(height: 20)
        }
        .frame(width: Self.progressCircleColumnWidth)
        .animation(.easeInOut(duration: 0.3), value: currentIndex)
    }

    private func circleFill(isCompleted: Bool, isCurrent: Bool) -> Color {
        if isCompleted { return Color(hex: "#EAF3E3") }
        if isCurrent { return Color(hex: "#FDF2D8") }
        return Color.gray.opacity(0.12)
    }
}

#endif

#if os(macOS)
import AppKit

// Simple hex helper for macOS Color
private extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }
        var rgb: UInt64 = 0
        _ = scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}

struct OnboardingView: View {
    @Environment(AuthenticationViewModel.self) var authVM
    @State private var page = 0
    @State private var name = ""
    @State private var handedness: String? = nil
    let onFinished: (String, String?) -> Void
    init(onFinished: @escaping (String, String?) -> Void = { _, _ in }) {
        self.onFinished = onFinished
    }

    var body: some View {
        Group {
            switch page {
            case 0:
                MacObView1 { page = 1 }
            case 1:
                MacObView2(onNext: { page = 2 }, name: $name, handedness: $handedness)
            case 2:
                MacObView3(onNext: { page = 3 }, name: name)
            case 3:
                MacObView4(onNext: {
                    // Move to a terminal page before finishing to avoid re-entering this case
                    page = 4
                    // Call completion on the next runloop to let navigation update cleanly
                    DispatchQueue.main.async {
                        self.onFinished(self.name, self.handedness)
                    }
                }, name: name)
            case 4:
                EmptyView()
            default:
                MacObView1 { page = 1 }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            authVM.setSessionHandedness(handedness)
        }
        .onChange(of: handedness) { _, newValue in
            authVM.setSessionHandedness(newValue)
        }
    }
}

private struct MacObView1: View {
    let onNext: () -> Void
    var body: some View {
        ZStack {
            Rectangle()
                .ignoresSafeArea()
                .foregroundColor(Color(hexString: "#EAF3E3"))

            RadialGradient(colors: [Color(hexString: "#82C8FF"), Color(hexString: "#ADCE8F")], center: .center, startRadius: 0, endRadius: 250)
                .frame(width: 500, height: 500)
                .clipShape(Circle())
                .blur(radius: 200)
                .offset(x: -160, y: -400)

            RadialGradient(colors: [Color(hexString: "#F8BC3A"), Color(hexString: "#ADCE8F")], center: .center, startRadius: 0, endRadius: 250)
                .frame(width: 500, height: 500)
                .clipShape(Circle())
                .blur(radius: 200)
                .offset(x: 160, y: 400)

            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome to")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hexString: "#464646"))
                Text("Talking Fingers")
                    .font(.system(size: 48)).bold()
                    .foregroundColor(Color(hexString: "#464646"))
                Button(action: onNext) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .foregroundColor(Color(hexString: "#97C171"))
                            .frame(width: 338, height: 45)
                        Text("Get Started")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }
}

private struct MacObView2: View {
    let onNext: () -> Void
    enum Handedness { case left, right }
    @Binding var name: String
    @Binding var handedness: String?
    @State private var selectedHand: Handedness? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hexString: "#464646"))
                    Text("Talking Fingers")
                        .font(.system(size: 48)).bold()
                        .foregroundColor(Color(hexString: "#464646"))
                }
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Text("Let's set you up.")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hexString: "#464646"))
                    TextField("Your Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 338)
                    (Text("In American Sign Language (ASL), dominant hand determines how you sign. ")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hexString: "#464646"))
                     + Text("Select your dominant hand.")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hexString: "#464646")))
                    HStack(spacing: 12) {
                        SelectHandButton(title: "Left", isSelected: selectedHand == .left) { selectedHand = .left }
                        SelectHandButton(title: "Right", isSelected: selectedHand == .right) { selectedHand = .right }
                    }
                    Button(action: {
                        if let hand = selectedHand {
                            handedness = hand == .left ? "left" : "right"
                        }
                        onNext()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 100)
                                .foregroundColor(Color(hexString: "#97C171"))
                                .frame(width: 338, height: 45)
                            Text("Start Learning")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            if selectedHand == nil || name.isEmpty {
                                RoundedRectangle(cornerRadius: 100)
                                    .foregroundColor(Color.white.opacity(0.4))
                                    .frame(width: 338, height: 45)
                            }
                        }
                    }
                    .disabled(selectedHand == nil || name.isEmpty)
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func SelectHandButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .frame(width: 165, height: 181)
                    .foregroundColor(isSelected ? Color(hexString: "#FDF2D8") : Color(hexString: "#FCFCFC"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hexString: "#E2E2E2"), lineWidth: 1)
                    )
                VStack(spacing: 8) {
                    // Placeholder icons for macOS; replace with images if available in asset catalog
                    Image(title == "Left" ? "left" : "right")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hexString: "#464646"))
                    Text(title)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hexString: "#464646"))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct MacObView3: View {
    let onNext: () -> Void
    @State var name: String

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Nice to meet you,")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hexString: "#464646"))
                    Text("\(name)!")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(hexString: "#559AD2"))
                        .padding(.bottom)
                    (Text("Learning to fingerspell is essential for your ASL journey. ")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hexString: "#464646"))
                     + Text("Let’s start with your name!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hexString: "#464646")))
                }
                .padding([.bottom, .trailing, .leading])

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(name.lowercased()), id: \.self) { letter in
                        HStack(alignment: .top, spacing: 12) {
                            Image("\(letter)")
                                .resizable()
                                .frame(width: 54, height: 72)
                            Text(letter.uppercased())
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hexString: "#464646"))
                            Text(signDescription(for: letter))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hexString: "#464646"))
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding()

                Button(action: onNext) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .foregroundColor(Color(hexString: "#97C171"))
                            .frame(width: 338, height: 45)
                        Text("Try It Out")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private let signDescriptions: [Character: String] = [
        "a": "Fist with thumb on side",
        "b": "Open hand, thumb across palm",
        "c": "C-shaped curve",
        "d": "Index up, thumb touches middle finger",
        "e": "Fingers curled into palm",
        "f": "Index + thumb touch (circle)",
        "g": "Sideways point with index",
        "h": "Index + middle together, horizontal",
        "i": "Pinky finger up",
        "j": "Trace J shape with pinky",
        "k": "V shape with index + thumb",
        "l": "L shape with thumb + index",
        "m": "Thumb under three fingers",
        "n": "Thumb under two fingers",
        "o": "Fingers form a circle",
        "p": "Thumb and middle touching, pointer pointing down",
        "q": "Pointer curled + middle and thumb pointing down",
        "r": "Index + middle crossed",
        "s": "Fist with thumb over fingers",
        "t": "Thumb between fingers",
        "u": "Index + middle up together",
        "v": "V shape fingers",
        "w": "Three fingers up",
        "x": "Hooked index finger",
        "y": "Thumb + pinky extended",
        "z": "Trace Z in air"
    ]

    private func signDescription(for letter: Character) -> String {
        signDescriptions[letter] ?? "No description available"
    }
}

private struct MacObView4: View {
    let onNext: () -> Void
    @State var name: String
    @State private var currentIndex: Int = 0
    @State private var isPassed: Bool = false
    @State private var finished = false
    @State private var completedWords: Set<Int> = []
    private let passThreshold: Double = 0.85

    var body: some View {
        let letters = Array(name.uppercased())
        VStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Try fingerspelling your name!")
                    .font(.system(size: 17))
                    .foregroundColor(Color(hexString: "#464646"))
            }
            HStack(spacing: 8) {
                ForEach(letters.indices, id: \.self) { i in
                    Text(String(letters[i]))
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(i == currentIndex ? Color(hexString: "#464646") : Color(hexString: "#CCCCCC"))
                    if i != letters.count - 1 {
                        Text("-")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(Color(hexString: "#CCCCCC"))
                    }
                }
            }
            if currentIndex < letters.count {
                SigningPracticeView(
                    signName: String(letters[currentIndex]),
                    onConfidenceChange: { score in
                        if score >= passThreshold && !isPassed {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isPassed = true
                                completedWords.insert(currentIndex)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isPassed = false
                                completedWords.insert(currentIndex)
                                if currentIndex < letters.count - 1 {
                                    currentIndex += 1
                                } else {
                                    finished = true
                                }
                            }
                        }
                    }
                )
                .id(currentIndex)
                nameProgressCircles
                    .padding(.bottom, 24)
            }
            if finished {
                Button(action: onNext) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .foregroundColor(Color(hexString: "#97C171"))
                            .frame(width: 338, height: 45)
                        Text("Next")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .padding()
    }

    private var nameProgressCircles: some View {
        let letters = Array(name.uppercased())
        return Group {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(letters.enumerated()), id: \.offset) { index, _ in
                            circleIcon2(for: index)
                                .id("circle-\(index)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .onChange(of: currentIndex) { _, newIndex in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("circle-\(newIndex)", anchor: .center)
                    }
                }
            }
        }
    }

    private static let progressCircleColumnWidth: CGFloat = 72
    private static let progressCircleDiameter: CGFloat = 52

    @ViewBuilder
    private func circleIcon2(for index: Int) -> some View {
        let letters = Array(name.uppercased())
        let isCompleted = completedWords.contains(index)
        let isCurrent = index == currentIndex && !finished
        let wordLabel = index < letters.count ? String(letters[index]) : ""
        let d = Self.progressCircleDiameter

        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(circleFill(isCompleted: isCompleted, isCurrent: isCurrent))
                    .frame(width: isCurrent ? d + 10 : d, height: isCurrent ? d + 10 : d)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hexString: "#71A046"))
                } else if isCurrent {
                    Image(systemName: "lightbulb.max")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hexString: "#F8BC3A"))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hexString: "#B3B3B3"))
                }
            }
            .frame(width: Self.progressCircleColumnWidth, height: Self.progressCircleColumnWidth, alignment: .center)
            Text(wordLabel)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hexString: "#767676"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(isCurrent ? 1 : 0)
                .frame(height: 20)
        }
        .frame(width: Self.progressCircleColumnWidth)
        .animation(.easeInOut(duration: 0.3), value: currentIndex)
    }

    private func circleFill(isCompleted: Bool, isCurrent: Bool) -> Color {
        if isCompleted { return Color(hexString: "#EAF3E3") }
        if isCurrent { return Color(hexString: "#FDF2D8") }
        return Color.gray.opacity(0.12)
    }
}
#endif

