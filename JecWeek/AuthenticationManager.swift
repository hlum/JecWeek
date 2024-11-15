//
//  AuthenticationManager.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/15/24.
//

import Foundation
import FirebaseAuth

struct GoogleSignInResultModel{
    let idToken: String
    let acessToken : String
    let name : String?
    let email : String?
}



struct AuthDataResultModel:Hashable{
    let uid : String
    let email : String?
    let photoURL : String?
    
    init(user:User){
        self.email = user.email
        self.uid = user.uid
        self.photoURL = user.photoURL?.absoluteString
    }
}


final class AuthenticationManager{
    static let shared = AuthenticationManager()
    
    private init(){}
    
    
    func signInWithGoogle(tokens:GoogleSignInResultModel)async throws->AuthDataResultModel{
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.acessToken)
        return try await signInWithCredential(credential: credential)
    }
    
    func signInWithCredential(credential:AuthCredential)async throws->AuthDataResultModel{
        let authDataResult = try await Auth.auth().signIn(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    
    
}
