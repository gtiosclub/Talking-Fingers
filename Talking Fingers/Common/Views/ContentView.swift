//
//  ContentView.swift
//  Talking Fingers
//
//  Created by Nikola Cao on 1/24/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthenticationViewModel.self) var authVM
    
    var body: some View {
        if authVM.currentUser != nil {
            TabsView()
                .environment(authVM)
        } else {
            EntryView()
                .environment(authVM)
        }
    }
}

#Preview {
    ContentView()
}
