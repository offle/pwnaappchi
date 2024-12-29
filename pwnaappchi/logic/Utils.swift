import Foundation
import _MapKit_SwiftUI
import NIO
import MapKit

struct Utils {
    
    func byteBufferToString(byteBuffer: ByteBuffer) -> String? {
        var buffer = byteBuffer
        // Versuche, die Daten als UTF-8-kodierten String zu lesen
        if let string = buffer.readString(length: buffer.readableBytes) {
            return string
        } else {
            debugPrint("Error converting ByteBuffer to String")
            return nil
        }
    }
    
    func getValue(from configContent: String, key: String) -> String? {
        
        let pattern = "\(key)\\s*=\\s*\"([^\"]*)\""
        
        // Führe die RegEx aus
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: configContent.utf16.count)
            if let match = regex.firstMatch(in: configContent, options: [], range: range) {
                if let valueRange = Range(match.range(at: 1), in: configContent) {
                    // Rückgabe des extrahierten Werts
                    return String(configContent[valueRange])
                }
            }
        }
        return nil
    }
    
    func getJsonFromFile(filename: String) -> Data? {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            do {
                return try Data(contentsOf: fileURL)
            } catch {
                debugPrint("Error loading JSON: \(error.localizedDescription)")
            }
        } else {
            debugPrint("Error loading File")
        }
        return nil
    }
    
    func getJsonAsPrettyString(filename: String) -> String {
        guard let data = getJsonFromFile(filename: filename) else {
            return "Error loading JSON."
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            return String(data: prettyData, encoding: .utf8) ?? "Invalid JSON"
        } catch {
            return "Error parsing JSON: \(error.localizedDescription)"
        }
    }
    
    func getJsonAsDictionary(filename: String) -> [String: Any]? {
        guard let data = getJsonFromFile(filename: filename) else {
            return nil
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            debugPrint("Error parsing JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getPositionFromFile(filename: String, mapAccuracy: Int) -> MapCameraPosition? {
        let utils = Utils()
        
        if let jsonData = utils.getJsonAsDictionary(filename: filename),
           let location = jsonData["location"] as? [String: Any],
           let lat = location["lat"] as? Double,
           let lng = location["lng"] as? Double {
            let mapAccuracyDouble = Double(mapAccuracy)
            let accuracy = location["accuracy"] as? Double ?? 0
            if (mapAccuracyDouble == 0 || accuracy == 0) || accuracy <= mapAccuracyDouble {
                    return MapCameraPosition.region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                        )
                    )
            }
        }
        return nil
    }
    
    func getPositionFromAllFiles(pwnfiles: [PwnFile], mapAccuracy: Int) -> [MapCameraPosition] {
        var positions: [MapCameraPosition] = []
        for file in pwnfiles {
            if file.filename.hasSuffix("geo.json") || file.filename.hasSuffix("gps.json") {
                if let position = getPositionFromFile(filename: file.filename, mapAccuracy: mapAccuracy) {
                    positions.append(position)
                }
            }
        }
        return positions
    }
}

extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: self)
    }
}
