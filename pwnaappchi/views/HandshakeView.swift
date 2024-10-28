import SwiftUI
import Citadel
import NIO

struct HandshakeView: View {
    
    @ObservedObject var networkManager = NetworkManager.shared
    private let pwnFileManager = PwnFileManager()
    private let utils = Utils()
    
    @Binding var pwnFiles: [PwnFile]
    @Binding var handshakes: [Handshake]
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach($handshakes, id: \.id) { $handshake in
                    NavigationLink(destination: HandshakeDetailView(handshake: $handshake)) {
                        VStack(alignment: .leading) {
                            Text(handshake.handshakeName)
                                .font(.headline)
                            Text((handshake.pcapFile.modificationDate ?? Date(timeIntervalSince1970: 0)).formattedDate())
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            HStack(spacing: 0) {
                                // PCAP Size Indicator
                                Text("\(handshake.pcapFile.size ?? 0) B")
                                    .frame(maxWidth: .infinity)
                                    .padding(4)
                                    .background(handshake.pcapFile.size ?? 0 > 0 ? Color.green : Color.red)
                                    .foregroundColor(.white)
                                    .font(.caption)
                                
                                // NET-POS Status
                                Text("NET-POS")
                                    .frame(maxWidth: .infinity)
                                    .padding(4)
                                    .background(handshake.netposFile != nil ? Color.green : Color.red)
                                    .foregroundColor(.white)
                                    .font(.caption)
                                
                                // GEO Status
                                Text("GEO")
                                    .frame(maxWidth: .infinity)
                                    .padding(4)
                                    .background(handshake.geoFile != nil ? Color.green : (handshake.gpsFile != nil ? Color.gray : Color.red))
                                    .foregroundColor(.white)
                                    .font(.caption)
                                
                                // GPS Status
                                Text("GPS")
                                    .frame(maxWidth: .infinity)
                                    .padding(4)
                                    .background(handshake.gpsFile != nil ? Color.green : Color.gray)
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await fetchFiles()
                }
            }
            .navigationTitle("Handshakes \($handshakes.count)")
            .refreshable {
                await fetchFiles()
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading...")
                }
            }
        }
    }
    
    private func fetchFiles() async {
        debugPrint("Loading Files")
        isLoading = true
        
        defer { isLoading = false }
        pwnFiles = pwnFileManager.getAllLocalFiles()
        handshakes = await pwnFileManager.loadLocalFiles(pwnFiles: pwnFiles)
    }
    
    
}
