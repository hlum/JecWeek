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
        ScrollView(showsIndicators:false){
            VStack{
                HStack(alignment:.center){
                    VStack(alignment:.leading){
                        Text(placeData.buildingName)
                            .font(.title)
                            .fontWeight(.bold)
                            
                        Text(placeData.adress)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 13))
                            .fontWeight(.light)
                            .textSelection(.enabled)
                            
                    }
                    .padding(.vertical)
                    
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
                .padding(.horizontal)
                
                if let _ = lookAroundScene{
                    LookAroundPreview(scene: $lookAroundScene)
                        .frame(height: 300)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                }
            }
            .padding(.top)
            .task {
                await fetchLookAroundView()
            }
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
