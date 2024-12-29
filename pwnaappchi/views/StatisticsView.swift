
import Foundation
import SwiftUI

struct StatisticsView: View {
    
    @Binding var pwnFiles: [PwnFile]
    @Binding var captures: [Capture]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Files")) {
                    statisticsRow(title: "Total Files", value: "\(pwnFiles.count)", fontLeft: .bold(.headline)(), fontRight: .bold(.headline)())
                    statisticsRow(title: "Capture Files", value: "\(captures.count)", fontLeft: .headline, fontRight: .headline)
                    statisticsRow(title: "NET-POS Files", value: "\(pwnFiles.compactMap { $0.fileType }.filter { $0 == .netpos }.count)", fontLeft: .headline, fontRight: .headline)
                    statisticsRow(title: "GEO Files", value: "\(pwnFiles.compactMap { $0.fileType }.filter { $0 == .geo }.count)", fontLeft: .headline, fontRight: .headline)
                    statisticsRow(title: "GPS Files", value: "\(pwnFiles.compactMap { $0.fileType }.filter { $0 == .gps }.count)", fontLeft: .headline, fontRight: .headline)
                }
                Section(header: Text("other fancy statistics")) {
                    Text("lol")
                    Text("lel")
                    Text("lul")
                }
                .padding()
            }
        }
        
        
        .navigationTitle("Statistics")
        .refreshable {
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") {
                    Task {
                    }
                }
            }
        }
    }
    
    
    
    
    private func statisticsRow(title: String, value: String, fontLeft: Font, fontRight: Font) -> some View {
        HStack {
            Text(title)
                .font(fontLeft)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(fontRight)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 3)
    }
}

