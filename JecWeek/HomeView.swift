//
//  ContentView.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/13/24.
//

import SwiftUI

final class HomeViewModel:ObservableObject{
    @Published var nfcData:NFCData?
    @Published var showAlert:Bool = false
    @Published var alertTitle:String = ""
    
    private let nfcManager = NFCManager()
    
    init() {
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
            self?.nfcData = data
        }
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

struct HomeView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
