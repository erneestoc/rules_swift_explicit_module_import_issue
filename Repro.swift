import UIKit
import SwiftUI
import MapKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    }
}

var hola: some View {
	Map(
        coordinateRegion: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )),
        annotationItems: [
            MapPin(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        ]
    ) { pin in
        MapMarker(coordinate: pin.coordinate, tint: .green)
    }
}
