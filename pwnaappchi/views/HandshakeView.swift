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
    @State private var searchText = ""
    
    var filteredHandshakes: [Handshake] {
        if searchText.isEmpty {
            return handshakes
        } else {
            return handshakes.filter { $0.handshakeName.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                TextField("Search by name", text: $searchText)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                List {
                    ForEach(filteredHandshakes, id: \.id) { handshake in
                        NavigationLink(destination: HandshakeDetailView(handshake: .constant(handshake))) {
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
                .navigationTitle("Handshakes (\(filteredHandshakes.count))")
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
    }
    
    private func fetchFiles() async {
        debugPrint("Loading Files")
        isLoading = true
        
        defer { isLoading = false }
        pwnFiles = pwnFileManager.getAllLocalFiles()
        handshakes = await pwnFileManager.loadLocalFiles(pwnFiles: pwnFiles)
    }
    
    
}
