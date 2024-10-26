import Foundation
import SwiftUI
import MapKit

struct HandshakeDetailView: View {
    @Binding var handshake: Handshake
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
            Section(header: Text("Handshake Info")) {
                Text("Name: \(handshake.handshakeName)")
                Text("PCAP File Size: \(handshake.pcapFile.size ?? 0) B")
                Text("Modification Date: \((handshake.pcapFile.modificationDate ?? Date(timeIntervalSince1970: 0)).formattedDate())")
            }
            
            Section(header: Text("Associated Files")) {
                if let netposFile = handshake.netposFile {
                    NavigationLink(destination: HandshakeDetailJsonView(filename: netposFile.filename, position: positionGeoFile)) {
                        Text("NET-POS: \(netposFile.filename)")}
                } else {
                    Text("NET-POS: Not available")
                }
                
                if let geoFile = handshake.geoFile {
                    NavigationLink(destination: HandshakeDetailJsonView(filename: geoFile.filename, position: positionGeoFile)) {
                        Text("GEO: \(geoFile.filename)")
                    }
                } else {
                    Text("GEO: Not available")
                }
                
                if let gpsFile = handshake.gpsFile {
                    NavigationLink(destination: HandshakeDetailJsonView(filename: gpsFile.filename, position: positionGpsFile)) {
                        Text("GPS: \(gpsFile.filename)")
                    }
                } else {
                    Text("GPS: Not available")
                }
                
                if (((handshake.geoFile?.filename.hasSuffix("geo.json")) != nil)) {
                    Map(
                        position: $positionGeoFile,
                        interactionModes: MapInteractionModes.all)
                    .frame(height: 200)
                    .onAppear {
                        self.positionGeoFile = utils.getPositionFromFile(filename: handshake.geoFile?.filename ?? "", mapAccuracy: 0) ?? defaultPosition
                    }
                    .padding(.bottom, 10)
                }
                if ((handshake.gpsFile?.filename.hasSuffix("gps.json")) != nil) {
                    Map(
                        position: $positionGpsFile,
                        interactionModes: MapInteractionModes.all)
                    .frame(height: 200)
                    .onAppear {
                        self.positionGpsFile = utils.getPositionFromFile(filename: handshake.gpsFile?.filename ?? "", mapAccuracy: 0) ?? defaultPosition
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .navigationTitle("Handshake Details")
    }
    

}


