//
//  ContentView.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/13/24.
//

import SwiftUI

final class HomeViewModel:ObservableObject{
    @Published var nfcData:[NFCData] = []
    @Published var showAlert:Bool = false
    @Published var alertTitle:String = ""
    
    private let nfcManager = NFCManager()
    
    init() {
        self.nfcData = JsonFileReader.shared.loadPlaceData() ?? []
    }
    
    @MainActor
    func showAlertTitle(alertTitle:String){
        showAlert = true
        self.alertTitle = alertTitle
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
                .fill(CustomColors.lightGray)
                .frame(width:300,height:450)
                .shadow(color: CustomColors.shadowColor,radius: 10,x:10,y:10)

            VStack{
                AsyncImage(url: URL(string: nfcData.images[0])) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250, height: 150)
                        .padding(10)
                } placeholder: {
                    Image(systemName: "person.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .padding(10)
                }
                .padding(.bottom,40)
                
                VStack(alignment:.leading){
                    Text(nfcData.buildingName)
                        .font(.system(size: 24, weight: .bold))
                    Text("\(nfcData.adress)")
                        .font(.system(size: 13, weight: .medium))
                    Text("モバイルアプリケーション開発科")
                        .font(.system(size: 13, weight: .medium))

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
#Preview {
    HomeView()
}
