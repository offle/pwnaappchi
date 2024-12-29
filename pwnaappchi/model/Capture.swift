import Foundation

struct Capture: Identifiable, Codable {
    var id: String
    var captureName: String
    var pcapFile: PwnFile
    var netposFile: PwnFile?
    var geoFile: PwnFile?
    var gpsFile: PwnFile?
    
    init(id: String, pwnFile: PwnFile) {
        self.id = id
        self.captureName = pwnFile.filename.replacingOccurrences(of: ".pcap", with: "")
        self.pcapFile = pwnFile
    }
    
}
