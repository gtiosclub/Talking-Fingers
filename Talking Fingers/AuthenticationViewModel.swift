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
    var isLoggedIn = false
    var currentUser: User?
    var auth: Auth
    private var handler: AuthStateDidChangeListenerHandle?
    init() {
        self.auth = Auth.auth()
        self.handler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let user = user {
                    self.currentUser = User(userId: user.uid, name: user.displayName ?? "", email: user.email ?? "")
                } else {
                    self.currentUser = nil
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
            let user = authResult.user
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.isLoggedIn = true
                print("Signed in as \(user.uid)")
                self.currentUser = User(userId: user.uid, name: user.displayName ?? "", email: email)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func register(email: String, password: String, name: String) {
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
            
            let userData: [String: Any] = [
                "userId": newUser.userId,
                "name": newUser.name,
                "email": newUser.email,
            ]
            Firebase.db.collection("Users").document(newUser.userId).setData(userData) { err in
                if let err = err {
                    print("Error saving user: \(err)")
                } else {
                    print("User profile saved in Firestore")
                    DispatchQueue.main.async {
                        self.currentUser = newUser
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
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
}

