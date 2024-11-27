import SwiftUI
import MapKit
import CoreLocation

// Place model to represent locations
struct Place: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

final class CardsManager:ObservableObject{
    @Published var cardsFromJson:[JsonDataModel] = []
    @Published var userPossessedCards:[String] = []
    
    
    func getCardsFromJson(){
        self.cardsFromJson = JsonFileReader.shared.loadPlaceData() ?? []
    }
    
    func getCardsFromFirestore(){
        guard let userData = AuthenticationManager.shared.getUserData()else{
            return
        }
        FirestoreManger.shared.getDBUser(userId: userData.uid) {[weak self] dbUser, error in
            if let error = error{
                return
            }
            
            guard let dbUser = dbUser else{
                return
            }
            self?.userPossessedCards = dbUser.cardPossessed ?? []
        }
    }
    
}


final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var region = MKCoordinateRegion()
    @Published var userCoordinate = CLLocationCoordinate2D()
    @Published var cameraPosition: MapCameraPosition = .automatic
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Use best available accuracy
        setup()
    }
    
    private func setup() {
        print("Setting up location manager")
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            print("Location access authorized")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            print("Requesting location authorization")
        case .denied, .restricted:
            locationManager.requestWhenInUseAuthorization()
            print("Location access denied or restricted. Guide user to Settings.")
            // Optionally, show an alert to guide the user to Settings
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
            print("Unknown authorization status")
        }
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            print("Location access granted")
        case .denied, .restricted:
            locationManager.requestWhenInUseAuthorization()
            print("Location access denied or restricted. User must enable permissions in Settings.")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            print("Authorization not determined yet.")
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
            print("Unknown authorization status")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        DispatchQueue.main.async {
            self.userCoordinate = newLocation.coordinate
            self.region = MKCoordinateRegion(
                center: newLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            print("Updated location: \(newLocation.coordinate)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to update location: \(error.localizedDescription)")
    }
}
struct MapView: View {
    @State var inDirectionMode:Bool = false
    @StateObject private var locationManager = LocationManager()
    @State private var selectedPlace: CLLocationCoordinate2D? = nil
    @State private var route: MKRoute?
    
    @StateObject var cardsManager = CardsManager()
    
    var body: some View {
        VStack {
            ZStack{
                Map(
                    position:$locationManager.cameraPosition
                ){
                    
                    UserAnnotation(anchor: .center)
                    
                    ForEach(cardsManager.cardsFromJson,id:\.id) { cardFromJson in
                        let coordinate = CLLocationCoordinate2D(
                            latitude: cardFromJson.coordinates.latitude,
                            longitude: cardFromJson.coordinates.longitude
                        )
                        
                        
                        if !checkUserHasTag(tag: cardFromJson) {
                            
                            Annotation(
                                "",
                                coordinate: coordinate
                            ) {
                                let isSelected = cardFromJson.coordinates.latitude == selectedPlace?.latitude &&
                                                 cardFromJson.coordinates.longitude == selectedPlace?.longitude
                                
                                VStack(spacing: 0) {
                                    // Animated building name
                                   
                                    
                                    // Animated marker icon
                                    Image(systemName: "map.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(
                                            width: isSelected ? 60 : 30,
                                            height: isSelected ? 60 : 30
                                        )
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(isSelected ? .blue : .green)
                                        .cornerRadius(36)
                                        .animation(.bouncy, value: isSelected)
                                    
                                    // Animated pointer
                                    Image(systemName: "triangle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(isSelected ? .blue : .green)
                                        .frame(width: 10, height: 10)
                                        .rotationEffect(Angle(degrees: 180))
                                        .offset(y: isSelected ? -5 : -3)
                                        .animation(.bouncy, value: isSelected)
                                    
                                    Text(cardFromJson.buildingName)
                                        .font(isSelected ? .title3 : .title2)
                                        .fontWeight(
                                            isSelected ? .bold : .regular
                                        )
                                        .foregroundColor(.black)
                                        .padding(6)
//                                        .background(.white)
                                        .cornerRadius(6)
                                        .offset(y: isSelected ? -5 : -3)
                                        .animation(.bouncy, value: isSelected)
                                }
                                .shadow(color: isSelected ? .blue.opacity(0.5) : .clear, radius: 10, x: 0, y: 0)
                                .onTapGesture {
                                    withAnimation(.bouncy) {
                                        selectedPlace = CLLocationCoordinate2D(
                                            latitude: coordinate.latitude,
                                            longitude: coordinate.longitude
                                        )
                                    }
                                }
                            }
                        }
                      
                        
                        
                    }
                    
                    if let route = route {
                        MapPolyline(route.polyline)
                            .stroke(Color.blue, lineWidth: 4    )
                    }
                }

                
                
                .mapControlVisibility(.hidden)
                                
                .mapStyle(.standard(elevation: .realistic))
                
                VStack{
                    Spacer()
                    HStack{
                        Button {
                            moveCameraToUserLocation()
                        } label: {
                            Image(systemName:"paperplane.fill")
                                .padding()
                                .background(.white)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                                .padding(.leading,30)
                            
                        }
                        
                        Spacer()
                        Button {
                            inDirectionMode = true
                            getDirections()
                            moveCameraToUserLocation()
                        } label: {
                            Text("Direction")
                                .padding()
                                .background(.white)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                    }
                }
                
            }
            .onAppear{
                cardsManager.getCardsFromJson()
                cardsManager.getCardsFromFirestore()
            }
            
        }
    }
    
    func checkUserHasTag(tag:JsonDataModel)->Bool{
        cardsManager.userPossessedCards.contains(where: { $0 == tag.id })
    }
    
    private func moveCameraToUserLocation(){
        let coordinate = CLLocationCoordinate2D(
            latitude: locationManager.userCoordinate.latitude,
            longitude: locationManager.userCoordinate.longitude
        )
        let span = MKCoordinateSpan(
            latitudeDelta: 0.001,
            longitudeDelta: 0.001
        )
        let region = MKCoordinateRegion(
            center: coordinate,
            span: span
        )
        withAnimation(.easeIn){
            locationManager.cameraPosition = .region(region)
        }

    }
    func getDirections() {
        
        // Create and configure the request
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.userCoordinate))
        request.destination = MKMapItem(
            placemark: MKPlacemark(
                coordinate: selectedPlace!
            )
        )
        request.transportType = .walking
        
        
        // Get the directions based on the request
        Task {
            do {
                let directions = MKDirections(request: request)
                let response = try await directions.calculate()
                route = response.routes.first
            } catch {
                print("Error getting directions: \(error)")
            }
        }
    }
}


extension MapView{
    //    private func markerForCard(cardFromJson:JsonDataModel)->some View{
    //        let coordinate = CLLocationCoordinate2D(
    //            latitude: cardFromJson.coordinates.latitude,
    //            longitude: cardFromJson.coordinates.longitude
    //        )
    //        VStack{
    //            Marker(coordinate: coordinate) {
    //                VStack{
    //                    Text(cardFromJson.buildingName)
    //                        .font(.title)
    //                        .padding(10)
    //                        .background(.white)
    //                        .bold()
    //                        .cornerRadius(10)
    //                    Image(systemName: "building.2")
    //                        .font(.title)
    //                }
    //            }
    //        }
    //    }
}

#Preview {
    MapView()
}
