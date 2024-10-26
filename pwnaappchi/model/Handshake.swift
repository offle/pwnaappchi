import Foundation

struct Handshake: Identifiable, Codable {
    var id: String
    var handshakeName: String
    var pcapFile: PwnFile
    var netposFile: PwnFile?
    var geoFile: PwnFile?
    var gpsFile: PwnFile?
    
    init(id: String, pwnFile: PwnFile) {
        self.id = id
        self.handshakeName = pwnFile.filename.replacingOccurrences(of: ".pcap", with: "")
        self.pcapFile = pwnFile
    }
    
}
