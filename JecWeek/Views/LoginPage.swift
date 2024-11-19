//
//  LoginPage.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/15/24.
//

import SwiftUI


final class LoginPageViewModel:ObservableObject{
    @Published var showAlert : Bool = false
    @Published var alertTitle : String = ""
    
    func signInWithGoogle()async{
        
        let helper = SignInGoogleHelper()
        
        do {
            let tokens = try await helper.signIn()
            let authDataResult = try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
            try FirestoreManger.shared
                .storeUserDataInFirestore(
                    userData: authDataResult
                )
        } catch {
            print(error.localizedDescription)
            await showAlertTitle(alertTitle: error.localizedDescription)
            try? await AuthenticationManager.shared.deleteUser()
            await showAlertTitle(alertTitle: error.localizedDescription)
        }
    }
    
    
    func userIsLogin()->Bool{
        AuthenticationManager.shared.userIsLogin()
    }
    
    @MainActor
    private func showAlertTitle(alertTitle:String){
        self.showAlert = true
        self.alertTitle = alertTitle
    }
}

struct LoginPage: View {
    @Binding var userIsNotLogIn:Bool
    @StateObject var vm = LoginPageViewModel()
    var body: some View {
        ZStack{
            CustomColors.backgroundColor.ignoresSafeArea()
            Image(.lines)
                .resizable()
                .scaledToFit()
                .blur(radius: 10)

            VStack{
                Text("日本電子専門学校")
                    .font(.system(size: 40))
                    .bold()
                    .padding()
                    
                Text("スタンプラリー")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.white)
                    .bold()
                    .font(.system(size: 30))
                    .background(CustomColors.darkGreen)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                Spacer()
                
                Button {
                    Task{
                        await vm.signInWithGoogle()
                        userIsNotLogIn = !vm.userIsLogin()
                        print(vm.userIsLogin())
                    }
                } label: {
                    Text("Login")
                        .font(.title)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(.blue)
                        .foregroundStyle(Color.white)
                        .cornerRadius(10)
                        .padding()
                        .shadow(radius: 10)
                        
                    
                }

                
            }
        }
        .alert(isPresented: $vm.showAlert, content: {
            Alert(title: Text(vm.alertTitle))
        })
    }
}

#Preview {
    LoginPage(userIsNotLogIn: .constant(true))
}
