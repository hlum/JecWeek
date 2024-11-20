//
//  DetailSheetView.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/14/24.
//

import SwiftUI

import SwiftUI
import MapKit

struct DetailSheetView: View {
    var placeData:JsonDataModel
    @Binding var showDetailSheet:Bool
    
    var body: some View {
        
        
        ScrollView{
            VStack{
                imageSection
                    .shadow(color: .black, radius: 20, x: 0, y: 10)
                
                VStack(alignment: .leading,spacing: 16){
                    titleSection
                    Divider()
                    
                    descriptionSection
                    
                    Divider()
                }
                .frame(maxWidth: .infinity,alignment: .leading)
                .padding()
            }
        }
        .ignoresSafeArea()
        .background(.ultraThinMaterial)
        .overlay(backButton,alignment: .topLeading)
    }
}


extension DetailSheetView{
    private var imageSection: some View{
        TabView {
            ForEach(placeData.images, id: \.self) {
                AsyncImage(url: URL(string:$0)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width:UIDevice.current.userInterfaceIdiom == .pad ? nil : UIScreen.main.bounds.width)
                        .clipped()
                } placeholder: {
                    ProgressView()
                }
            }
        }
        .frame(height:500)
        .tabViewStyle(PageTabViewStyle())
    }
    
    private var titleSection:some View{
        VStack(alignment: .leading,spacing: 8){
            
            Text(placeData.buildingName)
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text(placeData.adress)
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
    private var descriptionSection:some View{
        VStack(alignment: .leading,spacing: 8){
            
            Text(placeData.buildingName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
        }
    }
        
    private var backButton : some View{
        Button {
            showDetailSheet.toggle()
        } label: {
            Image(systemName:"xmark")
                .font(.headline)
                .padding(16)
                .foregroundColor(.primary)
                .background(.thickMaterial)
                .cornerRadius(10)
                .shadow(radius: 4)
                .padding()
        }

    }
}


#Preview {
    DetailSheetView(
        placeData:
                JsonDataModel(
                id:"7E4F768A-9E11-45EB-9D94-3C3BB7C4C2A4",
                buildingNo: 0,
                images: [
                    "https://image.minkou.jp/images/school_img/21642/750_6831ae617fac95d66ee485fd6f84dcbf20fb30b7.jpg",
                    "https://s3-ap-northeast-1.amazonaws.com/license-shinronavi/images/6217/midium.jpg",
                    "https://fastly.4sqi.net/img/general/600x600/499674011_JFEz9JKbTXSeloXXXcE9oY-QmkhYy0R5ztNXyfoRDBY.jpg"
                ],
                buildingName: "本館",
                adress: "東京都新宿区百人町１丁目２５−４",
                date: ISO8601DateFormatter()
                    .date(
                        from: "2024-11-14T00:00:00Z"
                    ) ?? Date()
            ),
        showDetailSheet: .constant(
            true
        )
    )
}
