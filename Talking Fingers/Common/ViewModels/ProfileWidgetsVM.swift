//
//  ProfileWidgetsVM.swift
//  Talking Fingers
//
//  Created by Assistant on 4/19/26.
//

import SwiftUI
import Combine

class ProfileWidgetsVM: ObservableObject {
    @Published var displayedWidgets: [ProfileWidget] = [] {
        didSet {
            saveWidgets()
        }
    }
    
    private let userDefaultsKey = "profileWidgets"
    private let defaultWidgets: [ProfileWidget] = [
        ProfileWidget(type: .streak, order: 0),
        ProfileWidget(type: .wordsLearned, order: 1),
        ProfileWidget(type: .recentProgress, order: 2),
        ProfileWidget(type: .dailyChallenge, order: 3),
        ProfileWidget(type: .masteryBadges, order: 4)
    ]
    
    init() {
        loadWidgets()
    }
    
    private func loadWidgets() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([ProfileWidget].self, from: data) {
            displayedWidgets = decoded.sorted(by: { $0.order < $1.order })
            normalizeOrders()
        } else {
            displayedWidgets = defaultWidgets
        }
    }
    
    private func saveWidgets() {
        if let data = try? JSONEncoder().encode(displayedWidgets) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func addWidget(type: WidgetType) {
        guard !displayedWidgets.contains(where: { $0.type == type }) else { return }
        let newOrder = (displayedWidgets.map { $0.order }.max() ?? -1) + 1
        let newWidget = ProfileWidget(type: type, order: newOrder)
        displayedWidgets.append(newWidget)
        displayedWidgets.sort(by: { $0.order < $1.order })
        normalizeOrders()
    }
    
    func removeWidget(at offsets: IndexSet) {
        displayedWidgets.remove(atOffsets: offsets)
        normalizeOrders()
    }
    
    func moveWidget(from source: IndexSet, to destination: Int) {
        displayedWidgets.move(fromOffsets: source, toOffset: destination)
        normalizeOrders()
    }
    
    func applyOrderedWidgets(_ widgets: [ProfileWidget]) {
        displayedWidgets = widgets
        normalizeOrders()
    }
    
    private func normalizeOrders() {
        for (index, widget) in displayedWidgets.enumerated() {
            displayedWidgets[index].order = index
        }
    }
    
    var availableWidgets: [WidgetType] {
        WidgetType.allCases.filter { type in
            !displayedWidgets.contains(where: { $0.type == type })
        }
    }
    
    var removableWidgets: [ProfileWidget] {
        displayedWidgets
    }
}