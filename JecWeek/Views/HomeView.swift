//
//  ContentView.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/13/24.
//


import SwiftUI

//final class MockDataProvider{
//    static let shared = MockDataProvider()
//    var gotTag:[JsonDataModel] = [
//        JsonDataModel(
//            id:"7E4F768A-9E11-45EB-9D94-3C3BB7C4C2A4",
//            buildingNo: 0,
//            images: [
//                "https://image.minkou.jp/images/school_img/21642/750_6831ae617fac95d66ee485fd6f84dcbf20fb30b7.jpg",
//                "https://s3-ap-northeast-1.amazonaws.com/license-shinronavi/images/6217/midium.jpg",
//                "https://fastly.4sqi.net/img/general/600x600/499674011_JFEz9JKbTXSeloXXXcE9oY-QmkhYy0R5ztNXyfoRDBY.jpg"
//            ],
//            buildingName: "本館",
//            adress: "東京都新宿区百人町１丁目２５−４",
//            date: ISO8601DateFormatter().date(
//                from: "2024-11-14T00:00:00Z"
//            ) ?? Date()
//        )    ]
//    
//    func getTags() -> [JsonDataModel] {
//        return gotTag
//    }
//}

final class HomeViewModel:ObservableObject{
    @Published var cards:[JsonDataModel] = []
    @Published var showAlert:Bool = false
    @Published var alertTitle:String = ""
    @Published var userCardsId:[String] = []
    @Published var userData:AuthDataResultModel? = nil
    private let nfcManager:NFCManager = NFCManager()
    
    
    init() {
        Task{
            await self.getUserTagFromFirestore()
        }
        self.cards = JsonFileReader.shared.loadPlaceData() ?? []
        nfcManager.onCardDataUpdate = { [weak self] data,error in
            if let error = error{
                Task{
                    await self?.showAlertTitle(alertTitle: error.localizedDescription)
                }
            }
            guard let data = data else {
                Task{
                    await self?.showAlertTitle(alertTitle: "No data found")
                }
                return
            }
            guard let userData = AuthenticationManager.shared.getUserData() else {
                Task{
                    await self?.showAlertTitle(alertTitle: "User not found")
                }
                return
            }
            //Save the scanned card id to firestore
            FirestoreManger.shared
                .updateUserCardPossession(userId: userData.uid, cardId: data.id)
            
            Task{
                await self?.getUserTagFromFirestore()
            }
        }
    }
    
    
    func getUserData(){
        userData = AuthenticationManager.shared.getUserData()
        dump(userData)
    }
    
    @MainActor
    func showAlertTitle(alertTitle:String){
        showAlert = true
        self.alertTitle = alertTitle
    }
    
    func getUserTagFromFirestore()async {
        guard let userData = AuthenticationManager.shared.getUserData()else{
            await showAlertTitle(alertTitle: "User not found")
            return
        }
        FirestoreManger.shared
            .getUserTagData(userId: userData.uid, completion: {[weak self] cards, error in
                if let error = error {
                    Task{
                        await self?.showAlertTitle(alertTitle: error.localizedDescription)
                    }
                }
                
                self?.userCardsId = cards
            })
    }
                            
                        
    
    func scan(){
        nfcManager.scan()
    }
    
    func userIsLogin()->Bool{
        AuthenticationManager.shared.userIsLogin()
    }
}

//MARK: HomeView
struct HomeView: View {
    @State var refreshedButtonAnimate:Bool = false
    @State var showLogOutButton:Bool = false
    @State var userIsNotLogIn = true
    @State var selectedCardIndex:Int = 0
    @State var showDetailSheet:Bool = false
    @State var tabSelection = 0
    @ObservedObject var vm = HomeViewModel()
    var body: some View {
        ZStack(alignment:.center){
            CustomColors.backgroundColor.ignoresSafeArea()
            backgroundView
            VStack {
                titleView
                
                Spacer()
                TabView(selection: $tabSelection) {
                    ForEach(vm.cards.indices, id: \.self) { index in
                        Button {
                            showDetailSheet.toggle()
                        } label: {
                            cardView(for: vm.cards[index])
                                .tag(index) // Set the tag to the current index
                            
                        }
                        .foregroundStyle(checkUserHasTag(tag: vm.cards[index]) ? Color.black : Color.gray)
                        .disabled(!checkUserHasTag(tag: vm.cards[index]))
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                
                Spacer()
                
                scanButton
            }
        }
        .actionSheet(isPresented: $showLogOutButton, content: {
            ActionSheet(title: Text("Log Out"),
                        message: Text("Are you sure you want to log out?"),
                        buttons: [
                            .destructive(Text("Log Out"), action: {
                                Task{
                                    try? await AuthenticationManager.shared.logOut()
                                    userIsNotLogIn = !vm.userIsLogin()
                                }
                            }),
                            .cancel()
                        ])
        })
        .onAppear{
            //check the user is login or not
            userIsNotLogIn = !vm.userIsLogin()
            vm.getUserData()
        }
        .alert(isPresented: $vm.showAlert, content: {
            Alert(title: Text(vm.alertTitle))
        })
        .onChange(of:tabSelection, { _, newValue in
            selectedCardIndex = tabSelection
        })
        .sheet(isPresented: $showDetailSheet, content: {
            DetailSheetView(placeData: vm.cards[selectedCardIndex], showDetailSheet: $showDetailSheet)
        })
        .fullScreenCover(isPresented: $userIsNotLogIn, content: {
            LoginPage(userIsNotLogIn: $userIsNotLogIn)
        })
    }
}



//MARK: VIEWS
extension HomeView{
    private var backgroundView:some View{
        ZStack{
            Image(.lines)
                .resizable()
                .scaledToFit()
                .blur(radius: 10)
        }
    }
    private var titleView:some View{
        HStack{
            VStack(alignment:.leading){
                Text("日本電子専門学校")
                    .font(.system(size: 30, weight: .semibold))
                Text("取得したタッグ")
                    .font(.system(size: 19, weight: .thin))
            }
            .padding(20)
            Spacer()
            VStack{
                Button {
                    showLogOutButton.toggle()
                } label: {
                    Image(.menu)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .padding(20)
                }
                
                Button {
                    Task{
                        await vm.getUserTagFromFirestore()
                        refreshedButtonAnimate.toggle()
                    }
                } label: {
                    if #available(iOS 18, *){
                        Image(systemName: "arrow.clockwise")
                            .symbolEffect(.rotate, value: refreshedButtonAnimate)
                            .font(.title)
                            .tint(.black)
                            .padding(.trailing,10)
                    }else{
                        Image(systemName: "arrow.clockwise")
                            .font(.title)
                            .padding(.trailing,10)
                            .tint(.black)
                    }
                    
                }
            }
        }
    }
    
    private func cardView(for nfcData:JsonDataModel)->some View{
        ZStack{
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .frame(width:300,height:450)
                .shadow(color: CustomColors.shadowColor,radius: 16,x:1,y:1)
            
            VStack{
                if !checkUserHasTag(tag: nfcData){
                    Image(.lock)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 130, height: 130)
                        .shadow(radius: 10,x:10,y:10)
                        .padding(10)
                }else{
                    AsyncImage(url: URL(string: nfcData.images[0])){
                        image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                            .cornerRadius(10)
                            .shadow(radius: 10,x:10,y:10)
                            .padding(10)
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                VStack(alignment:.leading){
                    Text(nfcData.buildingName)
                        .font(.system(size: 40, weight: .bold))
                    Text("\(nfcData.adress)")
                        .font(.system(size:16, weight: .medium))
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.black)
                        .frame(width:200,height: 1)
                    
                    Text(nfcData.date,style: .date)
                        .font(.system(size: 16, weight: .medium))
                    
                }
                .padding(.bottom,150)
                
                
                
            }
        }
    }
    
    private var scanButton:some View{
        Button {
            
            vm.scan()
        } label: {
            HStack{
                Image(systemName: "wifi")
                    .font(.title)
                    .padding(.leading)
                Text("Scan")
                    .padding(.trailing)
            }
            .foregroundStyle(Color.white)
            .font(.title2)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(.blue)
            .cornerRadius(10)
            .shadow(color: CustomColors.shadowColor,radius: 4,x:1,y:1)
        }
    }
}


extension HomeView{
    private func checkUserHasTag(tag:JsonDataModel)->Bool{
        withAnimation(.easeInOut(duration: 10)){
            vm.userCardsId.contains(where: { $0 == tag.id })
        }
    }
}
#Preview {
    HomeView()
}
