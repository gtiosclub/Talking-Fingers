//
//  EntryView.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/27/26.
//

import Foundation
import SwiftUI

struct EntryView: View {
    @State private var isLogin: Bool = true
    @Environment(AuthenticationViewModel.self) var authVM
    var body: some View {
        if authVM.currentUser != nil {
            TabsView()
                .environment(authVM)
        } else {
            VStack {
                HStack {
                    Button(action: {self.isLogin = true}) {
                        VStack(spacing: 8) {
                            if (isLogin) {
                                Text("Login")
                                    .foregroundColor(Color.black)
                            } else {
                                Text("Login")
                                    .foregroundColor(Color.gray.opacity(0.3))
                            }
                        }
                    }
                    .padding()
                    Button(action: {self.isLogin = false}) {
                        VStack(spacing: 8) {
                            if (isLogin) {
                                Text("Register")
                                    .foregroundColor(Color.gray.opacity(0.3))
                            } else {
                                Text("Register")
                                    .foregroundColor(Color.black)
                            }
                        }
                    }
                    .padding()
                }
                if (isLogin) {
                    Login()
                        .environment(authVM)
                } else {
                    Register()
                        .environment(authVM)
                }
            }
        }
    }
}

struct Login: View {
    @Environment(AuthenticationViewModel.self) var authVM
    @State private var email = ""
    @State private var password = ""
    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
            SecureField("Password", text: $password)
                .textContentType(.oneTimeCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
            Button(action: {
                Task {
                    await authVM.login(email: email, password: password)
                }
            }) {
                if authVM.isLoading {
                    Text("Loading...")
                } else {
                    Text("Log In")
                }
            }
        }
        .padding()
        
    }
}

struct Register: View {
    @Environment(AuthenticationViewModel.self) var authVM
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var confirmPasswordErrorMessage: String?
    @State private var error: Bool = false
    var body: some View {
        VStack {
            TextField("Name", text: $name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .padding()
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
            SecureField("Password", text: $password)
                .textContentType(.none)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
            Button(action: {
                authVM.register(email: email, password: password, name: name)
                Task {
                    await authVM.login(email: email, password: password)
                }
            }) {
                if authVM.isLoading {
                    Text("Loading...")
                } else {
                    Text("Register")
                }
            }

        }
        .padding()
    }
}

struct HomeView: View {
    @Environment(AuthenticationViewModel.self) var authVM
    var body: some View {
        VStack {
            Text("Hello \(authVM.currentUser?.name ?? "Unknown")")
            Text("This is the main page for Talking Fingers")
            Text("Go to TabsView to add tabs for the other views")
            Button(action: {
                authVM.signOut()
            }) {
                Text("Sign Out")
            }
            .padding()
        }
    }
}

