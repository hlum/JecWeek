//
//  GoogleSignInHelper.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/15/24.
//

import Foundation
import GoogleSignIn
import GoogleSignInSwift

final class SignInGoogleHelper{

    @MainActor
    func signIn()async throws -> GoogleSignInResultModel{
        guard let topVC = Utilities.shared.topViewController()else{
            throw URLError(.cannotFindHost)
        }
        
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)

        guard let idToken:String = gidSignInResult.user.idToken?.tokenString else{
            throw URLError(.badServerResponse)
        }
        let acessToken:String = gidSignInResult.user.accessToken.tokenString
        let name:String? = gidSignInResult.user.profile?.name
        let email:String? = gidSignInResult.user.profile?.email
        
        
        
        let tokens = GoogleSignInResultModel(idToken: idToken, acessToken: acessToken,name: name,email: email)
        
        return tokens
    }
}

enum customSignInError:Error{
    case invalidEmail
}
