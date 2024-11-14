//
//  ContentView.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/13/24.
//

import SwiftUI

final class MockDataProvider{
    static let shared = MockDataProvider()
    var gotTag:[NFCData] = [
        NFCData(
            id: UUID(
                uuidString: "7E4F768A-9E11-45EB-9D94-3C3BB7C4C2A4"
            ) ?? UUID(),
            buildingNo: 0,
            images: [
                "https://image.minkou.jp/images/school_img/21642/750_6831ae617fac95d66ee485fd6f84dcbf20fb30b7.jpg",
                "https://s3-ap-northeast-1.amazonaws.com/license-shinronavi/images/6217/midium.jpg",
                "https://fastly.4sqi.net/img/general/600x600/499674011_JFEz9JKbTXSeloXXXcE9oY-QmkhYy0R5ztNXyfoRDBY.jpg"
            ],
            buildingName: "本館",
            adress: "東京都新宿区百人町１丁目２５−４",
            date: ISO8601DateFormatter().date(
                from: "2024-11-14T00:00:00Z"
            ) ?? Date()
            )    ]
    
    
    func getTags() -> [NFCData] {
        return gotTag
    }
}

final class HomeViewModel:ObservableObject{
    @Published var nfcData:[NFCData] = []
    @Published var showAlert:Bool = false
    @Published var alertTitle:String = ""
    @Published var userTag:[NFCData] = []
    
    private let nfcManager = NFCManager()
    
    init() {
        self.getUserTag()
        self.nfcData = JsonFileReader.shared.loadPlaceData() ?? []
    }
    
    @MainActor
    func showAlertTitle(alertTitle:String){
        showAlert = true
        self.alertTitle = alertTitle
    }
    
    func getUserTag(){
        userTag = MockDataProvider.shared.getTags()
    }
    
    func scan(){
        nfcManager.scan()
    }
}

//MARK: HomeView
struct HomeView: View {
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
                        ForEach(vm.nfcData.indices, id: \.self) { index in
                            cardView(for: vm.nfcData[index])
                                .tag(index) // Set the tag to the current index
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    
                    Spacer()
                    
                    scanButton

                }
                .padding()
            }
            .alert(isPresented: $vm.showAlert, content: {
                Alert(title: Text(vm.alertTitle))
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
            .padding(.leading,10)
            Spacer()
            Button {
                print("Menu")
            } label: {
                Image(.menu)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .padding(.trailing)
            }
        }
    }
    
    private func cardView(for nfcData:NFCData)->some View{
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
    private func checkUserHasTag(tag:NFCData)->Bool{
        vm.userTag.contains(where: { $0.id == tag.id })
    }
}
#Preview {
    HomeView()
}
