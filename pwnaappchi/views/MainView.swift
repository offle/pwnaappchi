import Foundation
import SwiftUI

struct MainView: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var pwnFiles: [PwnFile] = []
    @State private var handshakes: [Handshake] = []
    
    var body: some View {
        TabView {
            HandshakeView(pwnFiles: $pwnFiles, handshakes: $handshakes)
                .tabItem {
                    Image(systemName: "network")
                    Text("Handshakes")
                }
            
            MapView(pwnFiles: $pwnFiles)
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            StatisticsView(pwnFiles: $pwnFiles, handshakes: $handshakes)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Statistics")
                }
            
            ConnectionView(networkManager: networkManager)
                .tabItem {
                    Image(systemName: "wave.3.right.circle")
                    Text("Connection")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .onAppear {
            networkManager.checkConnection()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
