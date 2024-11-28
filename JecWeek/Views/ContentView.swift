//
//  ContentView.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/13/24.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State var cameraPosition:MapCameraPosition = .automatic
    var body: some View {
        Map{
            Marker("New York", monogram: Text("NY"), coordinate: CLLocationCoordinate2D(latitude: 35.658581, longitude: 139.745438))
            
        }
        .onAppear{
            let coordinate = CLLocationCoordinate2D(latitude: 35.658581, longitude: 139.745438)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            
            let region = MKCoordinateRegion(center: coordinate, span: span)
            cameraPosition = .region(region)
        }
        
    }
}

#Preview {
    ContentView()
}
