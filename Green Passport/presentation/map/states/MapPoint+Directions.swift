import MapKit

extension MapPoint {
    func openDirections() {
        let item = mapItem
        item.name = name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }

    private var mapItem: MKMapItem {
        if #available(iOS 26, *) {
            return MKMapItem(location: CLLocation(latitude: latitude, longitude: longitude), address: nil)
        }
        return MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
    }
}
