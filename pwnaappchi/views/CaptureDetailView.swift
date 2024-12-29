import Foundation
import SwiftUI
import MapKit

struct CaptureDetailView: View {
    @Binding var capture: Capture
    @State private var positionGeoFile = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var positionGpsFile = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    private let defaultPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    let utils = Utils()

    
    var body: some View {
        Form {
            Section(header: Text("Capture Info")) {
                Text("Name: \(capture.captureName)")
                Text("PCAP File Size: \(capture.pcapFile.size ?? 0) B")
                Text("Modification Date: \((capture.pcapFile.modificationDate ?? Date(timeIntervalSince1970: 0)).formattedDate())")
            }
            
            Section(header: Text("Associated Files")) {
                if let netposFile = capture.netposFile {
                    NavigationLink(destination: CaptureDetailJsonView(filename: netposFile.filename, position: positionGeoFile)) {
                        Text("NET-POS: \(netposFile.filename)")}
                } else {
                    Text("NET-POS: Not available")
                }
                
                if let geoFile = capture.geoFile {
                    NavigationLink(destination: CaptureDetailJsonView(filename: geoFile.filename, position: positionGeoFile)) {
                        Text("GEO: \(geoFile.filename)")
                    }
                } else {
                    Text("GEO: Not available")
                }
                
                if let gpsFile = capture.gpsFile {
                    NavigationLink(destination: CaptureDetailJsonView(filename: gpsFile.filename, position: positionGpsFile)) {
                        Text("GPS: \(gpsFile.filename)")
                    }
                } else {
                    Text("GPS: Not available")
                }
                
                if (((capture.geoFile?.filename.hasSuffix("geo.json")) != nil)) {
                    Map(
                        position: $positionGeoFile,
                        interactionModes: MapInteractionModes.all)
                    .frame(height: 200)
                    .onAppear {
                        self.positionGeoFile = utils.getPositionFromFile(filename: capture.geoFile?.filename ?? "", mapAccuracy: 0) ?? defaultPosition
                    }
                    .padding(.bottom, 10)
                }
                if ((capture.gpsFile?.filename.hasSuffix("gps.json")) != nil) {
                    Map(
                        position: $positionGpsFile,
                        interactionModes: MapInteractionModes.all)
                    .frame(height: 200)
                    .onAppear {
                        self.positionGpsFile = utils.getPositionFromFile(filename: capture.gpsFile?.filename ?? "", mapAccuracy: 0) ?? defaultPosition
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .navigationTitle("Capture Details")
    }
    

}


