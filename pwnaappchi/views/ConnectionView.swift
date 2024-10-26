import Foundation
import SwiftUI

struct ConnectionView: View {
    @ObservedObject var networkManager: NetworkManager
    @State private var downloadActive = false
    @State private var downloadedFiles = 0
    @State private var totalFiles = 0
    @State private var downloadTask: Task<Void, Never>?
    private let pwnFileManager = PwnFileManager()
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Connection Info
                VStack {
                    if let latency = networkManager.latency {
                        Text("Connected to: \(networkManager.pwnagotchiName)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Latency: \(String(format: "%.0f ms", latency))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    } else {
                        Text("Not Connected")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                
                // Port Status Grid View
                LazyVGrid(columns: columns, spacing: 20) {
                    PortStatusView(portName: "Port 22\nSSH", isReachable: networkManager.isPort22Reachable)
                    PortStatusView(portName: "Port 80\nBettercap UI", isReachable: networkManager.isPort80Reachable)
                    PortStatusView(portName: "Port 8080\nPwnagotchi UI", isReachable: networkManager.isPort8080Reachable)
                    PortStatusView(portName: "Port 8081\nBettercap API", isReachable: networkManager.isPort8081Reachable)
                }
                .padding(.horizontal, 20)
                
                Button(action: {
                    startDownload()
                }) {
                    Text("Download Handshakes")
                        .font(.body)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(downloadActive ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .allowsHitTesting(!downloadActive)
                
                if downloadActive {
                    Text("Download: \(downloadedFiles) of \(totalFiles) Files")
                        .font(.subheadline)
                        .padding(.top, 10)
                    Button(action: {
                        cancelDownload()
                    }) {
                        Text("Cancel Download")
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    .padding(.top, 5)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Connection")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        Task {
                            networkManager.checkConnection()
                        }
                    }
                }
            }
            .onAppear {
            }
        }
    }
    
    private func startDownload() {
        guard networkManager.latency != nil else { return }
        guard !downloadActive else { return }
        downloadActive = true
        downloadedFiles = 0
        totalFiles = 0
        
        downloadTask = Task {
            do {
                totalFiles = try await pwnFileManager.downloadFiles { downloaded, total in
                    downloadedFiles = downloaded
                    totalFiles = total
                }
            } catch {
                print("Fehler beim Herunterladen: \(error.localizedDescription)")
            }
            downloadActive = false
            downloadTask = nil
            await MainActor.run {
                downloadActive = false
                downloadTask = nil
            }
        }
    }
    
    private func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadActive = false
    }
    
}

struct PortStatusView: View {
    var portName: String
    var isReachable: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: isReachable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isReachable ? .green : .red)
                .font(.system(size: 24))
            
            Text("\(portName)")
                .font(.body)
                .fontWeight(isReachable ? .semibold : .regular)
                .foregroundColor(isReachable ? .green : .red)
                .multilineTextAlignment(.center)
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 3)
    }
    
}
