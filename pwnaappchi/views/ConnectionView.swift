import Foundation
import SwiftUI

struct ConnectionView: View {
    @ObservedObject var networkManager = NetworkManager.shared
    @State private var downloadActive = false
    @State private var downloadedFiles = 0
    @State private var totalFiles = 0
    @State private var downloadTask: Task<Void, Never>?
    @State private var webViewID = UUID()
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
                        Text("Connected to: \(networkManager.pwnyName)")
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
                        Text(" ")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                
                // Port Status Grid View
                HStack {
                    Spacer()
                    LazyVGrid(columns: columns, spacing: 20) {
                        PortStatusView(portName: "Port 22\nSSH", isReachable: networkManager.isPort22Reachable)
                        PortStatusView(portName: "Port 80\nBettercap UI", isReachable: networkManager.isPort80Reachable)
                        PortStatusView(portName: "Port 8080\nPwnagotchi", isReachable: networkManager.isPort8080Reachable)
                        PortStatusView(portName: "Port 8081\nBettercap API", isReachable: networkManager.isPort8081Reachable)
                    }
                    Spacer()
                }                
                
                VStack {
                    if (networkManager.configUpdated && networkManager.isPort8080Reachable) {
                        let ip = UserDefaults.standard.string(forKey: "pwnIp") ?? "172.20.10.6"
                        let user = networkManager.webUiUser
                        let password = networkManager.webUiPassword

                        WebViewElement(urlString: "http://\(ip):8080", username: user, password: password, id: webViewID)
                            .id(webViewID)
                            .onAppear {
                                // set uuid on reconnect
                                webViewID = UUID()}
                            .aspectRatio(3/2.09, contentMode: .fit) // Aspect Ratio for WEB Ui with Waveshare 2.13
                            .frame(maxWidth: UIScreen.main.bounds.width)
                            .padding(.bottom, 10)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(3/2.09, contentMode: .fit) // Matching aspect ratio
                            .frame(maxWidth: UIScreen.main.bounds.width)
                            .overlay(
                                Text("Not Connected")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            )
                            .padding(.bottom, 10)
                    }
                }
                
                
                HStack{
                    Button(action: {
                        if downloadActive {
                            cancelDownload()
                        } else {
                            startDownload()
                        }
                    }) {
                        Text(downloadActive ? "Cancel Download" : "Load Data")
                            .font(.body)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(downloadActive ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Button(action: {
                        Task {
                            networkManager.performConnectionCheckIfNeeded()
                        }
                    }) {
                        Text("Refresh")
                            .font(.body)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(downloadActive ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                if downloadActive {
                    Text("Download: \(downloadedFiles) of \(totalFiles) Files")
                        .font(.subheadline)
                        .padding(.top, 10)
                }
                Spacer()
                
            }
            .padding()
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
                debugPrint("Error downloading files: \(error.localizedDescription)")
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
        HStack(spacing: 10) {
            Image(systemName: isReachable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isReachable ? .green : .red)
                .font(.system(size: 20)) // Symbolgröße anpassen
            
            Text(portName)
                .font(.body)
                .fontWeight(isReachable ? .semibold : .regular)
                .foregroundColor(isReachable ? .green : .red)
                .multilineTextAlignment(.leading) // Textausrichtung anpassen
        }
        .padding(10) // Padding anpassen
        .frame(maxWidth: .infinity, alignment: .leading) // Links ausrichten
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}
