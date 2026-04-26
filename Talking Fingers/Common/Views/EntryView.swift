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
    @State private var showOnboarding: Bool = false
    @State private var pushOnboarding: Bool = false
    @State private var pendingEmail: String = ""
    @State private var pendingPassword: String = ""
    @Environment(AuthenticationViewModel.self) var authVM
    var body: some View {
        NavigationStack {
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
                    Register(onSuccess: { email, password in
                        // After successful register, present onboarding first
                        pendingEmail = email
                        pendingPassword = password
                        pushOnboarding = true
                    })
                        .environment(authVM)
                }
            }
            .background(
                NavigationLink(isActive: $pushOnboarding) {
                    OnboardingView(onFinished: { name, handedness in
                        // After onboarding finishes, register with the name and handedness from onboarding, then log in
                        Task {
                            authVM.setSessionHandedness(handedness)
                            await authVM.register(email: pendingEmail, password: pendingPassword, name: name, handedness: handedness)
                            await authVM.login(email: pendingEmail, password: pendingPassword)
                        }
                    })
                    .environment(authVM)
                } label: {
                    EmptyView()
                }
                .hidden()
            )
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

                .universalAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
            SecureField("Password", text: $password)
                #if !os(macOS)
                .textContentType(.oneTimeCode)
                #endif

                .universalAutocapitalization(.never)
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
    let onSuccess: (_ email: String, _ password: String) -> Void
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var confirmPasswordErrorMessage: String?
    @State private var error: Bool = false
    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .universalAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
            SecureField("Password", text: $password)
                #if !os(macOS)
                .textContentType(.none)
                #endif

                .universalAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
            Button(action: {
                // Defer registration until after onboarding completes
                onSuccess(email, password)
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
