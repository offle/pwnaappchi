import SwiftUI
import Citadel
import NIO

struct CaptureView: View {
    
    @ObservedObject var networkManager = NetworkManager.shared
    private let pwnFileManager = PwnFileManager()
    private let utils = Utils()
    
    @Binding var pwnFiles: [PwnFile]
    @Binding var captures: [Capture]
    @State private var isLoading = false
    @State private var searchText = ""
    
    var filteredCaptures: [Capture] {
        if searchText.isEmpty {
            return captures
        } else {
            return captures.filter { $0.captureName.localizedCaseInsensitiveContains(searchText) }
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
                    ForEach(filteredCaptures, id: \.id) { capture in
                        NavigationLink(destination: CaptureDetailView(capture: .constant(capture))) {
                            VStack(alignment: .leading) {
                                Text(capture.captureName)
                                    .font(.headline)
                                Text((capture.pcapFile.modificationDate ?? Date(timeIntervalSince1970: 0)).formattedDate())
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                HStack(spacing: 0) {
                                    // PCAP Size Indicator
                                    Text("\(capture.pcapFile.size ?? 0) B")
                                        .frame(maxWidth: .infinity)
                                        .padding(4)
                                        .background(capture.pcapFile.size ?? 0 > 0 ? Color.green : Color.red)
                                        .foregroundColor(.white)
                                        .font(.caption)
                                    
                                    // NET-POS Status
                                    Text("NET-POS")
                                        .frame(maxWidth: .infinity)
                                        .padding(4)
                                        .background(capture.netposFile != nil ? Color.green : Color.red)
                                        .foregroundColor(.white)
                                        .font(.caption)
                                    
                                    // GEO Status
                                    Text("GEO")
                                        .frame(maxWidth: .infinity)
                                        .padding(4)
                                        .background(capture.geoFile != nil ? Color.green : (capture.gpsFile != nil ? Color.gray : Color.red))
                                        .foregroundColor(.white)
                                        .font(.caption)
                                    
                                    // GPS Status
                                    Text("GPS")
                                        .frame(maxWidth: .infinity)
                                        .padding(4)
                                        .background(capture.gpsFile != nil ? Color.green : Color.gray)
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
                .navigationTitle("Captures (\(filteredCaptures.count))")
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
        captures = await pwnFileManager.loadLocalFiles(pwnFiles: pwnFiles)
    }
    
    
}
