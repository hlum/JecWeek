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
    @State var travelTime:TimeInterval?
    @State var showMapStyleMenu: Bool = false
    @State var mapStyle: MapStyle = .standard
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
                        
                        
                        Annotation("",coordinate: coordinate) {
                            AnnotationView(
                                for: cardFromJson,
                                cardIsAlreadyPossessed: checkUserHasTag(
                                    tag: cardFromJson
                                )
                            )
                        }
                        
                    }
                    
                    if let route = route {
                        MapPolyline(route.polyline)
                            .stroke(Color.blue, lineWidth: 4)
                    }
                }
                .mapControlVisibility(.hidden)
                .mapStyle(mapStyle)
                
            }
            .overlay(alignment: .bottom) {
                if let _ = route{
                    
                    HStack{
                        tripDetailView
                        
                        Spacer()
                        cancelDestinationButton
                        
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .move(edge: .bottom)
                        )
                    )
                    
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding()
                    .shadow(radius: 10)
                    //for the transition to work
                    .frame(maxHeight: .infinity,alignment:.bottom)
                    
                }
                
                
            }
            .overlay(alignment: .topLeading, content: {
                VStack(alignment:.leading){
                    mapStyleMenuView
                    showUserLocationButton
                }
            })
            .sheet(isPresented: $showDetailView){
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
    private var tripDetailView:some View{
        VStack(alignment:.leading,spacing: 0){
            if let route = route{
                Group{
                    
                    var formattedDistance:String{
                        if route.distance < 1000{
                            //m
                            return "\(Int(route.distance))m"
                        }else{
                            //km
                            return String(format: "%.2fkm", Double(route.distance) / 1000)
                        }
                    }
                    Text(
                        "\(formatTimeInterval(travelTime ?? 0))  (\(formattedDistance))"
                    )
                    .font(.title2)
                    .bold()
                    .padding(.top)
                    
                    if let travelTime = travelTime {
                        let calendar = Calendar.current
                        let minutes = Int(travelTime / 60) // If `travelTime` is in seconds
                        let date = calendar.date(byAdding: .minute, value: minutes, to: Date())
                        let formattedDate = date?.formatted(
                            Date.FormatStyle()
                                .hour(.twoDigits(amPM: .abbreviated))
                                .minute(.twoDigits)
                        )
                        
                        Text("到着：\(formattedDate ?? "Arrival Time Unavailable")")
                        
                        Text(route.steps.first?.instructions ?? "No instruction Available")
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 25,weight: .light))
                            .padding(.bottom)
                        
                    }
                    
                    
                }
                .padding(.leading)
            }
        }
        
    }
    private var cancelDestinationButton:some View{
        Button {
            withAnimation(.bouncy){
                route = nil
                isInDirectionMode = false
                selectedPlace = nil
            }
        } label: {
            Image(systemName:"xmark.app")
                .font(.system(size: 30))
                .padding()
                .background(.red)
                .foregroundColor(.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.trailing)
        }
    }
    private var mapStyleMenuView:some View{
        Menu {
            Button("標準") {
                mapStyle = .standard(elevation: .realistic)
            }
            
            Button("航空写真") {
                mapStyle = .hybrid(elevation: .realistic)
            }
        } label: {
            mapStyleMenuButton
        }
    }
    
    private var showUserLocationButton:some View{
        Button {
            moveCameraToUserLocation()
        } label: {
            Image(systemName:"paperplane.fill")
                .font(.system(size: 20))
                .padding()
                .background(.white)
                .foregroundColor(.blue)
                .cornerRadius(10)
                .padding(.leading,30)
                .shadow(radius: 10)
            
        }
    }
    
    
    private func AnnotationView(for cardFromJson:JsonDataModel,cardIsAlreadyPossessed:Bool)->some View{
        let isSelected = cardFromJson.coordinates.latitude == selectedPlace?.coordinates.latitude &&
        cardFromJson.coordinates.longitude == selectedPlace?.coordinates.longitude
        
        return VStack(spacing: 0) {
            // Animated building name
            
            
            // Animated marker icon
            Image(systemName: cardIsAlreadyPossessed ? "checkmark.circle.fill" : "lock.circle" )
                .resizable()
                .scaledToFit()
                .frame(
                    width: isSelected ? 30 : 20,
                    height: isSelected ? 30 : 20
                )
                .foregroundColor(.white)
                .padding(4)
                .background(
                    cardIsAlreadyPossessed ? (isSelected ? .blue : .green)
                    : .red
                )
                .cornerRadius(36)
                .animation(.bouncy, value: isSelected)
            
            // Animated pointer
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(
                    cardIsAlreadyPossessed ? (
                        isSelected ? .blue : .green
                    )
                    : .red
                )
                .frame(width: 10, height: 10)
                .rotationEffect(Angle(degrees: 180))
                .offset(y: isSelected ? -5 : -3)
                .animation(.bouncy, value: isSelected)
            Text(cardFromJson.buildingName)
                .font(isSelected ? .system(size: 8) : .system(size: 10))
                .fontWeight(
                    isSelected ? .bold : .regular
                )
                .foregroundColor(.black)
                .padding(6)
                .background(.thinMaterial)
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
    
    private var mapStyleMenuButton:some View{
        Button {
            showMapStyleMenu = true
        } label: {
            VStack{
                Image(systemName: "map.fill")
                    .font(.system(size: 20))
                    .padding()
                    .background(.white)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                
                Text("Map Style")
                    .font(.caption)
                    .foregroundStyle(.black)
            }
            .padding(.leading,30)
            .shadow(radius: 10)
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
                withAnimation(.bouncy){
                    route = response.routes.first
                    self.isInDirectionMode = true
                    moveCameraToUserLocation()
                    self.travelTime = route?.expectedTravelTime
                }
                
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
    
    func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: timeInterval) ?? "N/A"
    }
}

#Preview {
    MapView()
}
