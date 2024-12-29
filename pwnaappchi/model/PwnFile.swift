import Foundation

struct PwnFile: Identifiable, Codable {
    var id: String
    var filename: String
    var basename: String
    var size: UInt64?
    var modificationDate: Date?
    var fileType: FileType?
    
    
    // Enum für verschiedene Dateitypen
    enum FileType: String, Codable {
        case capture
        case netpos
        case geo
        case gps
        case unknown
        }
        
    // Initialisierer, der Dateisuffix und Dateityp setzt
    init(id: String, filename: String, size: UInt64, creationDate: Date, modificationDate: Date) {
        self.id = id
        self.filename = filename
        self.size = size
        self.modificationDate = modificationDate
        

        // Dateityp basierend auf Dateinamen und -endungen setzen
        if filename.hasSuffix(".pcap") {
            self.fileType = .capture
            self.basename = filename.replacingOccurrences(of: ".pcap", with: "")
        } else if filename.hasSuffix("net-pos.json") {
            self.fileType = .netpos
            self.basename = filename.replacingOccurrences(of: ".net-pos.json", with: "")
        } else if filename.hasSuffix("geo.json") {
            self.fileType = .geo
            self.basename = filename.replacingOccurrences(of: ".geo.json", with: "")
        } else if filename.hasSuffix("gps.json") {
            self.fileType = .geo
            self.basename = filename.replacingOccurrences(of: ".gps.json", with: "")
        } else {
            self.fileType = .unknown
            self.basename = filename
        }
    }
}
