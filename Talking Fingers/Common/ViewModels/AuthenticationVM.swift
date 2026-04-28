//
//  AuthenticationViewModel.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/27/26.
//

@preconcurrency import FirebaseAuth
import FirebaseFirestore
import Observation

@Observable
class AuthenticationViewModel {
    var errorMessage: String?
    var isLoading = false
    var isInitializingSession = true
    var isLoggedIn = false
    var currentUser: User?
    var sessionHandedness: String?
    var auth: Auth
    private var handler: AuthStateDidChangeListenerHandle?

    var effectiveHandedness: String? {
        currentUser?.handedness ?? sessionHandedness
    }

    init() {
        self.auth = Auth.auth()
        self.handler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }

            if let user = user {
                Task {
                    await self.loadCurrentUserProfile(for: user, isLoggingIn: false)
                }
            } else {
                DispatchQueue.main.async {
                    self.currentUser = nil
                    self.isLoggedIn = false
                    self.isInitializingSession = false
                    self.sessionHandedness = nil
                }
            }
        }
    }
    
    deinit {
        if let handler = handler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    public var isSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)
            await loadCurrentUserProfile(for: authResult.user, fallbackEmail: email, isLoggingIn: true)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func register(email: String, password: String, name: String, handedness: String? = nil) {
        sessionHandedness = normalizeHandedness(handedness)
        auth.createUser(withEmail: email, password: password) {result, error in
            if let error = error {
                print("Error registering: \(error.localizedDescription)")
            } else {
                print("User registered: \(result?.user.uid ?? "")")
            }
            
            guard let user = result?.user else {return}
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Failed to set displayName: \(error.localizedDescription)")
                } else {
                    print("FirebaseAuth displayName set successfully")
                }
            }
            let newUser = User(userId: user.uid, name: name, email: email)
            newUser.handedness = handedness
            
            var userData: [String: Any] = [
                "userId": newUser.userId,
                "name": newUser.name,
                "email": newUser.email,
            ]
            if let handedness = handedness {
                userData["handedness"] = handedness
            }
            Firebase.db.collection("Users").document(newUser.userId).setData(userData) { err in
                if let err = err {
                    print("Error saving user: \(err)")
                } else {
                    print("User profile saved in Firestore")
                    DispatchQueue.main.async {
                        self.currentUser = newUser
                        self.sessionHandedness = newUser.handedness
                        self.isLoggedIn = true
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.sessionHandedness = nil
                self.isLoggedIn = false
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func setSessionHandedness(_ handedness: String?) {
        sessionHandedness = normalizeHandedness(handedness)
    }

    private func loadCurrentUserProfile(for authUser: FirebaseAuth.User, fallbackEmail: String? = nil, isLoggingIn: Bool) async {
        do {
            let document = try await Firebase.db.collection("Users").document(authUser.uid).getDocument()
            let data = document.data()
            let handedness = normalizeHandedness(data?["handedness"] as? String)

            let hydratedUser = User(
                userId: authUser.uid,
                name: (data?["name"] as? String) ?? authUser.displayName ?? "",
                email: (data?["email"] as? String) ?? authUser.email ?? fallbackEmail ?? "",
                handedness: handedness
            )

            DispatchQueue.main.async {
                self.currentUser = hydratedUser
                self.sessionHandedness = handedness
                self.isLoggedIn = true
                self.isLoading = false
                self.isInitializingSession = false
                if isLoggingIn {
                    print("Signed in as \(authUser.uid)")
                }
            }
        } catch {
            print("Failed to load user profile: \(error.localizedDescription)")

            let fallbackUser = User(
                userId: authUser.uid,
                name: authUser.displayName ?? "",
                email: authUser.email ?? fallbackEmail ?? ""
            )

            DispatchQueue.main.async {
                self.currentUser = fallbackUser
                self.sessionHandedness = self.normalizeHandedness(self.sessionHandedness)
                self.isLoggedIn = true
                self.isLoading = false
                self.isInitializingSession = false
                if isLoggingIn {
                    print("Signed in as \(authUser.uid)")
                }
            }
        }
    }

    private func normalizeHandedness(_ handedness: String?) -> String? {
        guard let normalized = handedness?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              normalized == "left" || normalized == "right" else {
            return nil
        }
        return normalized
    }
}
