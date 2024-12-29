import Foundation
import SwiftUI
import MapKit

struct CaptureDetailJsonView: View {
    
    private let utils = Utils()
    var filename: String
    @State var position: MapCameraPosition
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Filename: \(filename)")
                .font(.headline)
                .padding(.bottom, 5)
            
            if (filename.hasSuffix("geo.json") || filename.hasSuffix("gps.json")) {
                Map(
                    position: $position,
                    interactionModes: MapInteractionModes.all)
                .frame(height: 200)
                .onAppear {
                    if let region = position.region {
                        position = .region(MKCoordinateRegion(
                            center: region.center,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                }
                .padding(.bottom, 10)
            }
            
            ScrollView {
                Text(utils.getJsonAsPrettyString(filename: filename))
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
        }
        .padding()
        .navigationTitle("JSON Details")
    }
    
    
}
