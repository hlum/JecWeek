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
    @State var userIsNotLogIn:Bool = true
    @State var menuOffsetForAnimation:CGFloat = 0
    @StateObject var mainViewModel = MainViewModel()
    @State var tabSelected:Int = 0
    @State var showMenu:Bool = false
    var body: some View {
        ZStack{
            switch tabSelected {
            case 0:
                HomeView(tabSelected: $tabSelected)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        )
                    )
            case 1:
                MapView()
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        )
                    )
            default:
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $userIsNotLogIn, content: {
            LoginPage(userIsNotLogIn: $userIsNotLogIn)
        })

        .alert(isPresented: $mainViewModel.showAlert, content: {
            Alert(title: Text(mainViewModel.alertMessage))
        })
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        
        .onAppear{
            mainViewModel.getUserData()
            userIsNotLogIn = !AuthenticationManager.shared
                .userIsLogin()
        }
        
        .overlay(menuButton,alignment: .topTrailing)
        .overlay(alignment: .trailing, content: {
            if showMenu{
                menuView
                    .shadow(radius: 8,x:-10,y:10)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                    .offset(x:menuOffsetForAnimation)
            }
        })
    }
}








extension MainView{
    private var menuButton:some View{
        Button {
            withAnimation(.bouncy) {
                showMenu = true
            }
        } label: {
            Image(.menu)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding(.trailing,30)
                .padding(.top,5)
                .shadow(radius: 10)

        }
    }
    private var menuView:some View{
        VStack(alignment:.leading){
            
            HStack{
                AsyncImage(
                    url: URL(string: mainViewModel.userData?.photoUrl ?? "")
                ) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipped()
                        .cornerRadius(50)
                        .overlay(RoundedRectangle(cornerRadius: 44)
                            .stroke(Color(.label), lineWidth: 1)
                        )
                        
                } placeholder: {
                    Image(.profilePic)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)

                }
                
                let userStudentNo = mainViewModel.userData?.email?.replacingOccurrences(
                    of: "@jec.ac.jp",
                    with: "さん"
                )
                Text(userStudentNo ?? "Guest")
                    .font(.title)
                    .bold()
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity,alignment: .leading)
                    

            }
            .padding(.leading,20)
            .padding(.top,20)
            
            Section{
                menuNavButton(tabNo: 0, title: "ホーム")
                menuNavButton(tabNo: 1, title: "マップ")
            }header:{
                Text("メニュー")
                    .bold()
            }
            .padding(.leading,10)
            Spacer()
            
            Section {
                Button {
                    withAnimation(.bouncy) {
                        showMenu = false
                    }
                    Task{
                        try? await AuthenticationManager.shared.logOut()
                        userIsNotLogIn = !AuthenticationManager.shared
                            .userIsLogin()
                    }
                } label: {
                    Text("Sign Out")
                        .padding()
                        .foregroundStyle(Color.red)
                        .font(.title3)
                        .frame(maxWidth: .infinity,alignment: .leading)
                        .frame(height: 55)
                        .background(.thinMaterial)
                        .cornerRadius(10)
                        .padding(.trailing,10)
                }
            }
            header:{
                Text("アカウント管理")
                    .bold()
            }
            .padding(.leading,10)
            Spacer()
        }
        .frame(width:300,height: UIScreen.main.bounds.height-100)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .gesture(
            DragGesture()
                .onChanged({ value in
                    withAnimation(.easeInOut){
                        if value.translation.width > 0{
                            menuOffsetForAnimation = value.translation.width
                        }
                    }
                })
                .onEnded{ value in
                    if value.translation.width > 100{
                        withAnimation(.bouncy){
                            menuOffsetForAnimation = 0
                            showMenu = false
                        }
                    }else{
                        menuOffsetForAnimation = 0
                        showMenu = true
                    }
                }
        )



    }
    
    private func menuNavButton(tabNo:Int,title:String)->some View{
        Button {
            withAnimation(.linear) {
                showMenu = false
                tabSelected = tabNo
            }
            } label: {
                Text(title)
                    .padding()
                    .foregroundStyle(Color.black)
                    .font(.title3)
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .frame(height: 55)
                    .background(.thinMaterial)
                    .cornerRadius(10)
                    .padding(.trailing,10)
                    .shadow(radius:tabSelected == tabNo ? 10 : 0)
            }
            .disabled(tabSelected == tabNo)
    }
}

#Preview {
    MainView()
}
