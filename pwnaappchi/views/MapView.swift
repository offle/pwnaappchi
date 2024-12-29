import Foundation
import SwiftUI
import MapKit

struct MapView: View {
    private let utils = Utils()
    @State private var positions: [CLLocationCoordinate2D] = []
    @State var minAccuracy: Double = 50
    @Binding var pwnFiles: [PwnFile]
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(positions.indices, id: \.self) { index in
                Marker("\(index)", coordinate: positions[index])
                    .tint(.red)
            }
        }
        .onAppear {
            getPositions()
            
        }
        .navigationTitle("Map")
    }
    
    
    func getPositions() {
        let mapAccuracyString = UserDefaults.standard.string(forKey: "mapAccuracy") ?? "0"
        var mapAccuracy: Int = 0
        mapAccuracy = Int(mapAccuracyString) ?? 0
        positions = utils.getPositionFromAllFiles(pwnfiles: pwnFiles, mapAccuracy: mapAccuracy)
            .compactMap { $0.region?.center }
        if !positions.isEmpty {
            cameraPosition = .rect(MKMapRect.fromCoordinates(positions))
        }
    }
}

extension MKMapRect {
    static func fromCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        let points = coordinates.map { MKMapPoint($0) }
        let rects = points.map { MKMapRect(origin: $0, size: MKMapSize(width: 0.1, height: 0.1)) }
        return rects.reduce(MKMapRect.null) { $0.union($1) }.insetBy(dx: -1000, dy: -1000)
    }
}
