import Citadel
import NIO
import Foundation

class PwnFileManager {
    
    private let utils = Utils()
    private let networkManager = NetworkManager()
    
    func downloadFiles(progressHandler: @escaping (Int, Int) throws -> Void) async throws -> Int {
        var total = 0
        
        do {
            let client = try await networkManager.createClient()
            let handshakeDirectory = UserDefaults.standard.string(forKey: "handshakeDir") ?? "/root/handshakes"
            var maxDownloadCount: Int = 0
            let maxDownloadCountString = UserDefaults.standard.string(forKey: "maxDownloadCount") ?? "0"
            maxDownloadCount = Int(maxDownloadCountString) ?? 0
            // parsing ls is dirty, but the listDirectory Method returns max 100 entries
            let lsOutBB = try await client.executeCommand("ls -t \(handshakeDirectory)")
            let lsOut = utils.byteBufferToString(byteBuffer: lsOutBB) ?? ""
            let files = lsOut.split(separator: "\n")
            let sftp = try await client.openSFTP()
            let totalFiles = files.count
            
            for file in files {
                try Task.checkCancellation()
                if (file == "." || file == "..")  {
                    continue
                }
                //debugPrint(file.filename)
                let fullPath = handshakeDirectory + "/" + file
                let buffer = try await sftp.openFile(filePath: fullPath, flags: .read)
                let bufferContents: ByteBuffer = try await buffer.readAll()
                try await buffer.close()
                // read date
                var modDate = Date(timeIntervalSince1970: 0)
                let modDateUnixBB = try await client.executeCommand("date -r \(fullPath) +%s")
                let modDateUnixClean = utils.byteBufferToString(byteBuffer: modDateUnixBB)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
                if let modDateUnixTimeStamp = TimeInterval(modDateUnixClean) {
                    modDate = Date(timeIntervalSince1970: modDateUnixTimeStamp)
                    debugPrint("Datum: \(modDate)")
                } else {
                    print("Ungültiger Zeitstempel")
                }
                
                debugPrint("Save \(file) local...")
                saveByteBufferToDocuments(byteBuffer: bufferContents, fileName: String(file), modDate: modDate)
                if (total >= maxDownloadCount && maxDownloadCount > 0) {
                    break
                }
                total += 1
                try progressHandler(total, totalFiles)
            }
            
            //          listDirectory only returns 100 entries
            //          TODO: investigate the 'only 100' issue and use this instead of the ls - parsing
            //            let directoryContents = try await sftp.listDirectory(atPath: handshakeDirectory)
            //            debugPrint("listDirectory has found \(directoryContents.first!.components.count) files")
            //
            //            for file in directoryContents.first!.components {
            //                if (file.filename == "." || file.filename == ".." || file.attributes.size == 0)  {
            //                    continue
            //                }
            //                //debugPrint(file.filename)
            //                let fullPath = handshakeDirectory + "/" + file.filename
            //                let buffer = try await sftp.openFile(filePath: fullPath, flags: .read)
            //                let bufferContents: ByteBuffer = try await buffer.readAll()
            //                try await buffer.close()
            //                debugPrint("Save \(file.filename) local...")
            //                saveByteBufferToDocuments(byteBuffer: bufferContents, fileName: file.filename)
            //                total += 1
            //            }
            
            debugPrint("Finished Downloading \(total) Files")
            
        } catch {
            throw error
        }
        return total
    }
    
    func loadLocalFiles(pwnFiles: [PwnFile]) async -> [Handshake] {
        debugPrint("Loading Files")
        
        var handshakes: [Handshake] = []
        debugPrint("Total File Count \(pwnFiles.count)")
        
        // Now run through the List to create handshake object when PCAP File is found and store geo, netpos and gps file inside the object
        for file in pwnFiles {
            if file.fileType == .handshake {
                var tempshake = Handshake(
                    id: UUID().uuidString, pwnFile: file
                )
                for fileToMatch in pwnFiles {
                    if tempshake.handshakeName == fileToMatch.basename {
                        switch fileToMatch.fileType {
                        case .netpos:
                            tempshake.netposFile = fileToMatch
                            debugPrint("Habe für \(tempshake.handshakeName) ein NETPOS File gefunden")
                        case .geo:
                            tempshake.geoFile = fileToMatch
                            debugPrint("Habe für \(tempshake.handshakeName) ein GEO File gefunden")
                        case .gps:
                            tempshake.gpsFile = fileToMatch
                            debugPrint("Habe für \(tempshake.handshakeName) ein GPS File gefunden")
                        default:
                            break
                        }
                    }
                }
                handshakes.append(tempshake)
            }
            
            // Sorting Handshakes
            handshakes.sort {
                $0.pcapFile.modificationDate ?? Date(timeIntervalSince1970: 0) > $1.pcapFile.modificationDate ?? Date(timeIntervalSince1970: 0)
            }
        }
        debugPrint("Total Handshake Count \(handshakes.count)")
        debugPrint("Finished Loading Files")
        return handshakes
    }
    
    
    func saveByteBufferToDocuments(byteBuffer: ByteBuffer, fileName: String, modDate: Date) {
        var buffer = byteBuffer
        if let data = buffer.readData(length: buffer.readableBytes) {
            
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                
                do {
                    try data.write(to: fileURL)
                    let attributes: [FileAttributeKey: Any] = [
                        .creationDate: modDate,
                        .modificationDate: modDate
                    ]
                    try FileManager.default.setAttributes(attributes, ofItemAtPath: fileURL.path)
                } catch {
                    debugPrint("Error writing file: \(error)")
                }
            }
        } else {
            print("Cannot read ByteBuffer")
        }
    }
    
    func getAllLocalFiles() -> [PwnFile] {
        var pwnFiles: [PwnFile] = []
        
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                // Alle Dateien im Dokumentenverzeichnis auflisten
                let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                for fileURL in fileURLs {
                    let filePath = fileURL.path
                    let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
                    let fileName = fileURL.lastPathComponent
                    let fileSize = attributes[.size] as? UInt64 ?? 0
                    let creationDate = attributes[.creationDate] as? Date
                    let modificationDate = attributes[.modificationDate] as? Date
                    let dummyDate = Date(timeIntervalSince1970: 0)
                    
                    let pwnfile = PwnFile(
                        id: UUID().uuidString,
                        filename: fileName,
                        size: fileSize,
                        creationDate: creationDate ?? dummyDate,
                        modificationDate: modificationDate ?? dummyDate)
                    pwnFiles.append(pwnfile)
                }
            } catch {
                print("Error fetching file information: \(error)")
            }
        }
        return pwnFiles
    }
}
