//
//  MainView.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/21/24.
//

import SwiftUI

final class MainViewModel:ObservableObject{
    @Published var showMenu:Bool = false
    @Published var userData:DBUser? = nil
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = ""
    
    
    
    func showAlertTitle(title:String){
        alertMessage = title
        showAlert = true
    }
    
    func getUserData(){
        guard let uid = AuthenticationManager.shared.getUserData()?.uid else {
            showAlertTitle(title: "User not found")
            return
        }
        
        FirestoreManger.shared.getDBUser(userId: uid) {[weak self] dbUser, error in
            guard let self = self else{return}
            if let error = error{
                showAlertTitle(title: error.localizedDescription)
                return
            }
            guard let dbUser = dbUser else {
                showAlertTitle(title: "User not found")
                return
            }
            
            self.userData = dbUser
        }
    }
    
}

struct MainView: View {
    @StateObject var mainViewModel = MainViewModel()
    @State var tabSelected:Int = 0
    var body: some View {
        TabView(selection: $tabSelected) {
            HomeView(tabSelected: $tabSelected)
                .tag(0)
            MapView()
                .tag(1)
        }
        .alert(isPresented: $mainViewModel.showAlert, content: {
            Alert(title: Text(mainViewModel.alertMessage))
        })
        .ignoresSafeArea()
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        
        .onAppear{
            mainViewModel.getUserData()
        }
    }
}

#Preview {
    MainView()
}
