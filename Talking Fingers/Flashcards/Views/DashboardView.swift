//
//  DashboardView.swift
//  Talking Fingers
//
//  Created by Isha Jain on 2/5/26.
//

import SwiftUI

struct DashboardView: View {
    @State private var flashcardVM = FlashcardVM()

    // Compute categories that are in progress (have at least one non-new and non-mastered card)
    private var inProgressCategories: [(category: String, progress: Float, mode: String)] {
        let grouped = Dictionary(grouping: flashcardVM.fakeFlashcards) { $0.category }
        return grouped.compactMap { (category, cards) in
            let progress = flashcardVM.returnProgress(flashcards: cards)
            // Only show categories that are actually in progress (not 0% and not 100%)
            guard progress > 0 && progress < 100 else { return nil }

            // Decide mode based on average progress
            let mode = progress < 50 ? "Learn" : "Exercise"
            return (category: category, progress: progress, mode: mode)
        }
        .sorted { $0.progress > $1.progress }
        .prefix(2)
        .map { $0 }
    }

    private var allCategories: [String] {
        TermCategory.allCases.map { $0.rawValue.capitalized }
    }

    private var dailyQueue: DailyReviewQueue {
        flashcardVM.generateDailyReviewQueue(limit: 5)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Search icon
                HStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal)

                // MARK: - In Progress
                if !inProgressCategories.isEmpty {
                    Text("In Progress")
                        .font(.system(size: 26, weight: .bold))
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(Array(inProgressCategories.enumerated()), id: \.element.category) { index, item in
                                InProgressCard(
                                    category: item.category,
                                    mode: item.mode,
                                    progress: item.progress,
                                    backgroundColor: index == 0
                                        ? Color(red: 0.78, green: 0.85, blue: 0.93)   // blue
                                        : Color(red: 0.96, green: 0.92, blue: 0.80)    // cream
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // MARK: - Daily Challenge
                Text("Daily Challenge")
                    .font(.system(size: 26, weight: .bold))
                    .padding(.horizontal)

                DailyChallengeCard(
                    streak: 3,
                    completed: dailyQueue.cards.count,
                    total: dailyQueue.requestedLimit
                )
                .padding(.horizontal)

                // MARK: - Categories
                Text("Categories")
                    .font(.system(size: 26, weight: .bold))
                    .padding(.horizontal)

                let columns = [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(allCategories, id: \.self) { category in
                        CategoryComponent(title: category)
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - In Progress Card

private struct InProgressCard: View {
    let category: String
    let mode: String
    let progress: Float
    let backgroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Illustration placeholder using the asset if available, else SF Symbol
            Image(category == "Greetings" ? "greetingsIllustration" : "dummySign")
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .center, spacing: 4) {
                Text("Continue \(mode)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Text(category)
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity)

            // Progress bar
            HStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.6))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.45, green: 0.65, blue: 0.25))
                            .frame(width: geo.size.width * CGFloat(progress / 100), height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(Int(progress))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Jump In link
            HStack {
                Spacer()
                Text("Jump In")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.primary)
        }
        .padding(14)
        .frame(width: 170)
        .background(backgroundColor)
        .cornerRadius(20)
    }
}

// MARK: - Daily Challenge Card

private struct DailyChallengeCard: View {
    let streak: Int
    let completed: Int
    let total: Int

    var progress: CGFloat {
        CGFloat(Double(completed) / Double(max(total, 1)))
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("\(streak) Day Streak")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.orange)
                    Text("🔥")
                        .font(.system(size: 14))
                }

                Text("Start Challenge")
                    .font(.system(size: 24, weight: .bold))

                // Progress bar
                HStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.5))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0.45, green: 0.65, blue: 0.25))
                                .frame(width: geo.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(completed)/\(total)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Placeholder icon for the lunchbox illustration
            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.brown.opacity(0.6))
        }
        .padding(18)
        .background(Color(red: 0.96, green: 0.90, blue: 0.72))
        .cornerRadius(20)
    }
}

#Preview {
    DashboardView()
}
