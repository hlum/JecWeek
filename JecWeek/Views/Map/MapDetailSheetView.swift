//
//  MapDetailSheetView.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/27/24.
//

import SwiftUI
import MapKit


struct MapDetailSheetView: View {
    var getDirection: ()->Void
    @Environment(\.presentationMode) var presentationMode
    @State var lookAroundScene:MKLookAroundScene?
    var placeData:JsonDataModel
    var body: some View {
        VStack{
            HStack{
                Text(placeData.buildingName)
                    .font(.system(size: 50))
                    .fontWeight(.bold)
                    .padding()
                Spacer()
                
                Button {
                    getDirection()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Direction")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .padding()
                        .background(.blue)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .padding(.trailing)
                }

            }
            if let _ = lookAroundScene{
                LookAroundPreview(scene: $lookAroundScene)
                    .frame(height: 300)
            }
        }
        .task {
            await fetchLookAroundView()
        }
    }
}

extension MapDetailSheetView{
    private func fetchLookAroundView()async{
        let coordinates = CLLocationCoordinate2D(
            latitude: placeData.coordinates.latitude,
            longitude: placeData.coordinates.longitude
        )
        let request = MKLookAroundSceneRequest(
            coordinate: coordinates
        )
        lookAroundScene = try? await request.scene
        
    }
}
