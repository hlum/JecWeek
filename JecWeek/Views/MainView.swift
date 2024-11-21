//
//  MainView.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/21/24.
//

import SwiftUI

struct MainView: View {
    @State var tabSelected:Int = 0
    var body: some View {
        TabView(selection: $tabSelected) {
            HomeView(tabSelected: $tabSelected)
                .tag(0)
        }
    }
}

#Preview {
    MainView()
}
