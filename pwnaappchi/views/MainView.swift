import Foundation
import SwiftUI

struct MainView: View {
    @State private var pwnFiles: [PwnFile] = []
    @State private var captures: [Capture] = []
    
    var body: some View {
        TabView {
            ConnectionView()
                .tabItem {
                    Image(systemName: "wave.3.right.circle")
                    Text("Connection")
                }
            
            CaptureView(pwnFiles: $pwnFiles, captures: $captures)
                .tabItem {
                    Image(systemName: "network")
                    Text("Captures")
                }
            
            MapView(pwnFiles: $pwnFiles)
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            StatisticsView(pwnFiles: $pwnFiles, captures: $captures)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Statistics")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
