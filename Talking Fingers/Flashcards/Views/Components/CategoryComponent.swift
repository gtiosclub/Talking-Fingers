//
//  CategoryComponent.swift
//  Talking Fingers
//
//  Created by Isha Jain on 2/5/26.
//

import SwiftUI

struct CategoryComponent: View {
    let title: String

    var body: some View {
        HStack(spacing: 16) {
            
            // ICON
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.95, green: 0.75, blue: 0.20))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconName(for: title))
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                
                Text(subtitle(for: title))
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        
        .background(Color(red: 0.96, green: 0.92, blue: 0.80))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.95, green: 0.75, blue: 0.20), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

// MARK: - Helpers

private func iconName(for title: String) -> String {
    switch title.lowercased() {
    case "alphabet": return "character"
    case "numbers": return "number"
    case "greetings": return "hand.wave"
    case "food": return "fork.knife"
    case "people": return "person.2"
    case "time", "date/time": return "clock"
    case "personal information": return "person.crop.circle"
    case "family": return "person.3"
    case "verbs": return "bolt.fill"
    case "feelings/emotions": return "face.smiling"
    case "locations": return "mappin.and.ellipse"
    case "common descriptors": return "text.alignleft"
    case "common objects": return "cube.box"
    default: return "square"
    }
}

private func subtitle(for title: String) -> String {
    switch title.lowercased() {
    case "alphabet": return "Learn fingerspelling letters A–Z"
    case "numbers": return "Learn counting and number signs"
    case "greetings": return "Say hello and common phrases"
    case "food": return "Sign everyday foods and drinks"
    case "people": return "Learn family and people signs"
    case "time", "date/time": return "Tell days, times, and dates"
    case "personal information": return "Name, age, and basic info"
    case "family": return "Family member signs"
    case "verbs": return "Action words and verbs"
    case "feelings/emotions": return "Express emotions and moods"
    case "locations": return "Places and directions"
    case "common descriptors": return "Adjectives and descriptions"
    case "common objects": return "Everyday objects"
        
    default: return ""
    }
}

#Preview {
    ZStack {
        Color.categoryComponentColor.ignoresSafeArea()
        VStack(spacing: 12) {
            CategoryComponent(title: "Alphabet")
            CategoryComponent(title: "Numbers")
            CategoryComponent(title: "Greetings")
        }
        .padding()
    }
}
