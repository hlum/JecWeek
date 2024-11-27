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
            //try to notify the user location updated, and update the route
            NotificationCenter.default.post(name: Notification.Name("UserLocationUpdated"), object: nil)

        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to update location: \(error.localizedDescription)")
    }
}
struct MapView: View {
    @State private var lastDirectionsUpdateTime: Date?
    private let minTimeBetweenUpdates: TimeInterval = 5.0
    @State private var showDetailView:Bool = false
    @State private var isInDirectionMode:Bool = false
    @StateObject private var locationManager = LocationManager()
    @State private var selectedPlace: JsonDataModel? = nil
    @State private var route: MKRoute?
    
    @StateObject var cardsManager = CardsManager()
    
    var body: some View {
        VStack {
            ZStack{
                Map(position:$locationManager.cameraPosition){
                    UserAnnotation(anchor: .center)
                    ForEach(cardsManager.cardsFromJson,id:\.id) { cardFromJson in
                        let coordinate = CLLocationCoordinate2D(
                            latitude: cardFromJson.coordinates.latitude,
                            longitude: cardFromJson.coordinates.longitude
                        )
                        
                        if !checkUserHasTag(tag: cardFromJson) {
                            Annotation("",coordinate: coordinate) {
                                AnnotationView(for: cardFromJson)
                            }
                        }
                    }
                    
                    if let route = route {
                        MapPolyline(route.polyline)
                            .stroke(Color.blue, lineWidth: 4)
                    }
                }
                .mapControlVisibility(.hidden)
                .mapStyle(.standard(elevation: .realistic))
                
                VStack{
                    Spacer()
                    HStack{
                        showUserLocationButton
                        Spacer()
                    }
                }
            }
            .sheet(isPresented: $showDetailView) {
                if let selectedPlace = selectedPlace{
                    MapDetailSheetView(
                        getDirection:getDirections,
                        placeData: selectedPlace
                    )
                    .presentationCornerRadius(20)
                    .presentationDetents([.medium])
                }
            }
            
            
            
            .onAppear{
                updateRoute()
                cardsManager.getCardsFromJson()
                cardsManager.getCardsFromFirestore()
            }
            
        }
    }
}





//MARK: - SubViews
extension MapView{
    private var showUserLocationButton:some View{
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
    }
    private func AnnotationView(for cardFromJson:JsonDataModel)->some View{
        let isSelected = cardFromJson.coordinates.latitude == selectedPlace?.coordinates.latitude &&
        cardFromJson.coordinates.longitude == selectedPlace?.coordinates.longitude
        
        return VStack(spacing: 0) {
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
                .cornerRadius(6)
                .offset(y: isSelected ? -5 : -3)
                .animation(.bouncy, value: isSelected)
        }
        .shadow(color: isSelected ? .blue.opacity(0.5) : .clear, radius: 10, x: 0, y: 0)
        .onTapGesture {
            withAnimation(.bouncy) {
                    selectedPlace = cardFromJson
                    showDetailView = true

            }
        }
        
    }
}


//MARK: - Functions
extension MapView{
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
        let destinationCoordinate = CLLocationCoordinate2D(
            latitude: selectedPlace!.coordinates.latitude,
            longitude: selectedPlace!.coordinates.longitude)
        
        request.destination = MKMapItem(
            placemark: MKPlacemark(coordinate: destinationCoordinate)
        )
        request.transportType = .walking
        
        
        // Get the directions based on the request
        Task {
            do {
                let directions = MKDirections(request: request)
                let response = try await directions.calculate()
                route = response.routes.first
                self.isInDirectionMode = true
            } catch {
                print("Error getting directions: \(error)")
            }
        }
    }
    
    //when the user start to move, getDirections() get called and update the route
    func updateRoute(){
        NotificationCenter.default
            .addObserver(
                forName: Notification.Name("UserLocationUpdated"),
                object: nil,
                queue: .main) { _ in
                    print("User location updated")
                    if isInDirectionMode{
                        self.checkAndUpdateRoute()
                        
                    }
                }
    }
    
    
    private func checkAndUpdateRoute(){
        guard let lastDirectionsUpdateTime = lastDirectionsUpdateTime else {
            getDirections()
            print("First update")
            self.lastDirectionsUpdateTime = Date()
            return
        }
        let timeSinceLastUpdate = Date().timeIntervalSince(lastDirectionsUpdateTime)
        
        if timeSinceLastUpdate > minTimeBetweenUpdates {
            getDirections()
            print("route updated after \(timeSinceLastUpdate)")
            self.lastDirectionsUpdateTime = Date()
        }else{
            print("Skip update")
        }
    }
}

#Preview {
    MapView()
}
