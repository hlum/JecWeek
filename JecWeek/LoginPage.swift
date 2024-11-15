//
//  LoginPage.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/15/24.
//

import SwiftUI

struct LoginPage: View {
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
    }
}

#Preview {
    LoginPage()
}
